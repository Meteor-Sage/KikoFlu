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

  FloatingLyricEnabledNotifier(this.ref) : super(false) {
    _load();
  }

  @override
  void dispose() {
    _stopBackgroundUpdate();
    super.dispose();
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
    await FloatingLyricService.instance.show('♪ 暂无播放 ♪');
    // 应用当前样式
    ref.read(floatingLyricStyleProvider.notifier).applyStyle();
    // 启动后台更新
    _startBackgroundUpdate();
  }

  /// 启动后台更新监听
  void _startBackgroundUpdate() {
    _stopBackgroundUpdate();

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
  }

  /// 停止后台更新监听
  void _stopBackgroundUpdate() {
    _positionSubscription?.cancel();
    _positionSubscription = null;
    _playingSubscription?.cancel();
    _playingSubscription = null;
  }

  /// 在后台更新歌词（不依赖 Provider watch）
  void _updateLyricInBackground() {
    final isPlaying = AudioPlayerService.instance.playing;
    final lyricState = ref.read(lyricControllerProvider);
    final currentPosition = AudioPlayerService.instance.position;

    String displayText;
    if (!isPlaying) {
      displayText = '♪ 暂停中 ♪';
    } else if (lyricState.lyrics.isNotEmpty) {
      // 使用调整后的歌词
      final adjustedLyrics = lyricState.adjustedLyrics;
      final currentLyric =
          LyricParser.getCurrentLyric(adjustedLyrics, currentPosition);

      if (currentLyric != null && currentLyric.trim().isNotEmpty) {
        displayText = currentLyric;
      } else {
        displayText = '♪ 暂无歌词 ♪';
      }
    } else {
      displayText = '♪ 暂无歌词 ♪';
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
