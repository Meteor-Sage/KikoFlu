import 'package:flutter/services.dart';
import 'dart:io';

/// 悬浮歌词服务
/// 负责管理桌面悬浮窗显示和歌词更新
class FloatingLyricService {
  static const _platform = MethodChannel('com.kikoeru.flutter/floating_lyric');

  static FloatingLyricService? _instance;

  FloatingLyricService._();

  static FloatingLyricService get instance {
    _instance ??= FloatingLyricService._();
    return _instance!;
  }

  /// 检查是否支持悬浮窗（仅安卓平台）
  bool get isSupported => Platform.isAndroid;

  /// 显示悬浮窗
  /// [text] 要显示的文本内容
  Future<bool> show(String text) async {
    if (!isSupported) {
      print('[FloatingLyric] 当前平台不支持悬浮窗');
      return false;
    }

    try {
      final result = await _platform.invokeMethod('show', {
        'text': text,
      });
      print('[FloatingLyric] 显示悬浮窗: $text');
      return result == true;
    } catch (e) {
      print('[FloatingLyric] 显示悬浮窗失败: $e');
      return false;
    }
  }

  /// 隐藏悬浮窗
  Future<bool> hide() async {
    if (!isSupported) {
      return false;
    }

    try {
      final result = await _platform.invokeMethod('hide');
      print('[FloatingLyric] 隐藏悬浮窗');
      return result == true;
    } catch (e) {
      print('[FloatingLyric] 隐藏悬浮窗失败: $e');
      return false;
    }
  }

  /// 更新悬浮窗文本
  /// [text] 新的文本内容
  Future<bool> updateText(String text) async {
    if (!isSupported) {
      return false;
    }

    try {
      final result = await _platform.invokeMethod('updateText', {
        'text': text,
      });
      return result == true;
    } catch (e) {
      print('[FloatingLyric] 更新文本失败: $e');
      return false;
    }
  }

  /// 检查是否有悬浮窗权限
  Future<bool> hasPermission() async {
    if (!isSupported) {
      return false;
    }

    try {
      final result = await _platform.invokeMethod('hasPermission');
      return result == true;
    } catch (e) {
      print('[FloatingLyric] 检查权限失败: $e');
      return false;
    }
  }

  /// 请求悬浮窗权限
  Future<bool> requestPermission() async {
    if (!isSupported) {
      return false;
    }

    try {
      final result = await _platform.invokeMethod('requestPermission');
      print('[FloatingLyric] 请求权限结果: $result');
      return result == true;
    } catch (e) {
      print('[FloatingLyric] 请求权限失败: $e');
      return false;
    }
  }

  /// 更新悬浮窗样式
  /// [fontSize] 字体大小
  /// [textColor] 文字颜色（ARGB格式）
  /// [backgroundColor] 背景颜色（ARGB格式）
  /// [alpha] 透明度 (0-255)
  Future<bool> updateStyle({
    double? fontSize,
    int? textColor,
    int? backgroundColor,
    int? alpha,
  }) async {
    if (!isSupported) {
      return false;
    }

    try {
      final params = <String, dynamic>{};
      if (fontSize != null) params['fontSize'] = fontSize;
      if (textColor != null) params['textColor'] = textColor;
      if (backgroundColor != null) params['backgroundColor'] = backgroundColor;
      if (alpha != null) params['alpha'] = alpha;

      final result = await _platform.invokeMethod('updateStyle', params);
      print('[FloatingLyric] 更新样式成功');
      return result == true;
    } catch (e) {
      print('[FloatingLyric] 更新样式失败: $e');
      return false;
    }
  }
}
