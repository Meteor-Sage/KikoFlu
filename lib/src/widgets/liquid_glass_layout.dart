import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:real_liquid_glass/real_liquid_glass.dart';

/// Shared geometry for the liquid-glass navigation stack.
///
/// Keeping these values in one place ensures that the MiniPlayer and the
/// floating tab bar have identical horizontal bounds and compatible corners.
abstract final class LiquidGlassLayout {
  static const double horizontalPadding = 12;
  static const double verticalPadding = 6;
  static const double iosNavigationBarHeight = 78;
  static const double cornerRadius = 24;

  static const double navigationBarBottomPadding = 0;

  // These metrics mirror LiquidGlassBottomBar's fallback item layout. The
  // resulting surface follows its content and the user's text scale instead
  // of applying the taller native iOS tab-bar height to every platform.
  static const double _fallbackIconSize = 24;
  static const double _fallbackItemGap = 2;
  static const double _fallbackLabelFontSize = 11;
  static const double _fallbackLabelLineHeight = 1.2;
  static const double _fallbackSurfacePadding = 8;

  static double navigationBarHeight(BuildContext context) {
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return iosNavigationBarHeight;
    }

    final mediaQuery = MediaQuery.of(context);
    final isCompactHeight =
        mediaQuery.orientation == Orientation.landscape &&
        mediaQuery.size.height < 600;
    final labelHeight =
        mediaQuery.textScaler.scale(_fallbackLabelFontSize) *
        _fallbackLabelLineHeight;
    final contentHeight =
        _fallbackIconSize +
        _fallbackItemGap +
        labelHeight +
        _fallbackSurfacePadding;

    // Compact phone/tablet landscapes trade a little breathing room for page
    // content. Larger text is still allowed to grow the control above its
    // default height, while the lower bounds preserve a comfortable target.
    final breathingRoom = isCompactHeight ? 8.0 : 12.0;
    final minimumHeight = isCompactHeight ? 56.0 : 60.0;
    final maximumHeight = isCompactHeight ? 72.0 : 92.0;
    return (contentHeight + breathingRoom)
        .clamp(minimumHeight, maximumHeight)
        .toDouble();
  }

  static double nativeTabBarExpansion(BuildContext context) {
    if (defaultTargetPlatform != TargetPlatform.iOS) return 0;

    // iOS 26's floating UITabBar has additional internal horizontal insets.
    // Older system tab bars and Flutter-drawn fallbacks do not, so expanding
    // those surfaces would make them overflow the viewport.
    return LiquidGlass.cachedCapabilities?.nativeGlass == true ? 20 : 0;
  }

  static double dockBottomInset(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final systemInset = mediaQuery.viewPadding.bottom;
    if (systemInset <= 0) return 0;

    // UIKit floating controls intentionally sit inside part of the home-
    // indicator safe area. Deriving the position from the device inset keeps
    // phones with different indicators and landscape insets aligned without
    // applying a model-specific point offset. Other platforms retain their
    // complete system-navigation inset.
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      final isLandscape = mediaQuery.orientation == Orientation.landscape;
      return systemInset * (isLandscape ? 0.25 : 1 / 3);
    }
    return systemInset;
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
    final bottom = extent > mediaQuery.padding.bottom
        ? extent
        : mediaQuery.padding.bottom;
    return MediaQuery(
      data: mediaQuery.copyWith(
        padding: mediaQuery.padding.copyWith(bottom: bottom),
        viewPadding: mediaQuery.viewPadding.copyWith(bottom: bottom),
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

/// Places a floating glass dock over full-size page content.
///
/// Keeping both layers in one stack lets native glass and Flutter fallbacks
/// sample page content instead of an intermediate Scaffold background.
class LiquidGlassDockOverlay extends StatelessWidget {
  const LiquidGlassDockOverlay({
    super.key,
    required this.child,
    required this.dock,
    required this.onExtentChanged,
  });

  final Widget child;
  final Widget dock;
  final ValueChanged<double> onExtentChanged;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        LiquidGlassDockMediaQuery(child: child),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: LiquidGlassDockExtentReporter(
            onChanged: onExtentChanged,
            child: Padding(
              padding: EdgeInsets.only(
                bottom: LiquidGlassLayout.dockBottomInset(context),
              ),
              child: dock,
            ),
          ),
        ),
      ],
    );
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
