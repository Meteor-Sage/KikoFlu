import 'package:flutter/material.dart';

/// Shared dimensions for controls and surfaces. Feature-specific layout values
/// may still differ when they are part of a deliberate dense/media layout.
abstract final class AppSpacing {
  static const double xxs = 4;
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
}

abstract final class AppRadius {
  static const double tag = 4;
  static const double control = 8;
  static const double listItem = 12;
  static const double card = 16;
  static const double capsule = 24;
}

abstract final class AppControlSize {
  static const double compact = 40;
  static const double standard = 48;
  static const double primary = 52;
}

abstract final class AppIconSize {
  static const double small = 16;
  static const double compact = 18;
  static const double standard = 20;
  static const double large = 24;
}

/// Shared settings-list geometry. The indent leaves the icon column clear for
/// nested options such as proxy modes and display sub-settings.
abstract final class AppSettingsLayout {
  static const double contentIndent = 52;
  static const double trailingGap = 12;
}

/// A small helper used by theme definitions to avoid repeating shape setup.
RoundedRectangleBorder roundedBorder(double radius, {BorderSide? side}) {
  return RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(radius),
    side: side ?? BorderSide.none,
  );
}
