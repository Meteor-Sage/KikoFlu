import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/work.dart';
import '../models/history_record.dart';
import '../models/audio_track.dart';
import '../services/history_database.dart';
import '../services/audio_player_service.dart' as import_service;
import '../services/log_service.dart';
import '../services/playback_history_service.dart';
import '../utils/paged_collection.dart';

class HistoryState {
  final List<HistoryRecord> records;
  final bool isLoading;
  final int currentPage;
  final int totalCount;
  final int pageSize;
  final bool hasMore;
  final bool isRefreshing;
  final bool isLoadingMore;
  final String? error;
  final String? loadMoreError;

  const HistoryState({
    this.records = const [],
    this.isLoading = false,
    this.currentPage = 1,
    this.totalCount = 0,
    this.pageSize = 20,
    this.hasMore = true,
    this.isRefreshing = false,
    this.isLoadingMore = false,
    this.error,
    this.loadMoreError,
  });

  HistoryState copyWith({
    List<HistoryRecord>? records,
    bool? isLoading,
    int? currentPage,
    int? totalCount,
    int? pageSize,
    bool? hasMore,
    bool? isRefreshing,
    bool? isLoadingMore,
    String? error,
    String? loadMoreError,
  }) {
    return HistoryState(
      records: records ?? this.records,
      isLoading: isLoading ?? this.isLoading,
      currentPage: currentPage ?? this.currentPage,
      totalCount: totalCount ?? this.totalCount,
      pageSize: pageSize ?? this.pageSize,
      hasMore: hasMore ?? this.hasMore,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      error: error,
      loadMoreError: loadMoreError,
    );
  }
}

final historyProvider =
    StateNotifierProvider<HistoryNotifier, HistoryState>((ref) {
  return HistoryNotifier(ref);
});

class HistoryNotifier extends StateNotifier<HistoryState> {
  // ignore: unused_field - kept for potential future use with Ref
  final Ref _ref;

  HistoryNotifier(this._ref) : super(const HistoryState()) {
    load(refresh: true);
    _initHistoryUpdateListener();
  }

  StreamSubscription? _historyUpdateSubscription;
  DateTime _lastRefreshTime = DateTime.now();
  final PagedRequestGate _requestGate = PagedRequestGate();

  Future<void> load({
    bool refresh = false,
    bool force = false,
    bool append = false,
  }) async {
    final token = _requestGate.begin(supersede: force || refresh);
    if (token == null) return;

    final existingCount = state.records.length;
    final offset = append ? existingCount : 0;
    final limit = refresh && existingCount > state.pageSize
        ? existingCount
        : state.pageSize;

    state = state.copyWith(
      isLoading: state.records.isEmpty,
      isRefreshing: refresh && state.records.isNotEmpty,
      isLoadingMore: append,
      error: null,
      loadMoreError: null,
    );

    try {
      final records = await HistoryDatabase.instance.getAllHistory(
        limit: limit,
        offset: offset,
      );
      final totalCount = await HistoryDatabase.instance.getHistoryCount();
      if (!_requestGate.isCurrent(token)) return;

      final merged = mergePagedItems(
        existing: state.records,
        incoming: records,
        idOf: (record) => record.work.id,
        replace: !append,
      );

      state = state.copyWith(
        records: merged,
        currentPage:
            merged.isEmpty ? 1 : ((merged.length - 1) ~/ state.pageSize) + 1,
        totalCount: totalCount,
        hasMore: merged.length < totalCount,
        isLoading: false,
        isRefreshing: false,
        isLoadingMore: false,
        error: null,
        loadMoreError: null,
      );
    } catch (e) {
      if (!_requestGate.isCurrent(token)) return;
      final message = e.toString();
      state = state.copyWith(
        isLoading: false,
        isRefreshing: false,
        isLoadingMore: false,
        error: append ? null : message,
        loadMoreError: append ? message : null,
      );
      logOutput('Failed to load history: $e');
    } finally {
      _requestGate.complete(token);
    }
  }

  Future<void> refresh() async {
    await load(refresh: true, force: true);
  }

  Future<void> loadMore() async {
    if (!state.hasMore || state.isRefreshing) return;
    await load(append: true);
  }

  Future<void> nextPage() => loadMore();

  /// 外部直接写入历史（例如 history_work_card 恢复播放时）
  Future<void> addOrUpdate(Work work,
      {AudioTrack? track, int? positionMs}) async {
    final now = DateTime.now();
    final audioService = PlaybackHistoryService.instance;

    int playlistIndex = 0;
    int playlistTotal = 0;

    // 尝试从播放历史服务获取播放列表信息
    if (audioService.currentWorkId == work.id) {
      playlistIndex = audioService.currentTrack != null
          ? AudioPlayerServiceHelper.currentIndex
          : 0;
      playlistTotal = AudioPlayerServiceHelper.queueLength;
    }

    final existingIndex = state.records.indexWhere((r) => r.work.id == work.id);
    HistoryRecord record;

    if (existingIndex >= 0) {
      final existing = state.records[existingIndex];
      record = existing.copyWith(
        work: work,
        lastPlayedTime: now,
        lastTrack: track ?? existing.lastTrack,
        lastPositionMs: positionMs ?? existing.lastPositionMs,
        playlistIndex:
            playlistIndex > 0 ? playlistIndex : existing.playlistIndex,
        playlistTotal:
            playlistTotal > 0 ? playlistTotal : existing.playlistTotal,
      );
    } else {
      record = HistoryRecord(
        work: work,
        lastPlayedTime: now,
        lastTrack: track,
        lastPositionMs: positionMs ?? 0,
        playlistIndex: playlistIndex,
        playlistTotal: playlistTotal,
      );
    }

    await HistoryDatabase.instance.addOrUpdate(record);
    await refresh();
  }

  Future<void> remove(int workId) async {
    await HistoryDatabase.instance.delete(workId);
    await refresh();
  }

  Future<void> clear() async {
    await HistoryDatabase.instance.clear();
    _requestGate.invalidate();
    state = state.copyWith(
      records: [],
      totalCount: 0,
      currentPage: 1,
      hasMore: false,
      isLoading: false,
      isRefreshing: false,
      isLoadingMore: false,
      error: null,
      loadMoreError: null,
    );
  }

  /// 监听 PlaybackHistoryService 的写入通知，节流刷新列表
  void _initHistoryUpdateListener() {
    _historyUpdateSubscription =
        PlaybackHistoryService.instance.historyUpdatedStream.listen((_) {
      final now = DateTime.now();
      // 节流：10 秒内最多刷新一次列表
      if (now.difference(_lastRefreshTime).inSeconds >= 10) {
        _lastRefreshTime = now;
        refresh();
      }
    });
  }

  @override
  void dispose() {
    _historyUpdateSubscription?.cancel();
    super.dispose();
  }
}

/// 帮助类，用于从 AudioPlayerService 获取播放列表信息
/// 避免直接在 provider 层级依赖 AudioPlayerService 的内部状态
class AudioPlayerServiceHelper {
  static int get currentIndex {
    try {
      return _audioPlayerService.currentIndex;
    } catch (_) {
      return 0;
    }
  }

  static int get queueLength {
    try {
      return _audioPlayerService.queue.length;
    } catch (_) {
      return 0;
    }
  }

  static import_service.AudioPlayerService get _audioPlayerService =>
      import_service.AudioPlayerService.instance;
}
