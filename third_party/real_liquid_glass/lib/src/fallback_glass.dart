import 'dart:ui';

import 'package:flutter/widgets.dart';

import 'glass_style.dart';

/// Flutter-drawn frosted-glass surface used where native Liquid Glass is
/// unavailable (Android, web, desktop).
///
/// Approximates the iOS material: background blur, a translucent fill
/// derived from the ambient brightness, and a hairline edge highlight.
/// Honors the platform high-contrast accessibility setting by rendering
/// (nearly) opaque.
class FallbackGlass extends StatelessWidget {
  const FallbackGlass({
    super.key,
    required this.style,
    required this.shape,
    this.tint,
    this.intensity = 1.0,
  });

  final LiquidGlassStyle style;
  final LiquidGlassShape shape;
  final Color? tint;

  /// 0–1 dial for how pronounced the effect is: scales blur and lowers
  /// fill opacity. 1 is the full effect; 0 is a plain translucent panel.
  /// The Flutter analogue of the iOS 27 transparency slider.
  final double intensity;

  // The fallback material is defined in absolute translucencies rather
  // than theme colors so it works identically under CupertinoApp and
  // MaterialApp.
  static const Color _fillLight = Color(0xFFF2F2F7);
  static const Color _fillDark = Color(0xFF1C1C1E);
  static const Color _edgeLight = Color(0x66FFFFFF);
  static const Color _edgeDark = Color(0x33FFFFFF);

  @override
  Widget build(BuildContext context) {
    final dark =
        MediaQuery.platformBrightnessOf(context) == Brightness.dark;
    final highContrast = MediaQuery.highContrastOf(context);
    final clamped = intensity.clamp(0.0, 1.0);

    final base = tint ?? (dark ? _fillDark : _fillLight);
    final maxTranslucency = style == LiquidGlassStyle.clear ? 0.85 : 0.55;
    // High contrast (or intensity 0) collapses toward an opaque panel.
    final fillAlpha = highContrast
        ? 0.98
        : 1.0 - maxTranslucency * clamped;
    final sigma =
        (style == LiquidGlassStyle.clear ? 12.0 : 24.0) * clamped;

    return LayoutBuilder(
      builder: (context, constraints) {
        final radius = BorderRadius.all(
          shape.radiusFor(constraints.biggest),
        );
        Widget surface = DecoratedBox(
          decoration: BoxDecoration(
            color: base.withValues(alpha: fillAlpha),
            borderRadius: radius,
            border: Border.all(
              color: dark ? _edgeDark : _edgeLight,
              width: 0.8,
            ),
          ),
        );
        if (!highContrast && sigma > 0) {
          surface = ClipRRect(
            borderRadius: radius,
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
              child: surface,
            ),
          );
        }
        return surface;
      },
    );
  }
}
