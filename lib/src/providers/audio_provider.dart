import 'dart:async';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:permission_handler/permission_handler.dart';

import '../models/audio_track.dart';
import '../models/audio_gain_settings.dart';
import '../models/audio_tap_playlist_mode.dart';
import '../models/work.dart';
import '../services/audio_player_service.dart';
import '../services/log_service.dart';
import '../services/playback_history_service.dart';
import 'settings_provider.dart';
import 'history_provider.dart';
import 'auth_provider.dart' show kikoeruApiServiceProvider;

final _log = LogService.instance;

// Audio Player Service Provider
final audioPlayerServiceProvider = Provider<AudioPlayerService>((ref) {
  final service = AudioPlayerService.instance;
  return service;
});

// Current Track Provider
final currentTrackProvider = StreamProvider<AudioTrack?>((ref) {
  final service = ref.watch(audioPlayerServiceProvider);
  return _withInitialValue(service.currentTrack, service.currentTrackStream);
});

// Player State Provider
final playerStateProvider = StreamProvider<PlayerState>((ref) {
  final service = ref.watch(audioPlayerServiceProvider);
  return _withInitialValue(service.playerState, service.playerStateStream);
});

// Position Provider
final positionProvider = StreamProvider<Duration>((ref) {
  final service = ref.watch(audioPlayerServiceProvider);
  return _withInitialValue(service.position, service.positionStream);
});

// Duration Provider
final durationProvider = StreamProvider<Duration?>((ref) {
  final service = ref.watch(audioPlayerServiceProvider);
  return _withInitialValue(service.duration, service.durationStream);
});

// Queue Provider
final queueProvider = StreamProvider<List<AudioTrack>>((ref) {
  final service = ref.watch(audioPlayerServiceProvider);
  return _withInitialValue(service.queue, service.queueStream);
});

Stream<T> _withInitialValue<T>(T initialValue, Stream<T> updates) async* {
  yield initialValue;
  yield* updates;
}

// Playing State Provider (convenience)
final isPlayingProvider = Provider<bool>((ref) {
  final playerState = ref.watch(playerStateProvider);
  return playerState.when(
    data: (state) => state.playing,
    loading: () => false,
    error: (_, __) => false,
  );
});

// Track Loading Provider (true while audio source is being loaded)
final isTrackLoadingProvider = StreamProvider<bool>((ref) {
  final service = ref.watch(audioPlayerServiceProvider);
  return service.trackLoadingStream;
});

// Progress Provider (convenience)
final progressProvider = Provider<double>((ref) {
  final position = ref.watch(positionProvider);
  final duration = ref.watch(durationProvider);

  return position.when(
    data: (pos) => duration.when(
      data: (dur) => dur != null && dur.inMilliseconds > 0
          ? pos.inMilliseconds / dur.inMilliseconds
          : 0.0,
      loading: () => 0.0,
      error: (_, __) => 0.0,
    ),
    loading: () => 0.0,
    error: (_, __) => 0.0,
  );
});

/// 是否可以播放下一首（列表未结束或开启了循环模式）
final canSkipNextProvider = Provider<bool>((ref) {
  final service = ref.watch(audioPlayerServiceProvider);
  final audioState = ref.watch(audioPlayerControllerProvider);
  // 监听队列和当前曲目变化
  ref.watch(queueProvider);
  ref.watch(currentTrackProvider);

  // 如果开启了列表循环或单曲循环，始终可以跳转
  if (audioState.repeatMode == LoopMode.all ||
      audioState.repeatMode == LoopMode.one) {
    return true;
  }

  // 否则检查是否还有下一首
  return service.hasNext;
});

// Audio Player Controller
class AudioPlayerController extends StateNotifier<AudioPlayerState> {
  final AudioPlayerService _service;
  final Ref _ref;
  Future<void> _pendingDismissal = Future.value();

