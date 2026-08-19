import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'package:just_audio/just_audio.dart';
import 'package:audio_service/audio_service.dart';
import 'package:audio_session/audio_session.dart';
import 'package:dio/dio.dart';
import 'package:path/path.dart' as p;
import 'package:smtc_windows/smtc_windows.dart';

import '../models/audio_track.dart';
import '../models/audio_gain_settings.dart';
import 'cache_service.dart';
import 'caching_stream_audio_source.dart';
import 'audio_haptics_service.dart';
import 'log_service.dart';
import 'playback_history_service.dart';
import 'download_path_service.dart';
import 'storage_service.dart';
import '../utils/image_blur_util.dart';
import '../utils/local_file_url.dart';

final _log = LogService.instance;

class AudioPlayerService {
  static AudioPlayerService? _instance;
  static AudioPlayerService get instance =>
      _instance ??= AudioPlayerService._();

  AudioPlayerService._() {
    if (Platform.isAndroid) {
      _androidLoudnessEnhancer = AndroidLoudnessEnhancer();
      _player = AudioPlayer(
        audioPipeline: AudioPipeline(
          androidAudioEffects: [_androidLoudnessEnhancer!],
        ),
      );
    } else {
      _player = AudioPlayer();
    }
  }

  late final AudioPlayer _player;
  AndroidLoudnessEnhancer? _androidLoudnessEnhancer;
  final AudioHapticsService _hapticsService = AudioHapticsService.instance;
  final List<AudioTrack> _queue = [];
  int _currentIndex = 0;
  AudioHandler? _audioHandler;
  LoopMode _appLoopMode = LoopMode.off; // Track loop mode at app level
  String? _tempPlaybackFilePath; // 临时音频副本路径，用于规避字幕冲突
  Directory? _tempAudioDirectory;
  bool _isSwitchingTrack = false; // Flag to indicate track switching state

  // 下一首预加载：剩余时长低于此阈值时提前缓存下一首，避免切歌空档
  // null 表示关闭预加载。默认 10 秒，可由设置更新。
  Duration? _preloadThreshold = const Duration(seconds: 10);
  String? _prefetchedNextHash; // 已为哪个 hash 触发过预取，避免重复

  static const List<String> _lyricExtensions = [
    '.lrc',
    '.srt',
    '.vtt',
    '.ass',
    '.ssa',
  ];

  // macOS specific: Track completion state to prevent duplicate triggers
  bool _completionHandled = false;
  Timer?
      _completionCheckTimer; // macOS workaround for StreamAudioSource completion bug

  // Windows SMTC support
  SMTCWindows? _smtc;

  // Privacy mode settings
  bool _privacyEnabled = false;
  bool _privacyBlurCover = true;
  bool _privacyMaskTitle = true;
  String _privacyCustomTitle = '正在播放音频';

  // Audio haptics settings
  bool _hapticsEnabled = false;
  double _hapticsIntensity = 0.85;

  // Logical user volume and the independent global gain setting.
  double _userVolume = 1;
  double _audioGainDecibels = AudioGainSettings.defaultDecibels;
  bool _audioPassthroughEnabled = false;

  // Stream controllers
  final StreamController<List<AudioTrack>> _queueController =
      StreamController.broadcast();
  final StreamController<AudioTrack?> _currentTrackController =
      StreamController.broadcast();
  final StreamController<bool> _trackLoadingController =
      StreamController<bool>.broadcast();

  // Initialize the service
  Future<void> initialize() async {
    // Initialize audio service handler for system integration
    _audioHandler = await AudioService.init(
      builder: () => _AudioPlayerHandler(this),
      config: const AudioServiceConfig(
        androidNotificationChannelId:
            'com.example.kikoeru_flutter.channel.audio',
        androidNotificationChannelName: 'Kikoeru Audio',
        androidNotificationOngoing: false,
        androidStopForegroundOnPause: false,
        androidShowNotificationBadge: true,
      ),
    );

    // Set initial playback state for all platforms
    _updatePlaybackState();
    _hapticsService.attachPlaybackState(
      positionProvider: () => _player.position,
      playingProvider: () => _player.playing,
    );

    // Initialize Windows SMTC (System Media Transport Controls)
    if (Platform.isWindows) {
      try {
        _smtc = SMTCWindows(
          config: const SMTCConfig(
            fastForwardEnabled: false,
            nextEnabled: true,
            pauseEnabled: true,
            playEnabled: true,
            rewindEnabled: false,
            prevEnabled: true,
            stopEnabled: true,
          ),
        );

        // Register SMTC button callbacks
        _smtc!.buttonPressStream.listen((button) {
          if (_instance == null) return; // Prevent callback after disposal
          switch (button) {
            case PressedButton.play:
              play();
              break;
            case PressedButton.pause:
              pause();
              break;
            case PressedButton.next:
              skipToNext();
              break;
            case PressedButton.previous:
              skipToPrevious();
              break;
            case PressedButton.stop:
              stop();
              break;
            default:
              break;
          }
        });

        // Enable SMTC
        _smtc!.enableSmtc();
      } catch (e) {
        _log.captureOutput(
            '[AudioPlayerService] Failed to initialize SMTC: $e');
      }
    }

    _setupPlayerListeners();
  }

