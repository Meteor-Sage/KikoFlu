import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:window_manager/window_manager.dart';
import '../services/log_service.dart';

class DesktopFloatingLyric extends StatefulWidget {
  final dynamic windowId;
  final Map<String, dynamic>? arguments;

  const DesktopFloatingLyric({
    super.key,
    required this.windowId,
    this.arguments,
  });

  @override
  State<DesktopFloatingLyric> createState() => _DesktopFloatingLyricState();
}

class _DesktopFloatingLyricState extends State<DesktopFloatingLyric>
    with WindowListener {
  static const _linuxWindowChannel = MethodChannel(
    'com.kikoeru.flutter/floating_lyric_linux',
  );

  String _text = '♪ - ♪';

  // Style properties
  double _fontSize = 24.0;
  Color _textColor = Colors.white;
  Color _backgroundColor = Colors.transparent;
  double _cornerRadius = 8.0;
  double _paddingHorizontal = 16.0;
  double _paddingVertical = 8.0;
  bool _touchEnabled = true;
  bool _isClosing = false;

  static const _linuxFontFallback = [
    'Noto Sans CJK SC',
    'Noto Sans CJK TC',
    'Noto Sans CJK JP',
    'Source Han Sans SC',
    'WenQuanYi Micro Hei',
    'Droid Sans Fallback',
  ];

  @override
  void initState() {
    super.initState();
    windowManager.addListener(this);

    if (widget.arguments != null) {
      if (widget.arguments!.containsKey('text')) {
        _text = widget.arguments!['text'] as String;
      }
      if (widget.arguments!['touchEnabled'] is bool) {
        _touchEnabled = widget.arguments!['touchEnabled'] as bool;
      }
      _updateStyleProperties(widget.arguments!);
    }

    _initWindow();
  }

  void _updateStyleProperties(Map args) {
    if (args.containsKey('fontSize')) {
      _fontSize = (args['fontSize'] as num).toDouble();
    }
    if (args.containsKey('textColor')) {
      _textColor = Color(args['textColor'] as int);
    }
    if (args.containsKey('backgroundColor')) {
      _backgroundColor = Color(args['backgroundColor'] as int);
    }
    if (args.containsKey('cornerRadius')) {
      _cornerRadius = (args['cornerRadius'] as num).toDouble();
    }
    if (args.containsKey('paddingHorizontal')) {
      _paddingHorizontal = (args['paddingHorizontal'] as num).toDouble();
    }
    if (args.containsKey('paddingVertical')) {
      _paddingVertical = (args['paddingVertical'] as num).toDouble();
    }
  }

  Future<void> _initWindow() async {
    try {
      // Register window messaging before platform setup so the main engine can
      // still close or update this window if a best-effort window hint fails.
      final controller = await WindowController.fromCurrentEngine();
      await controller.setWindowMethodHandler(_handleMethodCall);

      await windowManager.setAsFrameless();
      await windowManager.setAlwaysOnTop(true);
      if (Platform.isLinux) {
        // The close button must not route through GTK's default delete-event
        // handler, which can close the owning Flutter application.
        await windowManager.setPreventClose(true);
      }
      await windowManager.setBackgroundColor(Colors.transparent);
      if (!Platform.isLinux) {
        await windowManager.setHasShadow(false);
      }
      // 设置一个合理的默认大小
      await windowManager.setSize(const Size(800, 200));

      if (Platform.isLinux) {
        await windowManager.show();
        final capabilities = await _linuxWindowChannel
            .invokeMapMethod<String, dynamic>('configureWindow');
        logOutput(
          '[DesktopFloatingLyric] Linux window backend: '
          '${capabilities?['backend'] ?? 'unknown'}, '
          'transparent=${capabilities?['supportsTransparency'] ?? false}, '
          'clickThrough=${capabilities?['supportsClickThrough'] ?? false}, '
          'reliableAlwaysOnTop='
          '${capabilities?['reliableAlwaysOnTop'] ?? false}, '
          'diagnosticLogPath=${capabilities?['diagnosticLogPath'] ?? 'unknown'}',
        );
        // Reapply these hints after realization; some X11 window managers
        // ignore pre-show keep-above requests.
        await windowManager.setAlwaysOnTop(true);
        await _applyTouchMode();
      } else {
        await _applyTouchMode();
      }
    } catch (e) {
      logOutput('[DesktopFloatingLyric] Failed to init window: $e');
      if (Platform.isLinux) {
        try {
          await windowManager.show();
          await windowManager.setAlwaysOnTop(true);
          await _linuxWindowChannel.invokeMethod<void>('configureWindow');
          await _applyTouchMode();
        } catch (showError) {
          logOutput(
            '[DesktopFloatingLyric] Failed to show Linux fallback window: '
            '$showError',
          );
        }
      }
    }
  }

  Future<void> _applyTouchMode() async {
    if (Platform.isLinux) {
      await _linuxWindowChannel.invokeMethod<void>('setIgnoreMouseEvents', {
        'ignore': !_touchEnabled,
      });
      return;
    }
    if (Platform.isWindows || Platform.isMacOS) {
      await windowManager.setIgnoreMouseEvents(!_touchEnabled);
    }
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    super.dispose();
  }

  Future<dynamic> _handleMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'updateText':
        if (mounted) {
          setState(() {
            _text = call.arguments['text'] as String;
          });
        }
        return true;
      case 'updateStyle':
        if (mounted) {
          setState(() {
            _updateStyleProperties(call.arguments as Map);
          });
        }
        return true;
      case 'close':
        if (Platform.isLinux) {
          // Keep the secondary engine alive. Destroying a Linux secondary
          // window can race Flutter's view removal and terminate the app.
          await _linuxWindowChannel.invokeMethod<void>('hideWindow');
        } else {
          await windowManager.close();
        }
        return true;
      case 'setTouchEnabled':
        final arguments = call.arguments;
        _touchEnabled = arguments is Map && arguments['enabled'] == true;
        await _applyTouchMode();
        return true;
      default:
        return null;
    }
  }

  Future<void> _hideLinuxWindow() async {
    if (_isClosing) return;
    _isClosing = true;
    try {
      await _linuxWindowChannel.invokeMethod<void>('hideWindow');
    } catch (e) {
      logOutput('[DesktopFloatingLyric] Failed to hide Linux window: $e');
    } finally {
      _isClosing = false;
    }
  }

  @override
  void onWindowClose() {
    if (Platform.isLinux) {
      // window_manager emits this callback for the native close button while
      // prevent-close is enabled. Hide instead of destroying the engine.
      _hideLinuxWindow();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      color: Colors.transparent,
      home: Scaffold(
        backgroundColor: Colors.transparent,
        body: GestureDetector(
          onPanStart: (_) => windowManager.startDragging(),
          child: Container(
            width: double.infinity,
            height: double.infinity,
            color: Colors.transparent,
            child: Center(
              child: Container(
                decoration: BoxDecoration(
                  color: _backgroundColor,
                  borderRadius: BorderRadius.circular(_cornerRadius),
                ),
                padding: EdgeInsets.symmetric(
                  horizontal: _paddingHorizontal,
                  vertical: _paddingVertical,
                ),
                child: Text(
                  _text,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: _fontSize,
                    fontWeight: FontWeight.bold,
                    color: _textColor,
                    fontFamilyFallback: Platform.isLinux
                        ? _linuxFontFallback
                        : null,
                    shadows: [
                      Shadow(
                        offset: const Offset(1.0, 1.0),
                        blurRadius: 3.0,
                        color: Colors.black.withValues(alpha: 0.8),
                      ),
                      Shadow(
                        offset: const Offset(-1.0, -1.0),
                        blurRadius: 3.0,
                        color: Colors.black.withValues(alpha: 0.8),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