  AudioPlayerController(this._service, this._ref)
      : super(const AudioPlayerState()) {
    // 监听防社死设置变化
    _ref.listen<PrivacyModeSettings>(
      privacyModeSettingsProvider,
      (previous, next) {
        // 设置变化时更新音频服务
        _service.updatePrivacySettings(
          enabled: next.enabled,
          blurCover: next.blurCover,
          maskTitle: next.maskTitle,
          customTitle: next.customTitle,
        );
      },
    );

    // 监听音频直通设置变化
    _ref.listen<bool>(
      audioPassthroughProvider,
      (previous, next) {
        if (previous != next) {
          _service.updateAudioSessionConfig(next);
        }
      },
    );

    _ref.listen<AudioHapticsSettings>(
      audioHapticsSettingsProvider,
      (previous, next) {
        if (previous != next) {
          _service.updateHapticsSettings(
            enabled: next.enabled,
            intensity: next.intensity,
          );
        }
      },
    );

    _ref.listen<AudioGainSettings>(
      audioGainSettingsProvider,
      (previous, next) {
        if (previous?.decibels != next.decibels) {
          _service.updateAudioGain(next.decibels);
        }
      },
    );

    // 监听下一首预加载设置变化
    _ref.listen<PreloadNextSettings>(
      preloadNextSettingsProvider,
      (previous, next) {
        if (previous?.mode != next.mode ||
            previous?.customSeconds != next.customSeconds) {
          final seconds = next.effectiveSeconds;
          _service.updatePreloadThreshold(
            seconds == null ? null : Duration(seconds: seconds),
          );
        }
      },
    );
  }

  Future<void> initialize() async {
    // Notification permission is an Android-only requirement here. The
    // permission_handler Apple implementation is iOS-only, so requesting it
    // on macOS aborts audio initialization before session restoration.
    if (Platform.isAndroid) {
      await Permission.notification.request();
    }

    await _service.initialize();

    // 初始化时应用当前的防社死设置
    final privacySettings = _ref.read(privacyModeSettingsProvider);
    await _service.updatePrivacySettings(
      enabled: privacySettings.enabled,
      blurCover: privacySettings.blurCover,
      maskTitle: privacySettings.maskTitle,
      customTitle: privacySettings.customTitle,
    );

    final hapticsSettings = _ref.read(audioHapticsSettingsProvider);
    await _service.updateHapticsSettings(
      enabled: hapticsSettings.enabled,
      intensity: hapticsSettings.intensity,
    );

    await _service.updateAudioSessionConfig(
      _ref.read(audioPassthroughProvider),
    );
    await _service.updateAudioGain(
      _ref.read(audioGainSettingsProvider).decibels,
    );

    // 初始化时应用当前的下一首预加载阈值
    final preloadSettings = _ref.read(preloadNextSettingsProvider);
    final preloadSeconds = preloadSettings.effectiveSeconds;
    _service.updatePreloadThreshold(
      preloadSeconds == null ? null : Duration(seconds: preloadSeconds),
    );

    // Restore only after privacy and output settings are active. Restored
    // sessions stay paused until the user explicitly resumes playback.
    await _service.restorePlaybackSession();

    // Listen to player state changes
    _service.playerStateStream.listen((playerState) {
      // Force a state update to trigger UI rebuild
      state = state.copyWith();
    });
  }

  Future<void> playTrack(AudioTrack track) async {
    await _pendingDismissal;
    final playlistMode = await _ref
        .read(audioTapPlaylistModeProvider.notifier)
        .getMode();
    final shouldAppend =
        playlistMode != AudioTapPlaylistMode.replaceQueue && queue.isNotEmpty;

    if (shouldAppend) {
      final indexMap = await _service.appendTracks([track]);
      final targetIndex = indexMap[track.id];
      if (targetIndex != null) {
        await _service.skipToIndex(targetIndex);
      }
    } else {
      await _service.updateQueue([track]);
      await _service.play();
    }
    _ref.read(miniPlayerVisibilityProvider.notifier).show();

    // Ensure single-track plays are recorded to history.
    if (track.workId != null) {
      try {
        final api = _ref.read(kikoeruApiServiceProvider);
        final json = await api.getWork(track.workId!);
        final work = Work.fromJson(json);
        // Fire-and-forget: record history (don't block the UI)
        _ref.read(historyProvider.notifier).addOrUpdate(work,
            track: track, positionMs: _service.position.inMilliseconds);
      } catch (e) {
        _log.captureOutput(
            'Failed to record history for playTrack (id=${track.workId}): $e');
      }
    }
  }

