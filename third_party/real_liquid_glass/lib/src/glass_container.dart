import 'package:flutter/widgets.dart';

import 'capabilities.dart';
import 'fallback_glass.dart';
import 'glass_group.dart';
import 'glass_style.dart';
import 'native_glass_view.dart';

/// A container whose background is Liquid Glass.
///
/// On iOS this hosts Apple's real glass material (UIGlassEffect on
/// iOS 26+, a system blur material on older versions), so it refracts the
/// content behind it and automatically follows system appearance — the
/// iOS 27 transparency slider, Reduce Transparency, and Increase Contrast
/// all just work. Everywhere else it renders a Flutter-drawn frosted
/// fallback with the same API.
///
/// Use it like a [Container]:
///
/// ```dart
/// LiquidGlassContainer(
///   shape: const LiquidGlassShape.capsule(),
///   padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
///   child: const Text('Now playing'),
/// )
/// ```
class LiquidGlassContainer extends StatelessWidget {
  /// Creates a glass container. Provide a [child], explicit [width] and
  /// [height], or both.
  const LiquidGlassContainer({
    super.key,
    this.child,
    this.style = LiquidGlassStyle.regular,
    this.shape = const LiquidGlassShape.roundedRectangle(24),
    this.tint,
    this.interactive = false,
    this.onTap,
    this.padding,
    this.margin,
    this.alignment,
    this.width,
    this.height,
    this.fallbackIntensity = 1.0,
  });

  /// Content rendered on top of the glass.
  final Widget? child;

  /// Material variant; see [LiquidGlassStyle].
  final LiquidGlassStyle style;

  /// Outline of the surface. Defaults to a 24px continuous-corner
  /// rounded rectangle; use [LiquidGlassShape.capsule] for bars.
  final LiquidGlassShape shape;

  /// Optional tint mixed into the material (use sparingly — Apple's
  /// guidance is that glass reads best untinted).
  final Color? tint;

  /// When true, the native glass reacts to touch with Apple's shimmer /
  /// bounce (iOS 26+ only). Leave false for purely decorative surfaces so
  /// touches pass through to Flutter widgets behind the container.
  final bool interactive;

  /// Called when the surface is tapped. On iOS this is delivered by the
  /// native glass view, so Apple's interactive shimmer and the callback share
  /// the same touch. Supplying a callback automatically enables interaction.
  final VoidCallback? onTap;

  /// Inner padding around [child].
  final EdgeInsetsGeometry? padding;

  /// Outer margin around the glass surface.
  final EdgeInsetsGeometry? margin;

  /// How to align [child] within an oversized container.
  final AlignmentGeometry? alignment;

  /// Optional fixed dimensions.
  final double? width;
  final double? height;

  /// Strength of the Flutter-drawn fallback effect (0–1), the in-app
  /// analogue of the iOS 27 transparency slider. Has no effect on iOS,
  /// where the system setting governs the real material.
  final double fallbackIntensity;

  @override
  Widget build(BuildContext context) {
    final Widget surface;
    if (!LiquidGlass.isNativePlatform) {
      surface = FallbackGlass(
        style: style,
        shape: shape,
        tint: tint,
        intensity: fallbackIntensity,
      );
    } else {
      // Inside a LiquidGlassGroup the group's single native view draws all
      // shapes (so they can merge); this container only reports geometry.
      final group = GlassGroupScope.maybeOf(context);
      surface = group != null
          ? GlassRegionReporter(
              group: group,
              style: style,
              shape: shape,
              tint: tint,
            )
          : NativeGlassView(
              style: style,
              shape: shape,
              tint: tint,
              interactive: interactive || onTap != null,
              onTap: onTap,
            );
    }

    Widget? content = child;
    if (alignment != null && content != null) {
      content = Align(alignment: alignment!, child: content);
    }
    if (padding != null && content != null) {
      content = Padding(padding: padding!, child: content);
    }

    Widget result = Stack(
      children: [
        Positioned.fill(child: surface),
        ?content,
      ],
    );

    if (width != null || height != null) {
      result = SizedBox(width: width, height: height, child: result);
    }
    if (margin != null) {
      result = Padding(padding: margin!, child: result);
    }
    if (onTap != null &&
        (!LiquidGlass.isNativePlatform ||
            GlassGroupScope.maybeOf(context) != null)) {
      result = GestureDetector(onTap: onTap, child: result);
    }
    return result;
  }
}
