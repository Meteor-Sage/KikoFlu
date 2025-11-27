import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/settings_provider.dart';

/// Wraps any cover image with a gaussian blur when privacy mode requires it.
class PrivacyBlurCover extends ConsumerWidget {
  final Widget child;
  final BorderRadius? borderRadius;
  final double sigma;
  final bool enabled;

  const PrivacyBlurCover({
    super.key,
    required this.child,
    this.borderRadius,
    this.sigma = 27,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(privacyModeSettingsProvider);
    final shouldBlur =
        enabled && settings.enabled && settings.blurCoverInApp;

    if (!shouldBlur) {
      return child;
    }

    Widget blurred = ClipRect(
      child: ImageFiltered(
        imageFilter: ui.ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
        child: child,
      ),
    );

    blurred = Stack(
      fit: StackFit.passthrough,
      children: [
        blurred,
        Positioned.fill(
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.12),
              ),
            ),
          ),
        ),
      ],
    );

    if (borderRadius != null) {
      return ClipRRect(
        borderRadius: borderRadius!,
        child: blurred,
      );
    }

    return blurred;
  }
}