  Future<void> playTracks(List<AudioTrack> tracks,
      {int startIndex = 0,
      Work? work,
      AudioTapPlaylistMode? playlistMode}) async {
    await _pendingDismissal;
    if (tracks.isEmpty) return;

    final AudioTapPlaylistMode effectiveMode = playlistMode ??
        await _ref.read(audioTapPlaylistModeProvider.notifier).getMode();
    final selectedIndex = startIndex.clamp(0, tracks.length - 1);
    final selectedTrack = tracks[selectedIndex];
    final queueTracks = effectiveMode == AudioTapPlaylistMode.appendSingle
        ? <AudioTrack>[selectedTrack]
        : tracks;
    final queueStartIndex =
        effectiveMode == AudioTapPlaylistMode.appendSingle ? 0 : selectedIndex;

    _log.captureOutput(
        '[AudioController] playTracks调用: ${queueTracks.length}个轨道, '
        'startIndex=$queueStartIndex, mode=${effectiveMode.name}');
    _log.captureOutput(
        '[AudioController] 第一个轨道: title="${queueTracks.first.title}", '
        'url="${queueTracks.first.url}"');

    final shouldAppend = effectiveMode != AudioTapPlaylistMode.replaceQueue &&
        queue.isNotEmpty;

    if (shouldAppend) {
      final indexMap = await _service.appendTracks(queueTracks);
      final targetTrack = queueTracks[queueStartIndex];
      final targetIndex = indexMap[targetTrack.id];
      if (targetIndex != null) {
        await _service.skipToIndex(targetIndex);
      }
    } else {
      await _service.updateQueue(queueTracks, startIndex: queueStartIndex);
      _log.captureOutput('[AudioController] updateQueue完成');
      await _service.play();
      _log.captureOutput('[AudioController] play完成');
    }
    _ref.read(miniPlayerVisibilityProvider.notifier).show();

    if (work != null) {
      _ref.read(historyProvider.notifier).addOrUpdate(work);
    }
  }

  Future<void> play() async {
    await _pendingDismissal;
    await _service.play();
    _ref.read(miniPlayerVisibilityProvider.notifier).show();
  }

  Future<void> pause() async {
    await _service.pause();
    // 暂停时立即落盘历史
    PlaybackHistoryService.instance.onPaused();
  }

  Future<void> stop() async {
    await _service.stop();
    // 停止时立即落盘历史
    PlaybackHistoryService.instance.onStopped();
  }

  Future<void> dismissMiniPlayer() {
    _ref.read(miniPlayerVisibilityProvider.notifier).hide();
    final historyFlush = PlaybackHistoryService.instance.onStopped();
    final clearing = _service.clearQueue();
    final dismissal = Future.wait([historyFlush, clearing]).then<void>((_) {});
    _pendingDismissal = dismissal.catchError((Object error) {
      _log.captureOutput('[AudioController] Mini Player dismissal failed: $error');
    });
    return dismissal;
  }

  Future<void> seek(Duration position) async {
    await _service.seek(position);
  }

  /// seek 并立即持久化历史（用于用户显式拖动进度条）
  Future<void> seekAndPersist(Duration position) async {
    await _service.seek(position);
    await PlaybackHistoryService.instance.onSeekCommitted(position);
  }

  Future<void> seekForward(Duration duration) async {
    await _service.seekForward(duration);
  }

  Future<void> seekBackward(Duration duration) async {
    await _service.seekBackward(duration);
  }

  Future<void> skipToNext() async {
    await _service.skipToNext();
  }

  Future<void> skipToPrevious() async {
    await _service.skipToPrevious();
  }

