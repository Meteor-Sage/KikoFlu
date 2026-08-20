import 'dart:ui';

/// Which Liquid Glass material variant to use.
///
/// Mirrors Apple's two glass materials introduced in iOS 26.
enum LiquidGlassStyle {
  /// Adaptive glass that keeps content behind it legible. The right choice
  /// for bars, cards, and anything containing text or controls.
  regular,

  /// Highly transparent glass for media-rich backdrops where legibility is
  /// handled by the content itself (e.g. controls over a photo or video).
  clear,
}

/// The outline of a glass surface.
///
/// Native Liquid Glass draws its refraction and edge highlights from the
/// shape itself, so the shape is part of the material — not just a clip.
class LiquidGlassShape {
  /// A pill/stadium shape — the iOS 26/27 bar silhouette.
  const LiquidGlassShape.capsule()
      : capsule = true,
        cornerRadius = 0;

  /// A continuous-corner rounded rectangle with [cornerRadius] logical
  /// pixels, matching Apple's squircle corner curve.
  const LiquidGlassShape.roundedRectangle(this.cornerRadius) : capsule = false;

  /// Whether the shape is a capsule (radius tracks the shorter side).
  final bool capsule;

  /// Corner radius in logical pixels; ignored when [capsule] is true.
  final double cornerRadius;

  /// The equivalent [BorderRadius] for Flutter-side clipping, given the
  /// current render [size].
  Radius radiusFor(Size size) => capsule
      ? Radius.circular(size.shortestSide / 2)
      : Radius.circular(cornerRadius);

  @override
  bool operator ==(Object other) =>
      other is LiquidGlassShape &&
      other.capsule == capsule &&
      other.cornerRadius == cornerRadius;

  @override
  int get hashCode => Object.hash(capsule, cornerRadius);
}
