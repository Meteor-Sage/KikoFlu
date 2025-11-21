import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:window_manager/window_manager.dart';

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
  String _text = '♪ - ♪';

  // Style properties
  double _fontSize = 24.0;
  Color _textColor = Colors.white;
  Color _backgroundColor = Colors.transparent;
  double _cornerRadius = 8.0;
  double _paddingHorizontal = 16.0;
  double _paddingVertical = 8.0;

  @override
  void initState() {
    super.initState();
    windowManager.addListener(this);

    _initWindow();

    if (widget.arguments != null) {
      if (widget.arguments!.containsKey('text')) {
        _text = widget.arguments!['text'] as String;
      }
      _updateStyleProperties(widget.arguments!);
    }
  }

  void _updateStyleProperties(Map args) {
    if (args.containsKey('fontSize'))
      _fontSize = (args['fontSize'] as num).toDouble();
    if (args.containsKey('textColor'))
      _textColor = Color(args['textColor'] as int);
    if (args.containsKey('backgroundColor'))
      _backgroundColor = Color(args['backgroundColor'] as int);
    if (args.containsKey('cornerRadius'))
      _cornerRadius = (args['cornerRadius'] as num).toDouble();
    if (args.containsKey('paddingHorizontal'))
      _paddingHorizontal = (args['paddingHorizontal'] as num).toDouble();
    if (args.containsKey('paddingVertical'))
      _paddingVertical = (args['paddingVertical'] as num).toDouble();
  }

  Future<void> _initWindow() async {
    await windowManager.setAsFrameless();
    await windowManager.setAlwaysOnTop(true);
    await windowManager.setBackgroundColor(Colors.transparent);
    await windowManager.setHasShadow(false);
    // 设置一个合理的默认大小
    await windowManager.setSize(const Size(800, 120));

    // Setup method handler
    final controller = await WindowController.fromCurrentEngine();
    controller.setWindowMethodHandler(_handleMethodCall);
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
        await windowManager.close();
        return true;
      default:
        return null;
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
                    shadows: [
                      Shadow(
                        offset: const Offset(1.0, 1.0),
                        blurRadius: 3.0,
                        color: Colors.black.withOpacity(0.8),
                      ),
                      Shadow(
                        offset: const Offset(-1.0, -1.0),
                        blurRadius: 3.0,
                        color: Colors.black.withOpacity(0.8),
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
