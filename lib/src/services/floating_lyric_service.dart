import 'package:flutter/services.dart';
import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'package:desktop_multi_window/desktop_multi_window.dart';

import 'log_service.dart';

final _log = LogService.instance;

/// 悬浮字幕服务
/// 负责管理桌面悬浮窗显示和字幕更新
class FloatingLyricService {
  static const _platform = MethodChannel('com.kikoeru.flutter/floating_lyric');

  static FloatingLyricService? _instance;
  String? _windowId;
  String? _lastText;

  final _onCloseController = StreamController<void>.broadcast();
  Stream<void> get onClose => _onCloseController.stream;
  final _onTouchEnabledChangedController = StreamController<bool>.broadcast();
  Stream<bool> get onTouchEnabledChanged =>
      _onTouchEnabledChangedController.stream;

  FloatingLyricService._() {
    _platform.setMethodCallHandler(_handleMethodCall);
  }

  Future<dynamic> _handleMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'onClose':
        _onCloseController.add(null);
        break;
      case 'onTouchEnabledChanged':
        final arguments = call.arguments;
        final enabled = arguments is Map ? arguments['enabled'] == true : false;
        _onTouchEnabledChangedController.add(enabled);
        break;
      case 'onDiagnostic':
        _recordNativeDiagnostic(call.arguments);
        break;
    }
  }

  void _recordNativeDiagnostic(dynamic arguments) {
    if (arguments is! Map) {
      _log.warning('收到无法解析的原生诊断数据: $arguments', tag: 'FloatingLyric.iOS');
      return;
    }

    final event = arguments['event']?.toString() ?? 'unknown_event';
    final level = arguments['level']?.toString() ?? 'info';
    final rawDetails = arguments['details'];
    var details = '';
    if (rawDetails is Map && rawDetails.isNotEmpty) {
      final entries =
          rawDetails.entries
              .map((entry) => MapEntry(entry.key.toString(), entry.value))
              .toList()
            ..sort((a, b) => a.key.compareTo(b.key));
      details = entries
          .map((entry) => '${entry.key}=${entry.value}')
          .join(', ');
    }
    final message = details.isEmpty ? event : '$event | $details';

    switch (level) {
      case 'error':
        _log.error(message, tag: 'FloatingLyric.iOS');
        break;
      case 'warning':
        _log.warning(message, tag: 'FloatingLyric.iOS');
        break;
      default:
        _log.info(message, tag: 'FloatingLyric.iOS');
    }
  }

  static FloatingLyricService get instance {
    _instance ??= FloatingLyricService._();
    return _instance!;
  }

  /// 检查是否支持悬浮窗
  bool get isSupported =>
      Platform.isAndroid ||
      Platform.isWindows ||
      Platform.isMacOS ||
      Platform.isIOS;

  /// 显示悬浮窗
  /// [text] 要显示的文本内容
  /// [style] 初始样式参数
  Future<bool> show(String text, {Map<String, dynamic>? style}) async {
    if (!isSupported) {
      _log.captureOutput('[FloatingLyric] 当前平台不支持悬浮窗');
      return false;
    }

    if (Platform.isWindows) {
      try {
        if (_windowId != null) {
          final result = await updateText(text);
          if (result) {
            // 如果更新成功，且有样式参数，也更新样式
            if (style != null) {
              await updateStyle(
                fontSize: style['fontSize'],
                textColor: style['textColor'],
                backgroundColor: style['backgroundColor'],
                cornerRadius: style['cornerRadius'],
                paddingHorizontal: style['paddingHorizontal'],
                paddingVertical: style['paddingVertical'],
              );
            }
            return true;
          }
          // 如果更新失败，说明窗口可能已关闭，重置ID并重新创建
          _windowId = null;
        }

        final Map<String, dynamic> args = {'text': text};
        if (style != null) {
          args.addAll(style);
        }

        final controller = await WindowController.create(
          WindowConfiguration(
            arguments: jsonEncode(args),
          ),
        );
        _windowId = controller.windowId;
        await controller.show();
        return true;
      } catch (e) {
        _log.captureOutput('[FloatingLyric] Desktop显示悬浮窗失败: $e');
        return false;
      }
    }

    try {
      final Map<String, dynamic> args = {'text': text};
      if (style != null) {
        args.addAll(style);
      }
      final result = await _platform.invokeMethod('show', args);
      final shown = result == true;
      _log.info(
        '悬浮窗启动结果: $shown',
        tag: Platform.isIOS ? 'FloatingLyric.iOS' : 'FloatingLyric',
      );
      return shown;
    } catch (e) {
      _log.captureOutput('[FloatingLyric] 显示悬浮窗失败: $e');
      return false;
    }
  }

  /// 隐藏悬浮窗
  Future<bool> hide() async {
    if (!isSupported) {
      return false;
    }

    if (Platform.isWindows) {
      if (_windowId != null) {
        try {
          final controller = WindowController.fromWindowId(_windowId!);
          await controller.invokeMethod('close');
        } catch (e) {
          _log.captureOutput('[FloatingLyric] Windows隐藏悬浮窗失败: $e');
        }
        _windowId = null;
        return true;
      }
      return false;
    }

    try {
      final result = await _platform.invokeMethod('hide');
      _log.captureOutput('[FloatingLyric] 隐藏悬浮窗');
      return result == true;
    } catch (e) {
      _log.captureOutput('[FloatingLyric] 隐藏悬浮窗失败: $e');
      return false;
    }
  }

  /// 更新悬浮窗文本
  /// [text] 新的文本内容
  Future<bool> updateText(String text) async {
    if (!isSupported) {
      return false;
    }

    // 去重检查，避免频繁调用 MethodChannel
    if (text == _lastText) {
      return true;
    }
    _lastText = text;

    if (Platform.isWindows) {
      if (_windowId != null) {
        try {
          // _log.captureOutput('[FloatingLyric] Updating text for window $_windowId: $text');
          final controller = WindowController.fromWindowId(_windowId!);
          await controller.invokeMethod('updateText', {
            'text': text,
          });
          return true;
        } catch (e) {
          _log.captureOutput('[FloatingLyric] Windows更新文本失败: $e');
          // 如果是通道未注册（通常意味着窗口已关闭或未初始化），重置 ID
          if (e.toString().contains('CHANNEL_UNREGISTERED')) {
            _windowId = null;
          }
          return false;
        }
      }
      return false;
    }

    try {
      final result = await _platform.invokeMethod('updateText', {
        'text': text,
      });
      return result == true;
    } catch (e) {
      _log.captureOutput('[FloatingLyric] 更新文本失败: $e');
      return false;
    }
  }

  /// 检查是否有悬浮窗权限
  Future<bool> hasPermission() async {
    if (Platform.isWindows || Platform.isMacOS || Platform.isIOS) return true;
    if (!isSupported) {
      return false;
    }

    try {
      final result = await _platform.invokeMethod('hasPermission');
      return result == true;
    } catch (e) {
      _log.captureOutput('[FloatingLyric] 检查权限失败: $e');
      return false;
    }
  }

  /// 请求悬浮窗权限
  Future<bool> requestPermission() async {
    if (Platform.isWindows || Platform.isMacOS || Platform.isIOS) return true;
    if (!isSupported) {
      return false;
    }

    try {
      final result = await _platform.invokeMethod('requestPermission');
      _log.captureOutput('[FloatingLyric] 请求权限结果: $result');
      return result == true;
    } catch (e) {
      _log.captureOutput('[FloatingLyric] 请求权限失败: $e');
      return false;
    }
  }

  /// 更新悬浮窗样式
  /// [fontSize] 字体大小
  /// [textColor] 文字颜色（ARGB格式）
  /// [backgroundColor] 背景颜色（ARGB格式）
  /// [cornerRadius] 圆角半径
  /// [paddingHorizontal] 水平内边距
  /// [paddingVertical] 垂直内边距
  Future<bool> updateStyle({
    double? fontSize,
    int? textColor,
    int? backgroundColor,
    double? cornerRadius,
    double? paddingHorizontal,
    double? paddingVertical,
  }) async {
    if (!isSupported) {
      return false;
    }

    final params = <String, dynamic>{};
    if (fontSize != null) params['fontSize'] = fontSize;
    if (textColor != null) params['textColor'] = textColor;
    if (backgroundColor != null) params['backgroundColor'] = backgroundColor;
    if (cornerRadius != null) params['cornerRadius'] = cornerRadius;
    if (paddingHorizontal != null) {
      params['paddingHorizontal'] = paddingHorizontal;
    }
    if (paddingVertical != null) params['paddingVertical'] = paddingVertical;

    if (Platform.isWindows) {
      if (_windowId != null) {
        try {
          final controller = WindowController.fromWindowId(_windowId!);
          await controller.invokeMethod('updateStyle', params);
          return true;
        } catch (e) {
          _log.captureOutput('[FloatingLyric] Windows更新样式失败: $e');
          if (e.toString().contains('CHANNEL_UNREGISTERED')) {
            _windowId = null;
          }
          return false;
        }
      }
      return false;
    }

    try {
      final result = await _platform.invokeMethod('updateStyle', params);
      _log.captureOutput('[FloatingLyric] 更新样式成功');
      return result == true;
    } catch (e) {
      _log.captureOutput('[FloatingLyric] 更新样式失败: $e');
      return false;
    }
  }

  /// 设置悬浮窗触摸是否启用（仅 Android）
  Future<bool> setTouchEnabled(bool enabled) async {
    if (!Platform.isAndroid) return true;
    try {
      final result = await _platform.invokeMethod('setTouchEnabled', {
        'enabled': enabled,
      });
      return result == true;
    } catch (e) {
      _log.captureOutput('[FloatingLyric] 设置触摸模式失败: $e');
      return false;
    }
  }

  /// 设置 FPS 显示开关（仅 iOS）
  Future<bool> setFPSEnabled(bool enabled) async {
    if (!Platform.isIOS) return false;
    try {
      final result = await _platform.invokeMethod('setFPSEnabled', {
        'enabled': enabled,
      });
      return result == true;
    } catch (e) {
      _log.captureOutput('[FloatingLyric] 设置FPS显示失败: $e');
      return false;
    }
  }

  /// 设置网速显示开关（仅 iOS）
  Future<bool> setNetworkSpeedEnabled(bool enabled) async {
    if (!Platform.isIOS) return false;
    try {
      final result = await _platform.invokeMethod('setNetworkSpeedEnabled', {
        'enabled': enabled,
      });
      return result == true;
    } catch (e) {
      _log.captureOutput('[FloatingLyric] 设置网速显示失败: $e');
      return false;
    }
  }
}