  Future<void> skipToIndex(int index) async {
    await _service.skipToIndex(index);
  }

  Future<void> removeTrackAt(int index) async {
    await _service.removeTrackAt(index);
  }

  Future<void> moveTrack(int oldIndex, int newIndex) async {
    await _service.moveTrack(oldIndex, newIndex);
  }

  Future<void> setRepeatMode(LoopMode mode) async {
    await _service.setRepeatMode(mode);
    state = state.copyWith(repeatMode: mode);
  }

  Future<void> setShuffleMode(bool enabled) async {
    await _service.setShuffleMode(enabled);
    state = state.copyWith(shuffleMode: enabled);
  }

  Future<void> setVolume(double volume) async {
    await _service.setVolume(volume);
    state = state.copyWith(volume: volume);
  }

  Future<void> setSpeed(double speed) async {
    await _service.setSpeed(speed);
    state = state.copyWith(speed: speed);
  }

  // Getters to expose service state
  bool get isPlaying => _service.playing;
  PlayerState get playerState => _service.playerState;
  AudioTrack? get currentTrack => _service.currentTrack;
  List<AudioTrack> get queue => _service.queue;
  Stream<PlayerState> get playerStateStream => _service.playerStateStream;
  Stream<AudioTrack?> get currentTrackStream => _service.currentTrackStream;
}

// Audio Player State
class AudioPlayerState {
  final LoopMode repeatMode;
  final bool shuffleMode;
  final double volume;
  final double speed;

  const AudioPlayerState({
    this.repeatMode = LoopMode.off,
    this.shuffleMode = false,
    this.volume = 1.0,
    this.speed = 1.0,
  });

  AudioPlayerState copyWith({
    LoopMode? repeatMode,
    bool? shuffleMode,
    double? volume,
    double? speed,
  }) {
    return AudioPlayerState(
      repeatMode: repeatMode ?? this.repeatMode,
      shuffleMode: shuffleMode ?? this.shuffleMode,
      volume: volume ?? this.volume,
      speed: speed ?? this.speed,
    );
  }
}

// Audio Player Controller Provider
final audioPlayerControllerProvider =
    StateNotifierProvider<AudioPlayerController, AudioPlayerState>((ref) {
  final service = ref.watch(audioPlayerServiceProvider);
  return AudioPlayerController(service, ref);
});

// MiniPlayer Visibility Controller
class MiniPlayerVisibilityController extends StateNotifier<bool> {
  MiniPlayerVisibilityController() : super(true);

  void show() => state = true;
  void hide() => state = false;
}

// MiniPlayer Visibility Provider
final miniPlayerVisibilityProvider =
    StateNotifierProvider<MiniPlayerVisibilityController, bool>((ref) {
  return MiniPlayerVisibilityController();
});

// Sleep Timer Controller
class SleepTimerController extends StateNotifier<SleepTimerState> {
  final Ref _ref;
  Timer? _timer;
  Timer? _countdownTimer;
  StreamSubscription? _trackSubscription;

  SleepTimerController(this._ref) : super(const SleepTimerState());

  /// 设置定时器（按时长）
  void setTimer(Duration duration, {bool finishCurrentTrack = false}) {
    final endTime = DateTime.now().add(duration);
    _setTimerInternal(endTime, finishCurrentTrack: finishCurrentTrack);
  }

  /// 设置定时器（按指定时间）
  void setTimerUntil(DateTime targetTime, {bool finishCurrentTrack = false}) {
    _setTimerInternal(targetTime, finishCurrentTrack: finishCurrentTrack);
  }

