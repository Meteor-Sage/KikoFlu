import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/floating_lyric_service.dart';

/// 悬浮歌词样式设置
class FloatingLyricStyle {
  final double fontSize; // 字体大小 (14-32)
  final double opacity; // 不透明度 (0.5-1.0)
  final Color textColor; // 文字颜色
  final Color backgroundColor; // 背景颜色
  final double cornerRadius; // 圆角半径 (0-24)
  final double paddingHorizontal; // 水平内边距 (12-40)
  final double paddingVertical; // 垂直内边距 (6-20)

  const FloatingLyricStyle({
    this.fontSize = 16.0,
    this.opacity = 0.95,
    this.textColor = Colors.white,
    this.backgroundColor = const Color(0xFF000000),
    this.cornerRadius = 16.0,
    this.paddingHorizontal = 20.0,
    this.paddingVertical = 10.0,
  });

  FloatingLyricStyle copyWith({
    double? fontSize,
    double? opacity,
    Color? textColor,
    Color? backgroundColor,
    double? cornerRadius,
    double? paddingHorizontal,
    double? paddingVertical,
  }) {
    return FloatingLyricStyle(
      fontSize: fontSize ?? this.fontSize,
      opacity: opacity ?? this.opacity,
      textColor: textColor ?? this.textColor,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      cornerRadius: cornerRadius ?? this.cornerRadius,
      paddingHorizontal: paddingHorizontal ?? this.paddingHorizontal,
      paddingVertical: paddingVertical ?? this.paddingVertical,
    );
  }

  // 转换为 Map 用于保存
  Map<String, dynamic> toMap() {
    return {
      'fontSize': fontSize,
      'opacity': opacity,
      'textColor': textColor.value,
      'backgroundColor': backgroundColor.value,
      'cornerRadius': cornerRadius,
      'paddingHorizontal': paddingHorizontal,
      'paddingVertical': paddingVertical,
    };
  }

  // 从 Map 恢复
  factory FloatingLyricStyle.fromMap(Map<String, dynamic> map) {
    return FloatingLyricStyle(
      fontSize: map['fontSize']?.toDouble() ?? 16.0,
      opacity: map['opacity']?.toDouble() ?? 0.95,
      textColor: Color(map['textColor'] ?? Colors.white.value),
      backgroundColor:
          Color(map['backgroundColor'] ?? const Color(0xFF000000).value),
      cornerRadius: map['cornerRadius']?.toDouble() ?? 16.0,
      paddingHorizontal: map['paddingHorizontal']?.toDouble() ?? 20.0,
      paddingVertical: map['paddingVertical']?.toDouble() ?? 10.0,
    );
  }

  // 获取背景颜色（带透明度）
  Color get backgroundColorWithOpacity {
    return backgroundColor.withOpacity(opacity);
  }

  // 获取 ARGB 格式的颜色值（用于原生代码）
  int get textColorArgb => textColor.value;

  int get backgroundColorArgb {
    final color = backgroundColor.withOpacity(opacity);
    return color.value;
  }
}

/// 悬浮歌词样式 Provider
final floatingLyricStyleProvider =
    StateNotifierProvider<FloatingLyricStyleNotifier, FloatingLyricStyle>(
        (ref) {
  return FloatingLyricStyleNotifier();
});

class FloatingLyricStyleNotifier extends StateNotifier<FloatingLyricStyle> {
  static const _keyPrefix = 'floating_lyric_style_';

  FloatingLyricStyleNotifier() : super(const FloatingLyricStyle()) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();

    final fontSize = prefs.getDouble('${_keyPrefix}fontSize') ?? 16.0;
    final opacity = prefs.getDouble('${_keyPrefix}opacity') ?? 0.95;
    final textColor =
        Color(prefs.getInt('${_keyPrefix}textColor') ?? Colors.white.value);
    final backgroundColor = Color(
        prefs.getInt('${_keyPrefix}backgroundColor') ??
            const Color(0xFF000000).value);
    final cornerRadius = prefs.getDouble('${_keyPrefix}cornerRadius') ?? 16.0;
    final paddingHorizontal =
        prefs.getDouble('${_keyPrefix}paddingHorizontal') ?? 20.0;
    final paddingVertical =
        prefs.getDouble('${_keyPrefix}paddingVertical') ?? 10.0;

    state = FloatingLyricStyle(
      fontSize: fontSize,
      opacity: opacity,
      textColor: textColor,
      backgroundColor: backgroundColor,
      cornerRadius: cornerRadius,
      paddingHorizontal: paddingHorizontal,
      paddingVertical: paddingVertical,
    );

