import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';

import '../models/video_track.dart';
import '../services/video_player_service.dart';

// Video Player Service Provider
final videoPlayerServiceProvider = Provider<VideoPlayerService>((ref) {
  final service = VideoPlayerService.instance;
  return service;
});

// Current Video Provider
final currentVideoProvider = StreamProvider<VideoTrack?>((ref) {
  final service = ref.watch(videoPlayerServiceProvider);
  return service.currentVideoStream;
});

// Player Value Provider
final videoPlayerValueProvider = StreamProvider<VideoPlayerValue>((ref) {
  final service = ref.watch(videoPlayerServiceProvider);
  return service.playerValueStream;
});

// Video Queue Provider
final videoQueueProvider = StreamProvider<List<VideoTrack>>((ref) {
  final service = ref.watch(videoPlayerServiceProvider);
  return service.queueStream;
});

// Playing State Provider (convenience)
final isVideoPlayingProvider = Provider<bool>((ref) {
  final playerValue = ref.watch(videoPlayerValueProvider);
  return playerValue.when(
    data: (value) => value.isPlaying,
    loading: () => false,
    error: (_, __) => false,
  );
});

// Progress Provider (convenience)
final videoProgressProvider = Provider<double>((ref) {
  final playerValue = ref.watch(videoPlayerValueProvider);

  return playerValue.when(
    data: (value) {
      if (value.duration.inMilliseconds > 0) {
        return value.position.inMilliseconds / value.duration.inMilliseconds;
      }
      return 0.0;
    },
    loading: () => 0.0,
    error: (_, __) => 0.0,
  );
});

// Video Player Controller
class VideoPlayerController extends StateNotifier<VideoPlayerState> {
  final VideoPlayerService _service;

  VideoPlayerController(this._service) : super(const VideoPlayerState());

  Future<void> initialize() async {
    await _service.initialize();
  }

  Future<void> playVideo(VideoTrack video) async {
    await _service.updateQueue([video]);
    await _service.play();
  }

  Future<void> playVideos(List<VideoTrack> videos, {int startIndex = 0}) async {
    await _service.updateQueue(videos, startIndex: startIndex);
    await _service.play();
  }

  Future<void> play() async {
    await _service.play();
  }

  Future<void> pause() async {
    await _service.pause();
  }

  Future<void> stop() async {
    await _service.stop();
  }

  Future<void> seek(Duration position) async {
    await _service.seek(position);
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

  Future<void> setVolume(double volume) async {
    await _service.setVolume(volume);
    state = state.copyWith(volume: volume);
  }

  Future<void> setPlaybackSpeed(double speed) async {
    await _service.setPlaybackSpeed(speed);
    state = state.copyWith(playbackSpeed: speed);
  }

  Future<void> setLooping(bool looping) async {
    await _service.setLooping(looping);
    state = state.copyWith(isLooping: looping);
  }

  void toggleFullscreen() {
    state = state.copyWith(isFullscreen: !state.isFullscreen);
  }

  void setControlsVisible(bool visible) {
    state = state.copyWith(controlsVisible: visible);
  }
}

// Video Player State
class VideoPlayerState {
  final double volume;
  final double playbackSpeed;
  final bool isLooping;
  final bool isFullscreen;
  final bool controlsVisible;

  const VideoPlayerState({
    this.volume = 1.0,
    this.playbackSpeed = 1.0,
    this.isLooping = false,
    this.isFullscreen = false,
    this.controlsVisible = true,
  });

  VideoPlayerState copyWith({
    double? volume,
    double? playbackSpeed,
    bool? isLooping,
    bool? isFullscreen,
    bool? controlsVisible,
  }) {
    return VideoPlayerState(
      volume: volume ?? this.volume,
      playbackSpeed: playbackSpeed ?? this.playbackSpeed,
      isLooping: isLooping ?? this.isLooping,
      isFullscreen: isFullscreen ?? this.isFullscreen,
      controlsVisible: controlsVisible ?? this.controlsVisible,
    );
  }
}

// Video Player Controller Provider
final videoPlayerControllerProvider =
    StateNotifierProvider<VideoPlayerController, VideoPlayerState>((ref) {
  final service = ref.watch(videoPlayerServiceProvider);
  return VideoPlayerController(service);
});
