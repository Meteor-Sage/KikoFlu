import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'dart:io';
import '../services/floating_lyric_service.dart';
import '../services/audio_player_service.dart';
import '../services/log_service.dart';
import '../models/lyric.dart';
import 'lyric_provider.dart';
import 'floating_lyric_style_provider.dart';

final _log = LogService.instance;

/// 悬浮字幕开关状态
/// 使用后台 Stream 监听机制自动更新，无需依赖 UI Provider
final floatingLyricEnabledProvider =
    StateNotifierProvider<FloatingLyricEnabledNotifier, bool>((ref) {
  return FloatingLyricEnabledNotifier(ref);
});

/// 悬浮字幕触摸开关（仅 Android，默认允许触摸）
final floatingLyricTouchEnabledProvider =
    StateNotifierProvider<FloatingLyricTouchEnabledNotifier, bool>((ref) {
  return FloatingLyricTouchEnabledNotifier(ref);
});

/// 悬浮窗 FPS 显示开关（仅 iOS）
final floatingLyricFPSEnabledProvider =
    StateNotifierProvider<FloatingLyricFPSEnabledNotifier, bool>((ref) {
  return FloatingLyricFPSEnabledNotifier(ref);
});

/// 悬浮窗网速显示开关（仅 iOS）
final floatingLyricNetworkSpeedEnabledProvider =
    StateNotifierProvider<FloatingLyricNetworkSpeedEnabledNotifier, bool>(
        (ref) {
  return FloatingLyricNetworkSpeedEnabledNotifier(ref);
});

class FloatingLyricTouchEnabledNotifier extends StateNotifier<bool> {
  static const _key = 'floating_lyric_touch_enabled';
  final Ref ref;
  StreamSubscription<bool>? _touchEnabledSubscription;

  FloatingLyricTouchEnabledNotifier(this.ref) : super(true) {
    _load();
    _listenToNativeChanges();
  }

  @override
  void dispose() {
    _touchEnabledSubscription?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getBool(_key) ?? true;
  }

  void _listenToNativeChanges() {
    if (!Platform.isAndroid) return;

    _touchEnabledSubscription = FloatingLyricService
        .instance.onTouchEnabledChanged
        .listen((enabled) async {
      if (state == enabled) return;

      state = enabled;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_key, enabled);
    });
  }

  Future<void> setEnabled(bool enabled, {bool applyToWindow = true}) async {
    state = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, enabled);

    if (applyToWindow) {
      await FloatingLyricService.instance.setTouchEnabled(enabled);
    }
  }

  Future<void> toggle() async {
    await setEnabled(!state);
  }
}

class FloatingLyricFPSEnabledNotifier extends StateNotifier<bool> {
  static const _key = 'floating_lyric_fps_enabled';
  final Ref ref;

  FloatingLyricFPSEnabledNotifier(this.ref) : super(false) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getBool(_key) ?? false;
    if (state) {
      await FloatingLyricService.instance.setFPSEnabled(true);
    }
  }

  Future<void> toggle() async {
    final newValue = !state;
    state = newValue;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, newValue);
    await FloatingLyricService.instance.setFPSEnabled(newValue);
  }
}

class FloatingLyricNetworkSpeedEnabledNotifier extends StateNotifier<bool> {
  static const _key = 'floating_lyric_network_speed_enabled';
  final Ref ref;

  FloatingLyricNetworkSpeedEnabledNotifier(this.ref) : super(false) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getBool(_key) ?? false;
    if (state) {
      await FloatingLyricService.instance.setNetworkSpeedEnabled(true);
    }
  }

  Future<void> toggle() async {
    final newValue = !state;
    state = newValue;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, newValue);
    await FloatingLyricService.instance.setNetworkSpeedEnabled(newValue);
  }
}

class FloatingLyricEnabledNotifier extends StateNotifier<bool> {
  static const _key = 'floating_lyric_enabled';
  final Ref ref;
  Timer? _positionTimer;
  StreamSubscription? _playingSubscription;
  StreamSubscription? _trackSubscription;
  StreamSubscription? _closeSubscription;
  ProviderSubscription? _lyricStateSubscription;
  String? _lastTrackId;

  FloatingLyricEnabledNotifier(this.ref) : super(false) {
    _load();
    _listenToCloseEvent();
  }

  @override
  void dispose() {
    _stopBackgroundUpdate();
    _closeSubscription?.cancel();
    super.dispose();
  }

  void _listenToCloseEvent() {
    _closeSubscription =
        FloatingLyricService.instance.onClose.listen((_) async {
      if (state) {
        state = false;
        _stopBackgroundUpdate();
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(_key, false);
      }
    });
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getBool(_key) ?? false;

    // 如果已启用，尝试显示悬浮窗
    if (state) {
      final shown = await _showFloatingLyric();
      if (!shown) {
        state = false;
        await prefs.setBool(_key, false);
      }
    }
  }