  /// 更新音频会话配置（直通/独占模式）
  Future<void> updateAudioSessionConfig(bool enablePassthrough) async {
    _audioPassthroughEnabled = enablePassthrough;
    await _applyOutputLevel();

    if (!Platform.isAndroid && !Platform.isIOS) return;

    // iOS 平台如果用户认为不支持，则不应用直通配置，或者仅应用基础配置
    // 这里根据需求，如果是在 iOS 上，我们可能不希望开启 "movie" 模式，或者保持默认
    // 但为了代码一致性，我们还是允许配置，但可以通过平台判断来调整参数
    if (Platform.isIOS && enablePassthrough) {
      // 如果用户明确说 iOS 不支持，我们可以选择在这里直接返回，或者应用一个"无害"的配置
      // 暂时保持与 Android 一致的逻辑，但如果用户反馈有问题，可以随时禁用
      // _log.captureOutput('[AudioPlayerService] iOS passthrough requested but might not be fully supported.');
    }

    try {
      _log.captureOutput(
          '[AudioPlayerService] Updating AudioSession config. Passthrough enabled: $enablePassthrough');
      final session = await AudioSession.instance;

      if (enablePassthrough) {
        // 开启直通/独占模式配置 (Movie/Media)
        await session.configure(const AudioSessionConfiguration(
          avAudioSessionCategory: AVAudioSessionCategory.playback,
          avAudioSessionCategoryOptions:
              AVAudioSessionCategoryOptions.duckOthers,
          avAudioSessionMode: AVAudioSessionMode.moviePlayback,
          androidAudioAttributes: AndroidAudioAttributes(
            contentType: AndroidAudioContentType.movie,
            flags: AndroidAudioFlags.none,
            usage: AndroidAudioUsage.media,
          ),
          androidAudioFocusGainType: AndroidAudioFocusGainType.gain,
          androidWillPauseWhenDucked: true,
        ));
      } else {
        // 恢复默认配置 (Music/Media) - 适合普通音乐播放
        await session.configure(const AudioSessionConfiguration(
          avAudioSessionCategory: AVAudioSessionCategory.playback,
          avAudioSessionCategoryOptions:
              AVAudioSessionCategoryOptions.duckOthers,
          avAudioSessionMode: AVAudioSessionMode.defaultMode,
          androidAudioAttributes: AndroidAudioAttributes(
            contentType: AndroidAudioContentType.music,
            flags: AndroidAudioFlags.none,
            usage: AndroidAudioUsage.media,
          ),
          androidAudioFocusGainType: AndroidAudioFocusGainType.gain,
          androidWillPauseWhenDucked: true,
        ));
      }
      _log.captureOutput(
          '[AudioPlayerService] AudioSession updated successfully.');
    } catch (e) {
      _log.captureOutput(
          '[AudioPlayerService] Error updating AudioSession: $e');
    }
  }

  void _setupPlayerListeners() {
    // 预加载下一首：当前剩余时长低于阈值时，后台提前缓存队列中下一首
    _player.positionStream.listen((position) {
      _maybePreloadNextTrack(position, _player.duration);
    });

    // Listen to player state changes
    _player.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        if (Platform.isMacOS) {
          // macOS: Use dedicated handler to prevent duplicate triggers
          if (!_completionHandled) {
            _completionHandled = true;
            _handleTrackCompletion();
          }
        } else {
          // Other platforms: Use simple direct handling
          _handleTrackCompletion();
        }
      }

