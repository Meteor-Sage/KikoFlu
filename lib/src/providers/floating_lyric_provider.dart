import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/floating_lyric_service.dart';
import 'lyric_provider.dart';
import 'audio_provider.dart';

/// 悬浮歌词开关状态
final floatingLyricEnabledProvider =
    StateNotifierProvider<FloatingLyricEnabledNotifier, bool>((ref) {
  return FloatingLyricEnabledNotifier();
});

/// 悬浮歌词自动更新器
/// 监听当前歌词变化，自动更新悬浮窗内容
final floatingLyricAutoUpdaterProvider = Provider<void>((ref) {
  final isEnabled = ref.watch(floatingLyricEnabledProvider);
  final currentLyric = ref.watch(currentLyricTextProvider);
  final isPlaying = ref.watch(isPlayingProvider);

  if (!isEnabled) return;

  // 根据播放状态和歌词内容更新悬浮窗
  String displayText;

  if (!isPlaying) {
    displayText = '♪ 暂停中 ♪';
  } else if (currentLyric != null && currentLyric.trim().isNotEmpty) {
    displayText = currentLyric;
  } else {
    displayText = '♪ 暂无歌词 ♪';
  }

  // 异步更新悬浮窗文本
  FloatingLyricService.instance.updateText(displayText);
});

class FloatingLyricEnabledNotifier extends StateNotifier<bool> {
  static const _key = 'floating_lyric_enabled';

  FloatingLyricEnabledNotifier() : super(false) {
    _load();
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
  }

  /// 更新悬浮歌词文本
  Future<void> updateText(String text) async {
    if (state) {
      await FloatingLyricService.instance.updateText(text);
    }
  }
}
