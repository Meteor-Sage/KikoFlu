import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// 主题模式枚举
enum AppThemeMode {
  system, // 跟随系统
  light, // 浅色模式
  dark, // 深色模式
}

// 颜色方案类型枚举
enum ColorSchemeType {
  oceanBlue, // 海洋蓝（默认）
  forestGreen, // 森林绿
  sunsetOrange, // 日落橙
  lavenderPurple, // 薰衣草紫
  sakuraPink, // 樱花粉
  dynamic, // 系统动态取色
}

// 主题设置状态
class ThemeSettings {
  final AppThemeMode themeMode;
  final ColorSchemeType colorSchemeType;

  const ThemeSettings({
    this.themeMode = AppThemeMode.system,
    this.colorSchemeType = ColorSchemeType.oceanBlue,
  });

  ThemeSettings copyWith({
    AppThemeMode? themeMode,
    ColorSchemeType? colorSchemeType,
  }) {
    return ThemeSettings(
      themeMode: themeMode ?? this.themeMode,
      colorSchemeType: colorSchemeType ?? this.colorSchemeType,
    );
  }

  ThemeMode toThemeMode() {
    switch (themeMode) {
      case AppThemeMode.system:
        return ThemeMode.system;
      case AppThemeMode.light:
        return ThemeMode.light;
      case AppThemeMode.dark:
        return ThemeMode.dark;
    }
  }
}

// 主题设置控制器
class ThemeSettingsNotifier extends StateNotifier<ThemeSettings> {
  static const String _themeModeKey = 'theme_mode';
  static const String _colorSchemeTypeKey = 'color_scheme_type';

  ThemeSettingsNotifier() : super(const ThemeSettings()) {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();

    final themeModeIndex = prefs.getInt(_themeModeKey) ?? 0;
    final colorSchemeTypeIndex = prefs.getInt(_colorSchemeTypeKey) ?? 0;

    state = ThemeSettings(
      themeMode: AppThemeMode.values[themeModeIndex],
      colorSchemeType: ColorSchemeType.values[colorSchemeTypeIndex],
    );
  }

  Future<void> setThemeMode(AppThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_themeModeKey, mode.index);
    state = state.copyWith(themeMode: mode);
  }

  Future<void> setColorSchemeType(ColorSchemeType type) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_colorSchemeTypeKey, type.index);
    state = state.copyWith(colorSchemeType: type);
  }
}

// 主题设置提供者
final themeSettingsProvider =
    StateNotifierProvider<ThemeSettingsNotifier, ThemeSettings>((ref) {
  return ThemeSettingsNotifier();
});