      // Update audio service playback state
      _updatePlaybackState();
    });

    // macOS specific: Additional position-based completion detection
    if (Platform.isMacOS) {
      Duration lastPosition = Duration.zero;
      _player.positionStream.listen((position) {
        final duration = _player.duration;

        // Reset completion flag when track changes or seeks backward
        if (position < lastPosition - const Duration(seconds: 1)) {
          _completionHandled = false;
        }

        // Fallback: detect completion when position reaches duration
        if (duration != null &&
            position >= duration - const Duration(milliseconds: 100) &&
            _player.playing &&
            !_completionHandled) {
          // Check if position is stuck at the end
          if (lastPosition != Duration.zero &&
              (position - lastPosition).inMilliseconds.abs() < 50 &&
              position >= duration - const Duration(milliseconds: 100)) {
            _completionHandled = true;
            _handleTrackCompletion();
          }
        }

        lastPosition = position;
        _updatePlaybackState();
      });

      // Start periodic completion check timer as final fallback
      _startCompletionCheckTimer();
    } else {
      // Other platforms: Simple position stream for playback state updates
      _player.positionStream.listen((position) {
        _updatePlaybackState();
      });
    }
  }

  // Update audio service playback state for system controls
  void _updatePlaybackState() {
    if (_audioHandler == null) return;

    final playing = _player.playing;
    final processingState = _player.processingState;

    // Determine the effective processing state
    // If we are switching tracks, force buffering state to keep system controls active
    final effectiveProcessingState = _isSwitchingTrack
        ? AudioProcessingState.buffering
        : {
              ProcessingState.idle: AudioProcessingState.idle,
              ProcessingState.loading: AudioProcessingState.loading,
              ProcessingState.buffering: AudioProcessingState.buffering,
              ProcessingState.ready: AudioProcessingState.ready,
              ProcessingState.completed: AudioProcessingState.completed,
            }[processingState] ??
            AudioProcessingState.idle;

    (_audioHandler as _AudioPlayerHandler).playbackState.add(PlaybackState(
          controls: [
            MediaControl.skipToPrevious,
            if (playing) MediaControl.pause else MediaControl.play,
            MediaControl.skipToNext,
          ],
          systemActions: const {
            MediaAction.seek,
            MediaAction.seekForward,
            MediaAction.seekBackward,
          },
          androidCompactActionIndices: const [0, 1, 2],
          processingState: effectiveProcessingState,
          playing: playing,
          updatePosition: _player.position,
          bufferedPosition: _player.bufferedPosition,
          speed: _player.speed,
        ));

    // Update Windows SMTC playback status
    if (Platform.isWindows && _smtc != null) {
      _smtc!.setPlaybackStatus(
        playing ? PlaybackStatus.Playing : PlaybackStatus.Paused,
      );
    }
  }

  // Queue management
  Future<void> updateQueue(List<AudioTrack> tracks,
      {int startIndex = 0}) async {
    _queue.clear();
    _queue.addAll(tracks);
    _currentIndex = startIndex.clamp(0, tracks.length - 1);

    _queueController.add(List.from(_queue));

    // Load the current track
    if (tracks.isNotEmpty && _currentIndex < tracks.length) {
      await _loadTrack(tracks[_currentIndex]);
    }
  }

  Future<void> _loadTrack(AudioTrack track) async {
    _log.captureOutput(
        '[Audio] _loadTrack: title="${track.title}", url="${track.url}"');

    // 换曲目后清空预加载标记，让新的"下一首"可重新触发预取
    _prefetchedNextHash = null;

    // Emit track immediately so MiniPlayer appears right away
    _currentTrackController.add(track);
    _trackLoadingController.add(true);

    // Set switching flag and update state to buffering immediately
    _isSwitchingTrack = true;
    _updatePlaybackState();

    // Reset completion flag for new track (macOS specific)
    if (Platform.isMacOS) {
      _completionHandled = false;
    }

    // 清理上一首歌创建的临时文件
    await _cleanupTempPlaybackFile();

    try {
      // Update media item immediately to show new track info
      await _updateMediaItem(
        track,
        privacyEnabled: _privacyEnabled,
        blurCover: _privacyBlurCover,
        maskTitle: _privacyMaskTitle,
        customTitle: _privacyCustomTitle,
      );
      await _hapticsService.stop();

      String? audioFilePath;
      bool loaded = false;

      // 优先检查是否是本地文件（file:// 协议）
      final localPath = LocalFileUrl.pathFromUrl(track.url);
      if (localPath != null) {
        final localFile = File(localPath);
        _log.captureOutput('[Audio] 检查本地文件: $localPath');

        if (await localFile.exists()) {
          final fileStat = await localFile.stat();
          _log.captureOutput(
              '[Audio] 本地文件存在: size=${fileStat.size} bytes, modified=${fileStat.modified}');
          final playbackPath =
              await _prepareLocalPlaybackPath(localPath) ?? localPath;
          await _player.setFilePath(playbackPath);
          await _prepareHapticsForDownloadedFile(
            track,
            downloadPath: localPath,
            analysisPath: playbackPath,
          );
          _log.captureOutput('[Audio] 使用本地文件播放: ${track.title}');
          loaded = true;
        } else {
          _log.captureOutput('[Audio] 本地文件不存在: $localPath');
        }
      }

      // 如果不是本地文件，且有 hash，尝试使用缓存
      if (!loaded && track.hash != null && track.hash!.isNotEmpty) {
        audioFilePath = await CacheService.getCachedAudioFile(track.hash!);

        if (audioFilePath != null) {
          await _player.setFilePath(audioFilePath);
          await _prepareHapticsForDownloadedFile(
            track,
            downloadPath: audioFilePath,
          );
          _log.captureOutput('[Audio] 使用缓存文件播放: ${track.title}');
          loaded = true;
        } else {
          try {
            await CacheService.resetAudioCachePartial(track.hash!);
            final source = CachingStreamAudioSource(
              uri: Uri.parse(track.url),
              hash: track.hash!,
            );
            await _player.setAudioSource(source);
            unawaited(_hapticsService.prepareForTrack(track));
            _log.captureOutput('[Audio] 流式播放并写入缓存: ${track.title}');
            loaded = true;
          } catch (error) {
            _log.captureOutput('[Audio] 构建缓存流失败，回退到直接流式: $error');
          }
        }
      }

      if (!loaded) {
        await _player.setUrl(track.url);
        unawaited(_hapticsService.prepareForTrack(track));
        _log.captureOutput('[Audio] 流式播放: ${track.url}');
      }
    } catch (e) {
      _log.captureOutput('Error loading audio source: $e');
    } finally {
      _isSwitchingTrack = false;
      _trackLoadingController.add(false);
      _updatePlaybackState();
    }
  }

  // Update media item for system notification
  // privacySettings: 可选的防社死设置，如果提供则应用隐私保护
  Future<void> _updateMediaItem(
    AudioTrack track, {
    bool privacyEnabled = false,
    bool blurCover = true,
    bool maskTitle = true,
    String customTitle = '正在播放音频',
  }) async {
    if (_audioHandler == null) return;

    // 应用防社死设置
    String displayTitle = track.title;
    String? displayArtworkUrl = track.artworkUrl;

    if (privacyEnabled) {
      // 替换标题
      if (maskTitle) {
        displayTitle = customTitle;
      }

      // 模糊封面
      if (blurCover && displayArtworkUrl != null) {
        try {
          // 生成模糊后的封面并保存到临时文件
          final blurredFilePath =
              await ImageBlurUtil.blurNetworkImageToFile(displayArtworkUrl);
          if (blurredFilePath != null) {
            displayArtworkUrl = blurredFilePath;
          } else {
            // 模糊失败，隐藏封面
            displayArtworkUrl = null;
          }
        } catch (e) {
          _log.captureOutput('模糊封面失败: $e');
          displayArtworkUrl = null;
        }
      }
    }

    (_audioHandler as _AudioPlayerHandler).mediaItem.add(MediaItem(
          id: track.id,
          album: track.album ?? '',
          title: displayTitle,
          artist: track.artist ?? '',
          duration: track.duration,
          artUri:
              displayArtworkUrl != null ? Uri.parse(displayArtworkUrl) : null,
        ));

    // Update Windows SMTC media info
    if (Platform.isWindows && _smtc != null) {
      _smtc!.updateMetadata(
        MusicMetadata(
          title: displayTitle,
          artist: track.artist ?? '',
          album: track.album ?? '',
          thumbnail: displayArtworkUrl,
        ),
      );
    }

    // Update playback state immediately after media item change
    _updatePlaybackState();
  }

  // Handle track completion logic
  void _handleTrackCompletion() {
    if (_appLoopMode == LoopMode.one) {
      // Single track repeat - replay current track
      // macOS: Reset completion flag before replaying to allow next completion detection
      if (Platform.isMacOS) {
        _completionHandled = false;
      }
      seek(Duration.zero);
      play();
    } else if (_currentIndex < _queue.length - 1) {
      // Has next track - play it
      skipToNext();
    } else if (_appLoopMode == LoopMode.all && _queue.isNotEmpty) {
      // List repeat - go back to first track
      skipToIndex(0);
    } else {
      // Reached the end of the queue with no repeat, pause
      pause();
    }
  }

  // 预加载下一首：当当前曲目接近播放结束（剩余 < _preloadThreshold），
  // 在后台提前把下一首流式音频拉到缓存，切歌时即可命中本地缓存，避免卡顿空档。
  // 单曲循环、本地文件、已缓存曲目均自动跳过，不影响正常播放逻辑。
  void _maybePreloadNextTrack(Duration position, Duration? duration) {
    final threshold = _preloadThreshold;
    if (threshold == null || threshold <= Duration.zero) return;
    if (_appLoopMode == LoopMode.one) return;
    if (duration == null || duration <= Duration.zero) return;

    final remaining = duration - position;
    if (remaining > threshold) return;

    if (!hasNext) return;
    final nextTrack = _queue[_currentIndex + 1];

    final hash = nextTrack.hash;
    final url = nextTrack.url;
    if (hash == null || hash.isEmpty) return;

    // 本地文件 / 已预取过 / 已缓存：无需再次预取
    if (_prefetchedNextHash == hash) return;
    _prefetchedNextHash = hash;

    final localPath = LocalFileUrl.pathFromUrl(url);
    if (localPath != null) return; // 本地文件，秒加载，无需预取

    unawaited(_preloadNextTrackToCache(nextTrack));
  }

  Future<void> _preloadNextTrackToCache(AudioTrack track) async {
    final hash = track.hash;
    if (hash == null || hash.isEmpty) return;
    final url = track.url;

    try {
      // 若已命中缓存（含已下载文件），直接跳过
      final cached = await CacheService.getCachedAudioFile(hash);
      if (cached != null) {
        _log.captureOutput('[Audio] 下一首已缓存，无需预加载: ${track.title}');
        return;
      }

      // 清理可能存在的损坏临时文件，避免追加写入脏数据
      await CacheService.resetAudioCachePartial(hash);

      // 复用 CacheService 的下载 + finalize 流程，把整首流式音频写到本地缓存
      final dio = Dio();
      dio.options.headers.addAll(StorageService.serverCookieHeaders);
      dio.options.connectTimeout = const Duration(seconds: 15);
      dio.options.receiveTimeout = const Duration(seconds: 60);

      _log.captureOutput('[Audio] 开始预加载下一首: ${track.title}');
      await CacheService.cacheAudioFile(hash: hash, url: url, dio: dio);
      _log.captureOutput('[Audio] 预加载下一首完成: ${track.title}');
    } catch (e) {
      _log.captureOutput('[Audio] 预加载下一首失败: ${track.title} - $e');
    }
  }

  // macOS specific: Start periodic timer to check for track completion
  // This is needed because StreamAudioSource on macOS doesn't properly fire completion events
  void _startCompletionCheckTimer() {
    if (!Platform.isMacOS) return;

    _completionCheckTimer?.cancel();
    _completionCheckTimer =
        Timer.periodic(const Duration(milliseconds: 500), (timer) {
      final position = _player.position;
      final duration = _player.duration;
      final processingState = _player.processingState;
      final playing = _player.playing;

      if (playing && !_completionHandled) {
        // Check if track is completed
        if (processingState == ProcessingState.completed) {
          _completionHandled = true;
          _handleTrackCompletion();
        } else if (duration != null &&
            duration > Duration.zero &&
            position >= duration - const Duration(milliseconds: 50)) {
          _completionHandled = true;
          _handleTrackCompletion();
        }
      }
    });
  }

  // Playback controls
  Future<void> play() async {
    // macOS specific: Ensure completion check timer is running
    if (Platform.isMacOS &&
        (_completionCheckTimer == null || !_completionCheckTimer!.isActive)) {
      _startCompletionCheckTimer();
    }

    await _player.play();
    _updatePlaybackState();
    if (_hapticsEnabled) {
      _hapticsService.start();
    }

    // macOS specific: Check if track completed immediately (workaround for immediate completion bug)
    if (Platform.isMacOS &&
        _player.processingState == ProcessingState.completed) {
      Future.delayed(const Duration(milliseconds: 100), () {
        if (!_completionHandled) {
          _completionHandled = true;
          _handleTrackCompletion();
        }
      });
    }
  }

  Future<void> pause() async {
    await _player.pause();
    _updatePlaybackState();
    await _hapticsService.pause();
  }

  Future<void> stop() async {
    await _player.stop();
    _updatePlaybackState();
    await _hapticsService.stop();
  }

  Future<void> seek(Duration position) async {
    // macOS specific: Reset completion flag when seeking to allow new completion detection
    if (Platform.isMacOS) {
      _completionHandled = false;
    }
    await _player.seek(position);
    _hapticsService.seek(position);
    _updatePlaybackState();
  }

  Future<void> seekForward(Duration duration) async {
    final currentPosition = _player.position;
    final totalDuration = _player.duration;
    if (totalDuration != null) {
      final newPosition = currentPosition + duration;
      await _player
          .seek(newPosition > totalDuration ? totalDuration : newPosition);
      _updatePlaybackState();
    }
  }

  Future<void> seekBackward(Duration duration) async {
    final currentPosition = _player.position;
    final newPosition = currentPosition - duration;
    await _player
        .seek(newPosition < Duration.zero ? Duration.zero : newPosition);
    _updatePlaybackState();
  }

  Future<void> skipToNext() async {
    if (_queue.isNotEmpty && _currentIndex < _queue.length - 1) {
      _currentIndex++;
      await _loadTrack(_queue[_currentIndex]);
      await play();
    } else {
      // No next track available
      throw Exception('没有下一首可播放');
    }
  }

  Future<void> skipToPrevious() async {
    if (_queue.isNotEmpty && _currentIndex > 0) {
      _currentIndex--;
      await _loadTrack(_queue[_currentIndex]);
      await play();
    } else {
      // No previous track available
      throw Exception('没有上一首可播放');
    }
  }

  Future<void> skipToIndex(int index) async {
    if (index >= 0 && index < _queue.length) {
      _currentIndex = index;
      await _loadTrack(_queue[_currentIndex]);
      await play();
    }
  }

  Future<void> removeTrackAt(int index) async {
    if (index < 0 || index >= _queue.length) return;

    final wasCurrent = index == _currentIndex;
    final currentTrackId = (_queue.isNotEmpty && _currentIndex < _queue.length)
        ? _queue[_currentIndex].id
        : null;

    _queue.removeAt(index);
    _queueController.add(List.from(_queue));

    if (_queue.isEmpty) {
      _currentIndex = 0;
      await stop();
      _currentTrackController.add(null);
      return;
    }

    if (wasCurrent) {
      if (_currentIndex >= _queue.length) {
        _currentIndex = _queue.length - 1;
      }
      await _loadTrack(_queue[_currentIndex]);
      await play();
      return;
    }

    if (currentTrackId != null) {
      final updatedIndex =
          _queue.indexWhere((track) => track.id == currentTrackId);
      if (updatedIndex != -1) {
        _currentIndex = updatedIndex;
      }
    }
  }

  Future<void> moveTrack(int oldIndex, int newIndex) async {
    if (oldIndex < 0 || oldIndex >= _queue.length) return;

    if (newIndex < 0) {
      newIndex = 0;
    } else if (newIndex > _queue.length) {
      newIndex = _queue.length;
    }

    if (newIndex > oldIndex) {
      newIndex -= 1;
    }

    if (oldIndex == newIndex) return;

    final currentTrackId = (_queue.isNotEmpty && _currentIndex < _queue.length)
        ? _queue[_currentIndex].id
        : null;

    final track = _queue.removeAt(oldIndex);
    _queue.insert(newIndex, track);

    if (currentTrackId != null) {
      final updatedIndex =
          _queue.indexWhere((element) => element.id == currentTrackId);
      if (updatedIndex != -1) {
        _currentIndex = updatedIndex;
      }
    }

    _queueController.add(List.from(_queue));
  }

  Future<Map<String, int>> appendTracks(List<AudioTrack> tracks) async {
    final indexMap = <String, int>{};
    if (tracks.isEmpty) return indexMap;

    if (_queue.isEmpty) {
      await updateQueue(tracks);
      for (var i = 0; i < _queue.length; i++) {
        indexMap[_queue[i].id] = i;
      }
      return indexMap;
    }

    final existingIndex = <String, int>{};
    for (var i = 0; i < _queue.length; i++) {
      existingIndex[_queue[i].id] = i;
    }

    bool appended = false;
    for (final track in tracks) {
      final existing = existingIndex[track.id];
      if (existing != null) {
        indexMap[track.id] = existing;
        continue;
      }

      _queue.add(track);
      final newIndex = _queue.length - 1;
      existingIndex[track.id] = newIndex;
      indexMap[track.id] = newIndex;
      appended = true;
    }

    if (appended) {
      _queueController.add(List.from(_queue));
    }

    // Ensure we still report indexes for tracks that already existed
    for (final track in tracks) {
      indexMap[track.id] ??= existingIndex[track.id] ??
          _queue.indexWhere((element) => element.id == track.id);
    }

    return indexMap;
  }

  // Getters and Streams
  Stream<PlayerState> get playerStateStream => _player.playerStateStream;
  Stream<Duration> get positionStream => _player.positionStream;
  Stream<Duration?> get durationStream => _player.durationStream;
  Stream<List<AudioTrack>> get queueStream => _queueController.stream;
  Stream<AudioTrack?> get currentTrackStream => _currentTrackController.stream;
  Stream<bool> get trackLoadingStream => _trackLoadingController.stream;

  Duration get position => _player.position;
  Duration? get duration => _player.duration;
  bool get playing => _player.playing;
  PlayerState get playerState => _player.playerState;

  AudioTrack? get currentTrack =>
      _queue.isNotEmpty && _currentIndex < _queue.length
          ? _queue[_currentIndex]
          : null;

  List<AudioTrack> get queue => List.unmodifiable(_queue);
  int get currentIndex => _currentIndex;

  bool get hasNext => _currentIndex < _queue.length - 1;
  bool get hasPrevious => _currentIndex > 0;

  // Audio settings
  Future<void> setRepeatMode(LoopMode mode) async {
    // Store the mode at app level
    _appLoopMode = mode;
    // Always keep the player's loop mode off to prevent single-track looping
    // We handle all repeat logic in the app layer via playerStateStream listener
    await _player.setLoopMode(LoopMode.off);
  }

  Future<void> setShuffleMode(bool enabled) async {
    await _player.setShuffleModeEnabled(enabled);
  }

  Future<void> setVolume(double volume) async {
    _userVolume = volume.clamp(0.0, 1.0).toDouble();
    await _applyOutputLevel();
  }

  Future<void> updateAudioGain(double decibels) async {
    _audioGainDecibels = AudioGainSettings.normalize(decibels);
    await _applyOutputLevel();
  }

  Future<void> _applyOutputLevel() async {
    final gainDecibels = _audioPassthroughEnabled
        ? AudioGainSettings.defaultDecibels
        : _audioGainDecibels;

    if (Platform.isAndroid) {
      final enhancer = _androidLoudnessEnhancer;
      if (enhancer != null) {
        await enhancer.setTargetGain(math.max(gainDecibels, 0));
        await enhancer.setEnabled(gainDecibels > 0);
      }
      final effectiveVolume = gainDecibels < 0
          ? _userVolume * AudioGainSettings.linearMultiplier(gainDecibels)
          : _userVolume;
      await _player.setVolume(effectiveVolume);
      return;
    }

    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      final effectiveVolume =
          _userVolume * AudioGainSettings.linearMultiplier(gainDecibels);
      await _player.setVolume(effectiveVolume);
      return;
    }

    // AVPlayer cannot boost above its native 1.0 ceiling, but attenuation is
    // reliable. Ignore positive values instead of pretending they work.
    final effectiveVolume = _userVolume *
        AudioGainSettings.linearMultiplier(
          math.min(gainDecibels, 0),
        );
    await _player.setVolume(effectiveVolume);
  }

  Future<void> setSpeed(double speed) async {
    await _player.setSpeed(speed.clamp(0.5, 2.0));
  }

  // Privacy mode settings
  /// 更新防社死设置
  Future<void> updatePrivacySettings({
    required bool enabled,
    required bool blurCover,
    required bool maskTitle,
    required String customTitle,
  }) async {
    _privacyEnabled = enabled;
    _privacyBlurCover = blurCover;
    _privacyMaskTitle = maskTitle;
    _privacyCustomTitle = customTitle;

    // 如果当前有正在播放的音轨，立即更新媒体信息
    if (currentTrack != null) {
      await _updateMediaItem(
        currentTrack!,
        privacyEnabled: _privacyEnabled,
        blurCover: _privacyBlurCover,
        maskTitle: _privacyMaskTitle,
        customTitle: _privacyCustomTitle,
      );
    }
  }

  Future<void> updateHapticsSettings({
    required bool enabled,
    required double intensity,
  }) async {
    _hapticsEnabled = enabled;
    _hapticsIntensity = intensity.clamp(0.2, 1.0);
    await _hapticsService.updateSettings(
      enabled: _hapticsEnabled,
      intensity: _hapticsIntensity,
    );
  }

  /// 更新下一首预加载阈值，null 表示关闭预加载。
  void updatePreloadThreshold(Duration? threshold) {
    if (threshold != null && threshold < Duration.zero) {
      threshold = Duration.zero;
    }
    _preloadThreshold = threshold;
    if (threshold == null) {
      _log.captureOutput('[Audio] 预加载下一首已关闭');
    } else {
      _log.captureOutput('[Audio] 预加载阈值已更新: ${threshold.inSeconds} 秒');
    }
  }

  // Cleanup
  Future<void> dispose() async {
    _completionCheckTimer?.cancel();
    await _hapticsService.stop();
    await _cleanupTempPlaybackFile();
    await _queueController.close();
    await _currentTrackController.close();
    await _player.dispose();
  }

  Future<void> _prepareHapticsForDownloadedFile(
    AudioTrack track, {
    required String downloadPath,
    String? analysisPath,
  }) async {
    if (!await _isInDownloadDirectory(downloadPath)) {
      _log.captureOutput(
        '[Audio] 跳过触感分析，非下载目录文件: ${track.title}',
      );
      await _hapticsService.skipForTrack(track);
      return;
    }

    final resolvedAnalysisPath = analysisPath ?? downloadPath;
    if (!p.equals(
      p.normalize(resolvedAnalysisPath),
      p.normalize(downloadPath),
    )) {
      _log.captureOutput(
        '[Audio] 使用播放副本进行触感分析: $resolvedAnalysisPath',
      );
    }

    await _hapticsService.prepareForTrack(
      track.copyWith(sourcePath: resolvedAnalysisPath),
    );
  }

  Future<bool> _isInDownloadDirectory(String filePath) async {
    try {
      final downloadDir = await DownloadPathService.getDownloadDirectory();
      final root = p.normalize(downloadDir.path);
      final path = p.normalize(filePath);

      if (p.equals(path, root)) return true;
      return p.isWithin(root, path);
    } catch (e) {
      _log.captureOutput('[Audio] 检查下载目录失败: $e');
      return false;
    }
  }

  Future<void> _cleanupTempPlaybackFile() async {
    if (_tempPlaybackFilePath == null) return;
    try {
      final tempFile = File(_tempPlaybackFilePath!);
      if (await tempFile.exists()) {
        await tempFile.delete();
        _log.captureOutput('[Audio] 已删除临时音频文件: $_tempPlaybackFilePath');
      }
    } catch (e) {
      _log.captureOutput('[Audio] 删除临时音频文件失败: $e');
    } finally {
      _tempPlaybackFilePath = null;
    }
  }

  Future<String?> _prepareLocalPlaybackPath(String originalPath) async {
    final lowerPath = originalPath.toLowerCase();
    final shouldInspect = lowerPath.endsWith('.wav') ||
        lowerPath.endsWith('.flac') ||
        lowerPath.endsWith('.m4a') ||
        lowerPath.endsWith('.aac') ||
        lowerPath.endsWith('.ogg') ||
        lowerPath.endsWith('.opus') ||
        lowerPath.endsWith('.mp3');

    if (!shouldInspect) {
      return null;
    }

    final file = File(originalPath);
    final directory = file.parent;
    final baseName = p.basenameWithoutExtension(originalPath);
    final ext = p.extension(originalPath);

    // 检查文件名是否包含非 ASCII 字符（可能导致 MPV 崩溃）
    final hasNonAscii = baseName.codeUnits.any((c) => c > 127);

    // 检查是否有同名字幕文件
    bool hasLyricFile = false;
    for (final lyricExt in _lyricExtensions) {
      final lyricPath = p.join(directory.path, '$baseName$lyricExt');
      final lyricFile = File(lyricPath);
      if (await lyricFile.exists()) {
        hasLyricFile = true;
        _log.captureOutput('[Audio] 检测到同名字幕文件: $lyricPath');
        break;
      }
    }

    // 如果有非 ASCII 字符或同名字幕文件，复制到临时目录使用纯 ASCII 文件名
    if (hasNonAscii || hasLyricFile) {
      final reason = hasNonAscii ? '文件名含非ASCII字符' : '存在同名字幕文件';
      _log.captureOutput('[Audio] $reason，需要使用临时文件');

      final tempDir = await _getTempAudioDirectory();
      // 使用纯 ASCII 文件名：时间戳 + 简单哈希
      final hash = originalPath.hashCode.abs().toRadixString(16);
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final newName = 'audio_${timestamp}_$hash$ext';
      final tempPath = p.join(tempDir.path, newName);

      try {
        await file.copy(tempPath);
        _tempPlaybackFilePath = tempPath;
        _log.captureOutput('[Audio] 已复制音频到临时路径: $tempPath');
        return tempPath;
      } catch (e) {
        _log.captureOutput('[Audio] 复制文件失败: $e');
        return null;
      }
    }

    return null;
  }

  Future<Directory> _getTempAudioDirectory() async {
    if (_tempAudioDirectory != null) return _tempAudioDirectory!;
    final dir =
        Directory(p.join(Directory.systemTemp.path, 'kikoflu_audio_temp'));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    _tempAudioDirectory = dir;
    return dir;
  }
}

// Custom AudioHandler for system integration
class _AudioPlayerHandler extends BaseAudioHandler with SeekHandler {
  final AudioPlayerService _service;

  _AudioPlayerHandler(this._service);

  @override
  Future<void> play() => _service.play();

  @override
  Future<void> pause() async {
    await _service.pause();
    // 系统通知栏/锁屏暂停时也要立即落盘历史
    PlaybackHistoryService.instance.onPaused();
  }

  @override
  Future<void> stop() async {
    await _service.stop();
    // 系统通知栏停止时立即落盘历史
    PlaybackHistoryService.instance.onStopped();
  }

  @override
  Future<void> seek(Duration position) async {
    await _service.seek(position);
    // 系统通知栏/锁屏 seek 时立即落盘历史
    PlaybackHistoryService.instance.onSeekCommitted(position);
  }

  @override
  Future<void> skipToNext() => _service.skipToNext();

  @override
  Future<void> skipToPrevious() => _service.skipToPrevious();
}