  /// 内部方法：设置定时器到指定时间
  void _setTimerInternal(DateTime endTime, {bool finishCurrentTrack = false}) {
    // 取消现有定时器
    cancelTimer();

    final duration = endTime.difference(DateTime.now());

    // 如果时间已经过了，则不设置
    if (duration.isNegative || duration.inSeconds < 1) {
      return;
    }

    // 设置主定时器 - 到时间后暂停播放
    _timer = Timer(duration, () {
      if (state.finishCurrentTrack) {
        _waitForTrackEndAndPause();
      } else {
        final audioController =
            _ref.read(audioPlayerControllerProvider.notifier);
        audioController.pause();
        // 定时器结束后重置状态
        cancelTimer();
      }
    });

    // 设置倒计时更新定时器 - 每秒更新一次剩余时间
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final remaining = endTime.difference(DateTime.now());
      if (remaining.isNegative) {
        timer.cancel();
        return;
      }
      state = SleepTimerState(
        isActive: true,
        endTime: endTime,
        remainingTime: remaining,
        finishCurrentTrack: finishCurrentTrack,
      );
    });

    state = SleepTimerState(
      isActive: true,
      endTime: endTime,
      remainingTime: duration,
      finishCurrentTrack: finishCurrentTrack,
    );
  }

  /// 等待当前音轨播放结束并暂停
  void _waitForTrackEndAndPause() {
    _timer?.cancel();
    _timer = null;
    _countdownTimer?.cancel();
    _countdownTimer = null;

    final audioController = _ref.read(audioPlayerControllerProvider.notifier);
    final initialTrack = audioController.currentTrack;

    if (initialTrack == null) {
      cancelTimer();
      return;
    }

    state = state.copyWith(
      waitingForTrackEnd: true,
      remainingTime: Duration.zero,
    );

    _trackSubscription?.cancel();
    _trackSubscription = audioController.currentTrackStream.listen(
      (track) {
        // 当音轨发生变化（切换到下一首或停止）时暂停
        if (track?.id != initialTrack.id) {
          audioController.pause();
          cancelTimer();
        }
      },
    );
  }

  /// 取消定时器
  void cancelTimer() {
    _timer?.cancel();
    _timer = null;
    _countdownTimer?.cancel();
    _countdownTimer = null;
    _trackSubscription?.cancel();
    _trackSubscription = null;
    state = const SleepTimerState();
  }

  /// 添加时间（延长定时器）
  void addTime(Duration duration) {
    if (state.isActive && state.endTime != null) {
      final newEndTime = state.endTime!.add(duration);
      final newRemaining = newEndTime.difference(DateTime.now());

      // 重新设置定时器，并保持当前的"播完暂停"状态
      setTimer(
        newRemaining,
        finishCurrentTrack: state.finishCurrentTrack,
      );
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _countdownTimer?.cancel();
    _trackSubscription?.cancel();
    super.dispose();
  }
}

// Sleep Timer State
class SleepTimerState {
  final bool isActive;
  final DateTime? endTime;
  final Duration? remainingTime;
  final bool finishCurrentTrack;
  final bool waitingForTrackEnd;

  const SleepTimerState({
    this.isActive = false,
    this.endTime,
    this.remainingTime,
    this.finishCurrentTrack = false,
    this.waitingForTrackEnd = false,
  });

  SleepTimerState copyWith({
    bool? isActive,
    DateTime? endTime,
    Duration? remainingTime,
    bool? finishCurrentTrack,
    bool? waitingForTrackEnd,
  }) {
    return SleepTimerState(
      isActive: isActive ?? this.isActive,
      endTime: endTime ?? this.endTime,
      remainingTime: remainingTime ?? this.remainingTime,
      finishCurrentTrack: finishCurrentTrack ?? this.finishCurrentTrack,
      waitingForTrackEnd: waitingForTrackEnd ?? this.waitingForTrackEnd,
    );
  }

  String get formattedTime {
    if (remainingTime == null) return '';

    final hours = remainingTime!.inHours;
    final minutes = remainingTime!.inMinutes.remainder(60);
    final seconds = remainingTime!.inSeconds.remainder(60);

    if (hours > 0) {
      return '$hours:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    } else {
      return '$minutes:${seconds.toString().padLeft(2, '0')}';
    }
  }
}

// Sleep Timer Provider
final sleepTimerProvider =
    StateNotifierProvider<SleepTimerController, SleepTimerState>((ref) {
  return SleepTimerController(ref);
});