  Future<void> toggle() async {
    final newValue = !state;

    // 如果要启用悬浮窗，先检查权限
    if (newValue) {
      final hasPermission = await FloatingLyricService.instance.hasPermission();
      if (!hasPermission) {
        final granted = await FloatingLyricService.instance.requestPermission();
        if (!granted) {
          _log.captureOutput('[FloatingLyric] 用户未授予悬浮窗权限');
          return;
        }
      }

      // 显示悬浮窗
      final shown = await _showFloatingLyric();
      if (!shown) return;
    } else {
      // 停止后台更新
      _stopBackgroundUpdate();
      // 隐藏悬浮窗
      await FloatingLyricService.instance.hide();
    }

    // 保存状态
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, newValue);
    state = newValue;
  }

  Future<bool> _showFloatingLyric() async {
    // 使用 Provider 中的样式，确保与当前设置一致
    final style = ref.read(floatingLyricStyleProvider);

    final styleMap = {
      'fontSize': style.fontSize,
      'textColor': style.textColorArgb,
      'backgroundColor': style.backgroundColorArgb,
      'cornerRadius': style.cornerRadius,
      'paddingHorizontal': style.paddingHorizontal,
      'paddingVertical': style.paddingVertical,
    };

    final shown = await FloatingLyricService.instance.show(
      '♪ - ♪',
      style: styleMap,
    );
    if (!shown) {
      _log.captureOutput('[FloatingLyric] 悬浮窗启动失败');
      return false;
    }

    // Windows 平台需要给予窗口一点初始化时间，避免立即发送消息导致 CHANNEL_UNREGISTERED
    if (Platform.isWindows || Platform.isLinux) {
      await Future.delayed(const Duration(milliseconds: 500));
    }

    // 再次应用样式。
    // 这样做有两个目的：
    // 1. 如果上面的 show 使用的是默认样式（因为 Provider 还没加载完），此时 Provider 应该加载完了，再次应用可以修正样式。
    // 2. 如果 Provider 在 show 执行期间加载完成并尝试 updateStyle 但失败了（因为窗口还没创建好），这里可以补救。
    ref.read(floatingLyricStyleProvider.notifier).applyStyle();

    // 应用触摸设置（Android）
    if (Platform.isAndroid) {
      final touchEnabled = ref.read(floatingLyricTouchEnabledProvider);
      await FloatingLyricService.instance.setTouchEnabled(touchEnabled);
    }

    // 启动后台更新
    _startBackgroundUpdate();
    return true;
  }

  /// 启动后台更新监听
  void _startBackgroundUpdate() {
    _stopBackgroundUpdate();
    _log.captureOutput('[FloatingLyric] 启动后台更新监听');

    // 确保字幕自动加载器始终激活（即使在后台）
    ref.read(lyricAutoLoaderProvider);

    // 独立的低延迟计时器只在悬浮字幕启用期间运行。
    _positionTimer = Timer.periodic(const Duration(milliseconds: 50), (_) {
      if (AudioPlayerService.instance.playing) {
        _updateLyricInBackground();
      }
    });

    // 监听播放状态变化
    _playingSubscription =
        AudioPlayerService.instance.playerStateStream.listen((_) {
      _updateLyricInBackground();
    });

    // 监听音轨变化
    _trackSubscription =
        AudioPlayerService.instance.currentTrackStream.listen((track) {
      _log.captureOutput(
          '[FloatingLyric] 收到音轨事件: id=${track?.id}, title=${track?.title}, lastId=$_lastTrackId');
      if (track?.id != _lastTrackId) {
        _lastTrackId = track?.id;
        _log.captureOutput('[FloatingLyric] ✓ 音轨切换确认: ${track?.title}');
        // 音轨切换时先显示"加载中"
        FloatingLyricService.instance.updateText('♪ 加载字幕中 ♪');

        // 触发字幕加载
        if (track != null) {
          final fileListState = ref.read(fileListControllerProvider);
          if (fileListState.matches(track)) {
            _log.captureOutput('[FloatingLyric] 主动触发字幕加载');
            ref.read(lyricControllerProvider.notifier).loadLyricForTrack(
                  track,
                  fileListState.files,
                );
          } else {
            _log.captureOutput(
              '[FloatingLyric] 当前字幕文件树不匹配，等待自动恢复',
            );
          }
        }
      } else {
        _log.captureOutput('[FloatingLyric] ✗ 相同音轨，忽略');
      }
    });

    // 监听字幕状态变化 - 当字幕加载完成或变化时更新
    _lyricStateSubscription = ref.listen<LyricState>(
      lyricControllerProvider,
      (previous, next) {
        // 当字幕加载完成（isLoading 从 true 变为 false）时更新
        if (previous?.isLoading == true && next.isLoading == false) {
          _log.captureOutput('[FloatingLyric] 字幕加载完成，更新悬浮窗');
          _updateLyricInBackground();
        }
        // 或者字幕内容发生变化时也更新
        else if (previous?.lyrics != next.lyrics && !next.isLoading) {
          _log.captureOutput('[FloatingLyric] 字幕内容变化，更新悬浮窗');
          _updateLyricInBackground();
        }
      },
    );
  }

  /// 停止后台更新监听
  void _stopBackgroundUpdate() {
    _positionTimer?.cancel();
    _positionTimer = null;
    _playingSubscription?.cancel();
    _playingSubscription = null;
    _trackSubscription?.cancel();
    _trackSubscription = null;
    _lyricStateSubscription?.close();
    _lyricStateSubscription = null;
  }

  /// 在后台更新字幕（不依赖 Provider watch）
  void _updateLyricInBackground() {
    final isPlaying = AudioPlayerService.instance.playing;
    final lyricState = ref.read(lyricControllerProvider);
    final currentPosition = AudioPlayerService.instance.position;

    String displayText;
    if (!isPlaying) {
      displayText = '♪ - ♪';
    } else if (lyricState.lyrics.isNotEmpty) {
      // 使用显示用歌词（翻译后 > 原文）
      final displayLyrics = lyricState.displayLyrics;
      final currentLyric =
          LyricParser.getCurrentLyric(displayLyrics, currentPosition);

      if (currentLyric != null && currentLyric.trim().isNotEmpty) {
        displayText = currentLyric;
      } else {
        displayText = '♪ - ♪';
      }
    } else {
      displayText = '♪ - ♪';
    }

    FloatingLyricService.instance.updateText(displayText);
  }

  /// 更新悬浮字幕文本
  Future<void> updateText(String text) async {
    if (state) {
      await FloatingLyricService.instance.updateText(text);
    }
  }
}
