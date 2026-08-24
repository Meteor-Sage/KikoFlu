import 'dart:async';
import '../models/audio_track.dart';
import '../models/history_record.dart';
import '../models/work.dart';
import 'audio_player_service.dart';
import 'log_service.dart';
import 'playback_history_store.dart';

/// 历史写入触发原因
enum FlushReason {
  checkpoint, // 周期性 5 秒 checkpoint
  seekCommitted, // 用户 seek 提交
  paused, // 暂停
  stopped, // 停止
  trackChanged, // 切歌
  appBackground, // 应用进入后台
  dispose, // 服务销毁
}

class _TrackChangeSnapshot {
  const _TrackChangeSnapshot({
    required this.track,
    required this.playlistIndex,
    required this.playlistTotal,
    required this.positionMs,
  });

  final AudioTrack track;
  final int playlistIndex;
  final int playlistTotal;
  final int positionMs;
}

/// 播放历史服务 - 负责播放历史的写入、节流和即时落盘
///
/// 职责:
/// 1. 管理当前播放会话 snapshot
/// 2. 接收播放器事件 (position tick, seek, pause, stop, track change)
/// 3. 周期性 checkpoint (5s) + 关键事件立即 flush
/// 4. 通过 PlaybackHistoryStore 写入历史
/// 5. 对外发出轻量 "历史已更新" 通知
class PlaybackHistoryService {
  static PlaybackHistoryService? _instance;
  static PlaybackHistoryService get instance =>
      _instance ??= PlaybackHistoryService._();

  PlaybackHistoryService._({
    PlaybackHistoryStore store = const DatabasePlaybackHistoryStore(),
  }) : _store = store;

  final PlaybackHistoryStore _store;

  // --- 当前播放会话 snapshot ---
  int? _currentWorkId;
  AudioTrack? _currentTrack;
  int _playlistIndex = 0;
  int _playlistTotal = 0;
  int _lastKnownPositionMs = 0;
  int _lastPersistedPositionMs = 0;
  Work? _currentWork;
  bool _dirty = false;

  // Serialize state mutations and writes so a slow Work lookup or database
  // write for track A cannot overwrite a newer track B event.
  Future<void> _operationQueue = Future.value();
  int _attachmentGeneration = 0;

  // --- Subscriptions ---
  StreamSubscription? _positionSubscription;
  StreamSubscription? _trackSubscription;
  Timer? _checkpointTimer;

  // --- 历史更新通知 ---
  final StreamController<int?> _historyUpdatedController =
      StreamController<int?>.broadcast();

  /// 当历史记录被更新时发出通知，携带 workId
  Stream<int?> get historyUpdatedStream => _historyUpdatedController.stream;

  // --- Work 解析回调 ---
  /// 用于从 API 获取 Work 对象的回调（由外部注入，避免服务层直接依赖 API）
  Future<Work> Function(int workId)? onFetchWork;