    // 应用到悬浮窗
    _applyStyle();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('${_keyPrefix}fontSize', state.fontSize);
    await prefs.setDouble('${_keyPrefix}opacity', state.opacity);
    await prefs.setInt('${_keyPrefix}textColor', state.textColor.value);
    await prefs.setInt(
        '${_keyPrefix}backgroundColor', state.backgroundColor.value);
    await prefs.setDouble('${_keyPrefix}cornerRadius', state.cornerRadius);
    await prefs.setDouble(
        '${_keyPrefix}paddingHorizontal', state.paddingHorizontal);
    await prefs.setDouble(
        '${_keyPrefix}paddingVertical', state.paddingVertical);
  }

  void applyStyle() {
    FloatingLyricService.instance.updateStyle(
      fontSize: state.fontSize,
      textColor: state.textColorArgb,
      backgroundColor: state.backgroundColorArgb,
      cornerRadius: state.cornerRadius,
      paddingHorizontal: state.paddingHorizontal,
      paddingVertical: state.paddingVertical,
    );
  }

  void _applyStyle() => applyStyle();

  Future<void> updateFontSize(double size) async {
    state = state.copyWith(fontSize: size);
    await _save();
    _applyStyle();
  }

  Future<void> updateOpacity(double opacity) async {
    state = state.copyWith(opacity: opacity);
    await _save();
    _applyStyle();
  }

  Future<void> updateTextColor(Color color) async {
    state = state.copyWith(textColor: color);
    await _save();
    _applyStyle();
  }

  Future<void> updateBackgroundColor(Color color) async {
    state = state.copyWith(backgroundColor: color);
    await _save();
    _applyStyle();
  }

  Future<void> updateCornerRadius(double radius) async {
    state = state.copyWith(cornerRadius: radius);
    await _save();
    _applyStyle();
  }

  Future<void> updatePaddingHorizontal(double padding) async {
    state = state.copyWith(paddingHorizontal: padding);
    await _save();
    _applyStyle();
  }

  Future<void> updatePaddingVertical(double padding) async {
    state = state.copyWith(paddingVertical: padding);
    await _save();
    _applyStyle();
  }

  /// 重置为默认样式
  Future<void> reset() async {
    state = const FloatingLyricStyle();
    await _save();
    _applyStyle();
  }

  /// 应用预设样式
  Future<void> applyPreset(FloatingLyricStylePreset preset) async {
    state = preset.style;
    await _save();
    _applyStyle();
  }
}

/// 预设样式
enum FloatingLyricStylePreset {
  classic, // 经典
  modern, // 现代
  minimal, // 极简
  vibrant, // 鲜艳
  elegant, // 优雅
}

extension FloatingLyricStylePresetExtension on FloatingLyricStylePreset {
  String get name {
    switch (this) {
      case FloatingLyricStylePreset.classic:
        return '经典';
      case FloatingLyricStylePreset.modern:
        return '现代';
      case FloatingLyricStylePreset.minimal:
        return '极简';
      case FloatingLyricStylePreset.vibrant:
        return '鲜艳';
      case FloatingLyricStylePreset.elegant:
        return '优雅';
    }
  }

  String get description {
    switch (this) {
      case FloatingLyricStylePreset.classic:
        return '黑底白字，经典耐看';
      case FloatingLyricStylePreset.modern:
        return '渐变背景，时尚现代';
      case FloatingLyricStylePreset.minimal:
        return '轻透明，简约优雅';
      case FloatingLyricStylePreset.vibrant:
        return '色彩鲜明，活力四射';
      case FloatingLyricStylePreset.elegant:
        return '深蓝底，高雅气质';
    }
  }

  FloatingLyricStyle get style {
    switch (this) {
      case FloatingLyricStylePreset.classic:
        return const FloatingLyricStyle(
          fontSize: 16.0,
          opacity: 0.95,
          textColor: Colors.white,
          backgroundColor: Color(0xFF000000),
          cornerRadius: 16.0,
          paddingHorizontal: 20.0,
          paddingVertical: 10.0,
        );
      case FloatingLyricStylePreset.modern:
        return const FloatingLyricStyle(
          fontSize: 18.0,
          opacity: 0.90,
          textColor: Colors.white,
          backgroundColor: Color(0xFF1A237E), // 深蓝紫
          cornerRadius: 20.0,
          paddingHorizontal: 24.0,
          paddingVertical: 12.0,
        );
      case FloatingLyricStylePreset.minimal:
        return const FloatingLyricStyle(
          fontSize: 15.0,
          opacity: 0.75,
          textColor: Color(0xFF212121),
          backgroundColor: Color(0xFFFFFFFF),
          cornerRadius: 12.0,
          paddingHorizontal: 16.0,
          paddingVertical: 8.0,
        );
      case FloatingLyricStylePreset.vibrant:
        return const FloatingLyricStyle(
          fontSize: 17.0,
          opacity: 0.92,
          textColor: Colors.white,
          backgroundColor: Color(0xFFE91E63), // 粉红
          cornerRadius: 18.0,
          paddingHorizontal: 22.0,
          paddingVertical: 11.0,
        );
      case FloatingLyricStylePreset.elegant:
        return const FloatingLyricStyle(
          fontSize: 16.0,
          opacity: 0.88,
          textColor: Color(0xFFE3F2FD),
          backgroundColor: Color(0xFF0D47A1), // 深蓝
          cornerRadius: 16.0,
          paddingHorizontal: 20.0,
          paddingVertical: 10.0,
        );
    }
  }
}
