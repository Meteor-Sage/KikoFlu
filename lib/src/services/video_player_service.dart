import 'dart:async';
import 'package:video_player/video_player.dart';

import '../models/video_track.dart';

class VideoPlayerService {
  static VideoPlayerService? _instance;
  static VideoPlayerService get instance =>
      _instance ??= VideoPlayerService._();

  VideoPlayerService._();

  VideoPlayerController? _controller;
  final List<VideoTrack> _queue = [];
  int _currentIndex = 0;

  // Stream controllers
  final StreamController<List<VideoTrack>> _queueController =
      StreamController.broadcast();
  final StreamController<VideoTrack?> _currentVideoController =
      StreamController.broadcast();
  final StreamController<VideoPlayerValue> _playerValueController =
      StreamController.broadcast();

  // Initialize the service
  Future<void> initialize() async {
    // Setup is done when playing a video
  }

  // Queue management
  Future<void> updateQueue(List<VideoTrack> videos,
      {int startIndex = 0}) async {
    _queue.clear();
    _queue.addAll(videos);
    _currentIndex = startIndex.clamp(0, videos.length - 1);

    _queueController.add(List.from(_queue));

    // Load the current video
    if (videos.isNotEmpty && _currentIndex < videos.length) {
      await _loadVideo(videos[_currentIndex]);
    }
  }

  Future<void> _loadVideo(VideoTrack video) async {
    try {
      // Dispose previous controller
      await _controller?.dispose();

      // Create new controller
      _controller = VideoPlayerController.networkUrl(
        Uri.parse(video.url),
      );

      // Add listener for player value changes
      _controller!.addListener(() {
        _playerValueController.add(_controller!.value);
      });

      // Initialize the controller
      await _controller!.initialize();
      _currentVideoController.add(video);
    } catch (e) {
      print('Error loading video source: $e');
    }
  }

  // Playback controls
  Future<void> play() async {
    if (_controller != null && _controller!.value.isInitialized) {
      await _controller!.play();
    }
  }

  Future<void> pause() async {
    if (_controller != null && _controller!.value.isInitialized) {
      await _controller!.pause();
    }
  }

  Future<void> stop() async {
    if (_controller != null) {
      await _controller!.pause();
      await _controller!.seekTo(Duration.zero);
    }
  }

  Future<void> seek(Duration position) async {
    if (_controller != null && _controller!.value.isInitialized) {
      await _controller!.seekTo(position);
    }
  }

  Future<void> skipToNext() async {
    if (_currentIndex < _queue.length - 1) {
      _currentIndex++;
      await _loadVideo(_queue[_currentIndex]);
      await play();
    }
  }

  Future<void> skipToPrevious() async {
    if (_currentIndex > 0) {
      _currentIndex--;
      await _loadVideo(_queue[_currentIndex]);
      await play();
    }
  }

  Future<void> skipToIndex(int index) async {
    if (index >= 0 && index < _queue.length) {
      _currentIndex = index;
      await _loadVideo(_queue[_currentIndex]);
      await play();
    }
  }

  // Getters and Streams
  Stream<VideoPlayerValue> get playerValueStream =>
      _playerValueController.stream;
  Stream<List<VideoTrack>> get queueStream => _queueController.stream;
  Stream<VideoTrack?> get currentVideoStream => _currentVideoController.stream;

  VideoPlayerController? get controller => _controller;
  VideoPlayerValue? get value => _controller?.value;
  Duration get position => _controller?.value.position ?? Duration.zero;
  Duration get duration => _controller?.value.duration ?? Duration.zero;
  bool get isPlaying => _controller?.value.isPlaying ?? false;
  bool get isInitialized => _controller?.value.isInitialized ?? false;

  VideoTrack? get currentVideo =>
      _queue.isNotEmpty && _currentIndex < _queue.length
          ? _queue[_currentIndex]
          : null;

  List<VideoTrack> get queue => List.unmodifiable(_queue);
  int get currentIndex => _currentIndex;

  bool get hasNext => _currentIndex < _queue.length - 1;
  bool get hasPrevious => _currentIndex > 0;

  // Video settings
  Future<void> setVolume(double volume) async {
    if (_controller != null && _controller!.value.isInitialized) {
      await _controller!.setVolume(volume.clamp(0.0, 1.0));
    }
  }

  Future<void> setPlaybackSpeed(double speed) async {
    if (_controller != null && _controller!.value.isInitialized) {
      await _controller!.setPlaybackSpeed(speed.clamp(0.25, 2.0));
    }
  }

  Future<void> setLooping(bool looping) async {
    if (_controller != null && _controller!.value.isInitialized) {
      await _controller!.setLooping(looping);
    }
  }

  // Cleanup
  Future<void> dispose() async {
    await _queueController.close();
    await _currentVideoController.close();
    await _playerValueController.close();
    await _controller?.dispose();
  }
}
