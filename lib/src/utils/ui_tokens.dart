import 'package:flutter/material.dart';

/// Geometry shared by ordinary application surfaces.
///
/// These values mirror the current UI. Keeping them in one place makes later
/// spacing adjustments local without changing colors, materials, or platform
/// specific surfaces.
abstract final class UiSpacing {
  static const double xSmall = 4;
  static const double small = 8;
  static const double medium = 12;
  static const double large = 16;
  static const double xLarge = 24;
}

abstract final class UiRadii {
  static const double tag = 4;
  static const double control = 8;
  static const double list = 12;
  static const double card = 16;
  static const double capsule = 20;
}

abstract final class UiControlSize {
  static const double compact = 40;
  static const double standard = 48;
  static const double settingsLeading = 52;
  static const double iconButton = 40;
}

abstract final class UiIconSize {
  static const double small = 16;
  static const double standard = 20;
  static const double large = 24;
}

/// Text roles for ordinary controls. Colors and font families remain inherited
/// from the surrounding theme, so using these does not alter material styling.
abstract final class UiTextStyles {
  static const TextStyle pageTitle = TextStyle(fontSize: 18);
  static const TextStyle supporting = TextStyle(fontSize: 12, height: 1.5);
  static const TextStyle filterChipLabel = TextStyle(fontSize: 12);
}
