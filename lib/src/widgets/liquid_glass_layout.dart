/// Shared geometry for the liquid-glass navigation stack.
///
/// Keeping these values in one place ensures that the MiniPlayer and the
/// floating tab bar have identical horizontal bounds and compatible corners.
abstract final class LiquidGlassLayout {
  static const double horizontalPadding = 12;
  static const double verticalPadding = 6;
  static const double navigationBarHeight = 78;
  static const double cornerRadius = 24;
}
