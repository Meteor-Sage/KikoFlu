import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import '../services/floating_lyric_service.dart';
import '../services/audio_player_service.dart';
import '../models/lyric.dart';
import 'lyric_provider.dart';
import 'floating_lyric_style_provider.dart';

/// 悬浮歌词开关状态
/// 使用后台 Stream 监听机制自动更新，无需依赖 UI Provider
final floatingLyricEnabledProvider =
    StateNotifierProvider<FloatingLyricEnabledNotifier, bool>((ref) {
  return FloatingLyricEnabledNotifier(ref);
});

class FloatingLyricEnabledNotifier extends StateNotifier<bool> {
  static const _key = 'floating_lyric_enabled';
  final Ref ref;
  StreamSubscription? _positionSubscription;
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
      _showFloatingLyric();
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
          print('[FloatingLyric] 用户未授予悬浮窗权限');
          return;
        }
      }

      // 显示悬浮窗
      await _showFloatingLyric();
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

  Future<void> _showFloatingLyric() async {
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

    await FloatingLyricService.instance.show('♪ - ♪', style: styleMap);

    // 移除显式的 applyStyle 调用，因为 show 方法已经传递了样式参数
    // 且立即调用可能会因为窗口未完全初始化导致通信失败

    // 给予窗口一点初始化时间，避免立即发送消息导致 CHANNEL_UNREGISTERED
    await Future.delayed(const Duration(milliseconds: 500));

    // 再次应用样式。
    // 这样做有两个目的：
    // 1. 如果上面的 show 使用的是默认样式（因为 Provider 还没加载完），此时 Provider 应该加载完了，再次应用可以修正样式。
    // 2. 如果 Provider 在 show 执行期间加载完成并尝试 updateStyle 但失败了（因为窗口还没创建好），这里可以补救。
    ref.read(floatingLyricStyleProvider.notifier).applyStyle();

    // 启动后台更新
    _startBackgroundUpdate();
  }

  /// 启动后台更新监听
  void _startBackgroundUpdate() {
    _stopBackgroundUpdate();
    print('[FloatingLyric] 启动后台更新监听');

    // 确保歌词自动加载器始终激活（即使在后台）
    ref.read(lyricAutoLoaderProvider);

    // 监听播放位置变化，每次变化都更新歌词
    _positionSubscription =
        AudioPlayerService.instance.positionStream.listen((_) {
      _updateLyricInBackground();
    });

    // 监听播放状态变化
    _playingSubscription =
        AudioPlayerService.instance.playerStateStream.listen((_) {
      _updateLyricInBackground();
    });

    // 监听音轨变化
    _trackSubscription =
        AudioPlayerService.instance.currentTrackStream.listen((track) {
      print(
          '[FloatingLyric] 收到音轨事件: id=${track?.id}, title=${track?.title}, lastId=$_lastTrackId');
      if (track?.id != _lastTrackId) {
        _lastTrackId = track?.id;
        print('[FloatingLyric] ✓ 音轨切换确认: ${track?.title}');
        // 音轨切换时先显示"加载中"
        FloatingLyricService.instance.updateText('♪ 加载歌词中 ♪');

        // 触发歌词加载
        if (track != null) {
          final fileListState = ref.read(fileListControllerProvider);
          if (fileListState.files.isNotEmpty) {
            print('[FloatingLyric] 主动触发歌词加载');
            ref.read(lyricControllerProvider.notifier).loadLyricForTrack(
                  track,
                  fileListState.files,
                );
          } else {
            print('[FloatingLyric] 文件列表为空，无法加载歌词');
          }
        }
      } else {
        print('[FloatingLyric] ✗ 相同音轨，忽略');
      }
    });

    // 监听歌词状态变化 - 当歌词加载完成或变化时更新
    _lyricStateSubscription = ref.listen<LyricState>(
      lyricControllerProvider,
      (previous, next) {
        // 当歌词加载完成（isLoading 从 true 变为 false）时更新
        if (previous?.isLoading == true && next.isLoading == false) {
          print('[FloatingLyric] 歌词加载完成，更新悬浮窗');
          _updateLyricInBackground();
        }
        // 或者歌词内容发生变化时也更新
        else if (previous?.lyrics != next.lyrics && !next.isLoading) {
          print('[FloatingLyric] 歌词内容变化，更新悬浮窗');
          _updateLyricInBackground();
        }
      },
    );
  }

  /// 停止后台更新监听
  void _stopBackgroundUpdate() {
    _positionSubscription?.cancel();
    _positionSubscription = null;
    _playingSubscription?.cancel();
    _playingSubscription = null;
    _trackSubscription?.cancel();
    _trackSubscription = null;
    _lyricStateSubscription?.close();
    _lyricStateSubscription = null;
  }

  /// 在后台更新歌词（不依赖 Provider watch）
  void _updateLyricInBackground() {
    final isPlaying = AudioPlayerService.instance.playing;
    final lyricState = ref.read(lyricControllerProvider);
    final currentPosition = AudioPlayerService.instance.position;

    String displayText;
    if (!isPlaying) {
      displayText = '♪ - ♪';
    } else if (lyricState.lyrics.isNotEmpty) {
      // 使用调整后的歌词
      final adjustedLyrics = lyricState.adjustedLyrics;
      final currentLyric =
          LyricParser.getCurrentLyric(adjustedLyrics, currentPosition);

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

  /// 更新悬浮歌词文本
  Future<void> updateText(String text) async {
    if (state) {
      await FloatingLyricService.instance.updateText(text);
    }
  }
}
