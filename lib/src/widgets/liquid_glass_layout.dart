import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// Shared geometry for the liquid-glass navigation stack.
///
/// Keeping these values in one place ensures that the MiniPlayer and the
/// floating tab bar have identical horizontal bounds and compatible corners.
abstract final class LiquidGlassLayout {
  static const double horizontalPadding = 12;
  static const double verticalPadding = 6;
  static const double navigationBarHeight = 78;
  static const double cornerRadius = 24;

  static const double navigationBarBottomPadding = 0;
  static const double dockSafeAreaReduction = 8;

  static double nativeTabBarExpansion(BuildContext context) {
    return defaultTargetPlatform == TargetPlatform.iOS ? 20 : 0;
  }

  static double dockBottomInset(BuildContext context) {
    final systemInset = MediaQuery.viewPaddingOf(context).bottom;
    return (systemInset - dockSafeAreaReduction).clamp(0, double.infinity);
  }
}

/// Exposes the measured dock as the bottom safe inset to nested Scaffolds.
/// Their backgrounds still fill the page, while FABs and SafeArea controls
/// stay above the floating glass stack.
class LiquidGlassDockMediaQuery extends StatelessWidget {
  const LiquidGlassDockMediaQuery({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final extent = LiquidGlassDockScope.extentOf(context);
    final mediaQuery = MediaQuery.of(context);
    final bottom =
        extent > mediaQuery.padding.bottom ? extent : mediaQuery.padding.bottom;
    return MediaQuery(
      data: mediaQuery.copyWith(
        padding: mediaQuery.padding.copyWith(bottom: bottom),
      ),
      child: child,
    );
  }
}

/// Provides the measured bottom glass dock height to scrollable descendants.
///
/// The height changes when the mini player appears, hides, or starts showing
/// lyrics, so a fixed safe-area constant would either clip content or leave a
/// large blank tail. Virtualized collections read this notifier and append the
/// exact current extent after their content.
class LiquidGlassDockScope extends InheritedNotifier<ValueNotifier<double>> {
  const LiquidGlassDockScope({
    super.key,
    required ValueNotifier<double> notifier,
    required super.child,
  }) : super(notifier: notifier);

  static double extentOf(BuildContext context) {
    return context
            .dependOnInheritedWidgetOfExactType<LiquidGlassDockScope>()
            ?.notifier
            ?.value ??
        0;
  }
}

class LiquidGlassDockExtentReporter extends SingleChildRenderObjectWidget {
  const LiquidGlassDockExtentReporter({
    super.key,
    required this.onChanged,
    required super.child,
  });

  final ValueChanged<double> onChanged;

  @override
  RenderObject createRenderObject(BuildContext context) {
    return _LiquidGlassDockExtentRenderObject(onChanged);
  }

  @override
  void updateRenderObject(BuildContext context, RenderObject renderObject) {
    final extentRenderObject =
        renderObject as _LiquidGlassDockExtentRenderObject;
    extentRenderObject.onChanged = onChanged;
  }
}

class _LiquidGlassDockExtentRenderObject extends RenderProxyBox {
  _LiquidGlassDockExtentRenderObject(this.onChanged);

  ValueChanged<double> onChanged;
  double? _lastExtent;

  @override
  void performLayout() {
    super.performLayout();
    final extent = size.height;
    if (_lastExtent == extent) return;
    _lastExtent = extent;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (attached) onChanged(extent);
    });
  }
}