  /// 绑定播放器服务，启动监听
  void attachPlayer(AudioPlayerService playerService) {
    detach(); // 先清理旧监听
    final generation = ++_attachmentGeneration;

    // 监听轨道变化
    _trackSubscription = playerService.currentTrackStream.listen((track) {
      if (track != null && track.workId != null) {
        final snapshot = _TrackChangeSnapshot(
          track: track,
          playlistIndex: playerService.currentIndex,
          playlistTotal: playerService.queue.length,
          positionMs: playerService.position.inMilliseconds,
        );
        unawaited(_enqueueOperation(() async {
          if (generation != _attachmentGeneration) return;
          await _onTrackChanged(snapshot, generation);
        }));
      }
    });

    // 启动 5 秒 checkpoint 定时器
    _checkpointTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _onCheckpointTick(playerService);
    });
  }

  /// 周期性 checkpoint: 只在 playing 且 position 真正推进时触发
  void _onCheckpointTick(AudioPlayerService playerService) {
    if (!playerService.playing) return;
    final positionMs = playerService.position.inMilliseconds;
    unawaited(_enqueueOperation(() async {
      if (_currentWorkId == null || _currentWork == null) return;

      // 与上次持久化位置差值不足 3 秒则不写
      if ((positionMs - _lastPersistedPositionMs).abs() < 3000) return;

      _lastKnownPositionMs = positionMs;
      _dirty = true;
      await _persistNow(FlushReason.checkpoint);
    }));
  }

  /// 当轨道切换时，先 flush 上一首的进度，再更新会话
  Future<void> _onTrackChanged(
      _TrackChangeSnapshot snapshot, int generation) async {
    // flush 上一首的状态
    if (_dirty && _currentWork != null) {
      await _persistNow(FlushReason.trackChanged);
    }
    if (generation != _attachmentGeneration) return;

    // 更新会话 snapshot
    final track = snapshot.track;
    _currentTrack = track;
    _currentWorkId = track.workId;
    _playlistIndex = snapshot.playlistIndex;
    _playlistTotal = snapshot.playlistTotal;
    _lastKnownPositionMs = snapshot.positionMs;
    _lastPersistedPositionMs = 0;
    _dirty = true;

    // 获取 Work 数据
    await _ensureWork(track.workId!);
    if (generation != _attachmentGeneration) return;

    // 新轨道立即写一次
    if (_currentWork != null) {
      await _persistNow(FlushReason.trackChanged);
    }
  }

  /// 确保有 Work 对象（先从历史存储查，再从 API 拉）
  Future<void> _ensureWork(int workId) async {
    // 如果当前已有且 id 匹配，直接用
    if (_currentWork != null && _currentWork!.id == workId) return;
    _currentWork = null;

    // 从历史存储获取
    final dbRecord = await _store.getByWorkId(workId);
    if (dbRecord != null) {
      _currentWork = dbRecord.work;
      return;
    }

    // 用回调从 API 获取
    if (onFetchWork != null) {
      try {
        _currentWork = await onFetchWork!(workId);
      } catch (e) {
        logOutput('[PlaybackHistoryService] Failed to fetch work $workId: $e');
        _currentWork = null;
      }
    }
  }

  // ==========================================================================
  // 公共 API：由外部在关键事件时调用
  // ==========================================================================

  /// seek 提交后调用，立即落盘
  Future<void> onSeekCommitted(Duration position) =>
      _enqueueOperation(() async {
        _lastKnownPositionMs = position.inMilliseconds;
        _dirty = true;
        await _persistNow(FlushReason.seekCommitted);
      });

  /// 暂停时调用
  Future<void> onPaused() {
    final positionMs = AudioPlayerService.instance.position.inMilliseconds;
    return _enqueueOperation(() async {
      _lastKnownPositionMs = positionMs;
      _dirty = true;
      await _persistNow(FlushReason.paused);
    });
  }

  /// 停止时调用
  Future<void> onStopped() {
    final positionMs = AudioPlayerService.instance.position.inMilliseconds;
    return _enqueueOperation(() async {
      _lastKnownPositionMs = positionMs;
      _dirty = true;
      await _persistNow(FlushReason.stopped);
    });
  }

  /// 应用进入后台时调用
  Future<void> flushNow(
      {FlushReason reason = FlushReason.appBackground}) {
    return _enqueueOperation(() async {
      if (_currentWorkId == null || _currentWork == null) return;

      _lastKnownPositionMs =
          AudioPlayerService.instance.position.inMilliseconds;
      _dirty = true;
      await _persistNow(reason);
    });
  }

  // ==========================================================================
  // 核心持久化
  // ==========================================================================

  Future<void> _persistNow(FlushReason reason) async {
    if (!_dirty || _currentWork == null) return;

    final now = DateTime.now();

    final record = HistoryRecord(
      work: _currentWork!,
      lastPlayedTime: now,
      lastTrack: _currentTrack,
      lastPositionMs: _lastKnownPositionMs,
      playlistIndex: _playlistIndex,
      playlistTotal: _playlistTotal,
    );

    try {
      await _store.addOrUpdate(record);
      _lastPersistedPositionMs = _lastKnownPositionMs;
      _dirty = false;

      // 通知外部历史已更新
      _historyUpdatedController.add(_currentWorkId);
    } catch (e) {
      logOutput('[PlaybackHistoryService] Failed to persist ($reason): $e');
    }
  }

  Future<void> _enqueueOperation(Future<void> Function() operation) {
    final result = _operationQueue.then((_) => operation());
    _operationQueue = result.then<void>(
      (_) {},
      onError: (Object error, StackTrace stackTrace) {
        logOutput('[PlaybackHistoryService] Queued operation failed: $error');
      },
    );
    return result;
  }

  /// 清理资源
  void detach() {
    _attachmentGeneration++;
    _positionSubscription?.cancel();
    _positionSubscription = null;
    _trackSubscription?.cancel();
    _trackSubscription = null;
    _checkpointTimer?.cancel();
    _checkpointTimer = null;
  }

  /// 销毁服务（含最终 flush）
  Future<void> dispose() async {
    detach();
    await _operationQueue;
    if (_dirty && _currentWork != null) {
      await _persistNow(FlushReason.dispose);
    }
    await _historyUpdatedController.close();
    _instance = null;
  }

  // ==========================================================================
  // 测试支持
  // ==========================================================================

  /// 仅用于测试：重置单例
  static void resetForTest({PlaybackHistoryStore? store}) {
    _instance?.detach();
    _instance = store == null ? null : PlaybackHistoryService._(store: store);
  }

  /// 仅用于测试：获取当前 session 状态
  int? get currentWorkId => _currentWorkId;
  int get lastKnownPositionMs => _lastKnownPositionMs;
  int get lastPersistedPositionMs => _lastPersistedPositionMs;
  bool get dirty => _dirty;
  Work? get currentWork => _currentWork;
  AudioTrack? get currentTrack => _currentTrack;

  /// 仅用于测试：直接设置会话状态
  void setSessionForTest({
    required int workId,
    required Work work,
    AudioTrack? track,
    int positionMs = 0,
  }) {
    _currentWorkId = workId;
    _currentWork = work;
    _currentTrack = track;
    _lastKnownPositionMs = positionMs;
    _lastPersistedPositionMs = 0;
    _dirty = false;
  }
}
