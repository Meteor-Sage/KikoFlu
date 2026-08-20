import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart' show PlatformViewHitTestBehavior;
import 'package:flutter/services.dart';

import 'glass_style.dart';

/// Embeds the native effect view that carries the glass material.
///
/// On iOS 26+ / macOS 26+ this is real UIGlassEffect /
/// NSGlassEffectView Liquid Glass; on older systems it is a blur
/// material. Either way the effect samples the content rendered beneath
/// it — Flutter widgets included.
class NativeGlassView extends StatefulWidget {
  const NativeGlassView({
    super.key,
    required this.style,
    required this.shape,
    required this.interactive,
    this.tint,
    this.onTap,
  });

  final LiquidGlassStyle style;
  final LiquidGlassShape shape;
  final bool interactive;
  final Color? tint;
  final VoidCallback? onTap;

  @override
  State<NativeGlassView> createState() => _NativeGlassViewState();
}

class _NativeGlassViewState extends State<NativeGlassView> {
  MethodChannel? _viewChannel;

  Map<String, Object?> get _params => {
    'style': widget.style.name,
    'tint': widget.tint?.toARGB32(),
    'interactive': widget.interactive,
    'capsule': widget.shape.capsule,
    'cornerRadius': widget.shape.cornerRadius,
        'dark': CupertinoTheme.of(context).brightness == Brightness.dark,
  };

  @override
  void didUpdateWidget(NativeGlassView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.style != oldWidget.style ||
        widget.shape != oldWidget.shape ||
        widget.interactive != oldWidget.interactive ||
        widget.tint != oldWidget.tint) {
      _viewChannel?.invokeMethod<void>('update', _params);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _viewChannel?.invokeMethod<void>('update', _params);
  }

  @override
  Widget build(BuildContext context) {
    final hitTestBehavior = widget.interactive
        ? PlatformViewHitTestBehavior.opaque
        : PlatformViewHitTestBehavior.transparent;
    final Widget view = defaultTargetPlatform == TargetPlatform.macOS
        ? AppKitView(
            viewType: 'real_liquid_glass/glass_view',
            creationParams: _params,
            creationParamsCodec: const StandardMessageCodec(),
            hitTestBehavior: hitTestBehavior,
            onPlatformViewCreated: _onViewCreated,
          )
        : UiKitView(
            viewType: 'real_liquid_glass/glass_view',
            creationParams: _params,
            creationParamsCodec: const StandardMessageCodec(),
            hitTestBehavior: hitTestBehavior,
            onPlatformViewCreated: _onViewCreated,
          );
    return IgnorePointer(ignoring: !widget.interactive, child: view);
  }

  void _onViewCreated(int id) {
    final channel = MethodChannel('real_liquid_glass/glass_view_$id');
    _viewChannel = channel;
    channel.setMethodCallHandler((call) async {
      if (call.method == 'tap') widget.onTap?.call();
    });
  }

  @override
  void dispose() {
    _viewChannel?.setMethodCallHandler(null);
    super.dispose();
  }
}
