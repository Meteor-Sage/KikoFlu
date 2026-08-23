import 'package:flutter/widgets.dart';

/// Forces Apple glass widgets below this scope to use their pre-Liquid-Glass
/// system blur material. This is intended for testing legacy appearance on a
/// device whose OS would otherwise provide native Liquid Glass.
class LiquidGlassLegacyMaterialScope extends InheritedWidget {
  const LiquidGlassLegacyMaterialScope({
    super.key,
    required this.enabled,
    required super.child,
  });

  final bool enabled;

  static bool enabledOf(BuildContext context) =>
      context
          .dependOnInheritedWidgetOfExactType<LiquidGlassLegacyMaterialScope>()
          ?.enabled ??
      false;

  @override
  bool updateShouldNotify(LiquidGlassLegacyMaterialScope oldWidget) =>
      enabled != oldWidget.enabled;
}
