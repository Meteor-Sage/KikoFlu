import 'dart:io';
import 'package:flutter/material.dart';
import '../providers/theme_provider.dart';
import '../providers/text_scale_provider.dart';
import 'design_tokens.dart';

class AppTheme {
  // iOS 使用 Cupertino 转场以支持侧滑返回
  static const _pageTransitionsTheme = PageTransitionsTheme();

  /// Apple 平台对应语言的原生 CJK 字体。
  ///
  /// 显式给出有限 fallback 可避免信息流滚动时反复搜索系统字体；把当前
  /// 语言的字体放在首位，则不会再把中文界面优先渲染成日文字形。
  @visibleForTesting
  static List<String> iosFontFamilyFallback(Locale locale) {
    if (locale.languageCode == 'zh') {
      final isTraditional =
          locale.scriptCode == 'Hant' ||
          locale.countryCode == 'TW' ||
          locale.countryCode == 'HK' ||
          locale.countryCode == 'MO';
      return isTraditional
          ? const ['PingFang TC', 'PingFang HK', 'Hiragino Sans']
          : const ['PingFang SC', 'PingFang TC', 'Hiragino Sans'];
    }

    return const ['Hiragino Sans', 'PingFang SC', 'PingFang TC'];
  }

  static List<String>? _platformFontFamilyFallback(Locale locale) =>
      Platform.isIOS ? iosFontFamilyFallback(locale) : null;

  // 平台字体配置
  static TextTheme? _getTextTheme() {
    if (Platform.isWindows) {
      // 使用 Microsoft YaHei 作为主字体，确保中文显示一致
      const fontFamily = 'Microsoft YaHei';
      return const TextTheme(
        displayLarge: TextStyle(
          fontFamily: fontFamily,
          fontWeight: FontWeight.w400,
        ),
        displayMedium: TextStyle(
          fontFamily: fontFamily,
          fontWeight: FontWeight.w400,
        ),
        displaySmall: TextStyle(
          fontFamily: fontFamily,
          fontWeight: FontWeight.w400,
        ),
        headlineLarge: TextStyle(
          fontFamily: fontFamily,
          fontWeight: FontWeight.w400,
        ),
        headlineMedium: TextStyle(
          fontFamily: fontFamily,
          fontWeight: FontWeight.w400,
        ),
        headlineSmall: TextStyle(
          fontFamily: fontFamily,
          fontWeight: FontWeight.w400,
        ),
        titleLarge: TextStyle(
          fontFamily: fontFamily,
          fontWeight: FontWeight.w500,
        ),
        titleMedium: TextStyle(
          fontFamily: fontFamily,
          fontWeight: FontWeight.w500,
        ),
        titleSmall: TextStyle(
          fontFamily: fontFamily,
          fontWeight: FontWeight.w500,
        ),
        bodyLarge: TextStyle(
          fontFamily: fontFamily,
          fontWeight: FontWeight.w400,
        ),
        bodyMedium: TextStyle(
          fontFamily: fontFamily,
          fontWeight: FontWeight.w400,
        ),
        bodySmall: TextStyle(
          fontFamily: fontFamily,
          fontWeight: FontWeight.w400,
        ),
        labelLarge: TextStyle(
          fontFamily: fontFamily,
          fontWeight: FontWeight.w500,
        ),
        labelMedium: TextStyle(
          fontFamily: fontFamily,
          fontWeight: FontWeight.w500,
        ),
        labelSmall: TextStyle(
          fontFamily: fontFamily,
          fontWeight: FontWeight.w500,
        ),
      );
    }
    if (Platform.isLinux) {
      // Linux 上 Flutter 默认使用 Roboto，不含 CJK 字符
      // 通过 fontFamilyFallback 回退到系统 CJK 字体
      const fallback = [
        'Noto Sans CJK SC',
        'Noto Sans CJK TC',
        'Noto Sans CJK JP',
        'Source Han Sans SC',
        'WenQuanYi Micro Hei',
        'Droid Sans Fallback',
      ];
      return const TextTheme(
        displayLarge: TextStyle(
          fontFamilyFallback: fallback,
          fontWeight: FontWeight.w400,
        ),
        displayMedium: TextStyle(
          fontFamilyFallback: fallback,
          fontWeight: FontWeight.w400,
        ),
        displaySmall: TextStyle(
          fontFamilyFallback: fallback,
          fontWeight: FontWeight.w400,
        ),
        headlineLarge: TextStyle(
          fontFamilyFallback: fallback,
          fontWeight: FontWeight.w400,
        ),
        headlineMedium: TextStyle(
          fontFamilyFallback: fallback,
          fontWeight: FontWeight.w400,
        ),
        headlineSmall: TextStyle(
          fontFamilyFallback: fallback,
          fontWeight: FontWeight.w400,
        ),
        titleLarge: TextStyle(
          fontFamilyFallback: fallback,
          fontWeight: FontWeight.w500,
        ),
        titleMedium: TextStyle(
          fontFamilyFallback: fallback,
          fontWeight: FontWeight.w500,
        ),
        titleSmall: TextStyle(
          fontFamilyFallback: fallback,
          fontWeight: FontWeight.w500,
        ),
        bodyLarge: TextStyle(
          fontFamilyFallback: fallback,
          fontWeight: FontWeight.w400,
        ),
        bodyMedium: TextStyle(
          fontFamilyFallback: fallback,
          fontWeight: FontWeight.w400,
        ),
        bodySmall: TextStyle(
          fontFamilyFallback: fallback,
          fontWeight: FontWeight.w400,
        ),
        labelLarge: TextStyle(
          fontFamilyFallback: fallback,
          fontWeight: FontWeight.w500,
        ),
        labelMedium: TextStyle(
          fontFamilyFallback: fallback,
          fontWeight: FontWeight.w500,
        ),
        labelSmall: TextStyle(
          fontFamilyFallback: fallback,
          fontWeight: FontWeight.w500,
        ),
      );
    }
    return null;
  }

  static ThemeData lightTheme(
    ColorScheme? lightDynamic, [
    ColorSchemeType? themeType,
    Locale? locale,
    AppTextScale textScale = AppTextScale.normal,
  ]) {
    final ColorScheme colorScheme;
    if (lightDynamic != null) {
      colorScheme = lightDynamic;
    } else {
      colorScheme = _getColorScheme(
        themeType ?? ColorSchemeType.oceanBlue,
        false,
      );
    }

    final textTheme = _scaledTextTheme(Brightness.light, textScale);

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      textTheme: textTheme,
      fontFamilyFallback: _platformFontFamilyFallback(
        locale ?? WidgetsBinding.instance.platformDispatcher.locale,
      ),
      pageTransitionsTheme: _pageTransitionsTheme,
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 1,
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        titleTextStyle: textTheme.titleLarge,
      ),
      cardTheme: const CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: colorScheme.surface,
        indicatorColor: colorScheme.primaryContainer,
        labelTextStyle: WidgetStateProperty.all(
          TextStyle(
            fontSize: textTheme.labelMedium?.fontSize,
            fontWeight: FontWeight.w500,
            color: colorScheme.onSurface,
          ),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadius.card),
          ),
        ),
      ),
      listTileTheme: ListTileThemeData(
        shape: roundedBorder(AppRadius.listItem),
        contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        horizontalTitleGap: AppSpacing.sm,
        minVerticalPadding: AppSpacing.xs,
      ),
      buttonTheme: ButtonThemeData(
        height: AppControlSize.standard,
        shape: roundedBorder(AppRadius.control),
      ),
      inputDecorationTheme: _inputDecorationTheme(colorScheme),
      filledButtonTheme: _filledButtonTheme(),
      outlinedButtonTheme: _outlinedButtonTheme(),
      textButtonTheme: _textButtonTheme(),
      chipTheme: _chipTheme(textTheme),
      dialogTheme: _dialogTheme(colorScheme, textTheme),
      popupMenuTheme: _popupMenuTheme(textTheme),
      snackBarTheme: _snackBarTheme(colorScheme, textTheme),
      sliderTheme: _sliderTheme(colorScheme),
      radioTheme: RadioThemeData(fillColor: _controlColor(colorScheme.primary)),
      checkboxTheme: CheckboxThemeData(
        fillColor: _controlColor(colorScheme.primary),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: _controlColor(colorScheme.primary),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        shape: roundedBorder(AppRadius.control),
      ),
    );
  }

  static ThemeData darkTheme(
    ColorScheme? darkDynamic, [
    ColorSchemeType? themeType,
    Locale? locale,
    AppTextScale textScale = AppTextScale.normal,
  ]) {
    final ColorScheme colorScheme;
    if (darkDynamic != null) {
      colorScheme = darkDynamic;
    } else {
      colorScheme = _getColorScheme(
        themeType ?? ColorSchemeType.oceanBlue,
        true,
      );
    }

    final textTheme = _scaledTextTheme(Brightness.dark, textScale);

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      textTheme: textTheme,
      fontFamilyFallback: _platformFontFamilyFallback(
        locale ?? WidgetsBinding.instance.platformDispatcher.locale,
      ),
      pageTransitionsTheme: _pageTransitionsTheme,
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 1,
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        titleTextStyle: textTheme.titleLarge,
      ),
      cardTheme: const CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: colorScheme.surface,
        indicatorColor: colorScheme.primaryContainer,
        labelTextStyle: WidgetStateProperty.all(
          TextStyle(
            fontSize: textTheme.labelMedium?.fontSize,
            fontWeight: FontWeight.w500,
            color: colorScheme.onSurface,
          ),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadius.card),
          ),
        ),
      ),
      listTileTheme: ListTileThemeData(
        shape: roundedBorder(AppRadius.listItem),
        contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        horizontalTitleGap: AppSpacing.sm,
        minVerticalPadding: AppSpacing.xs,
      ),
      buttonTheme: ButtonThemeData(
        height: AppControlSize.standard,
        shape: roundedBorder(AppRadius.control),
      ),
      inputDecorationTheme: _inputDecorationTheme(colorScheme),
      filledButtonTheme: _filledButtonTheme(),
      outlinedButtonTheme: _outlinedButtonTheme(),
      textButtonTheme: _textButtonTheme(),
      chipTheme: _chipTheme(textTheme),
      dialogTheme: _dialogTheme(colorScheme, textTheme),
      popupMenuTheme: _popupMenuTheme(textTheme),
      snackBarTheme: _snackBarTheme(colorScheme, textTheme),
      sliderTheme: _sliderTheme(colorScheme),
      radioTheme: RadioThemeData(fillColor: _controlColor(colorScheme.primary)),
      checkboxTheme: CheckboxThemeData(
        fillColor: _controlColor(colorScheme.primary),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: _controlColor(colorScheme.primary),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        shape: roundedBorder(AppRadius.control),
      ),
    );
  }

  static TextTheme _scaledTextTheme(
    Brightness brightness,
    AppTextScale textScale,
  ) {
    final platformTheme = _getTextTheme();
    final fallback = ThemeData(
      useMaterial3: true,
      brightness: brightness,
    ).textTheme;
    final semanticTheme = _ensureSemanticFontSizes(
      fallback.merge(platformTheme),
    );
    return _scaleTextTheme(semanticTheme, textScale.multiplier);
  }

  static TextTheme _ensureSemanticFontSizes(TextTheme theme) {
    TextStyle ensure(TextStyle? style, double fontSize) {
      return (style ?? const TextStyle()).copyWith(
        fontSize: style?.fontSize ?? fontSize,
      );
    }

    return theme.copyWith(
      displayLarge: ensure(theme.displayLarge, 57),
      displayMedium: ensure(theme.displayMedium, 45),
      displaySmall: ensure(theme.displaySmall, 36),
      headlineLarge: ensure(theme.headlineLarge, 32),
      headlineMedium: ensure(theme.headlineMedium, 28),
      headlineSmall: ensure(theme.headlineSmall, 24),
      titleLarge: ensure(theme.titleLarge, 18),
      titleMedium: ensure(theme.titleMedium, 16),
      titleSmall: ensure(theme.titleSmall, 14),
      bodyLarge: ensure(theme.bodyLarge, 16),
      bodyMedium: ensure(theme.bodyMedium, 14),
      bodySmall: ensure(theme.bodySmall, 12),
      labelLarge: ensure(theme.labelLarge, 14),
      labelMedium: ensure(theme.labelMedium, 12),
      labelSmall: ensure(theme.labelSmall, 11),
    );
  }

  static TextTheme _scaleTextTheme(TextTheme theme, double multiplier) {
    TextStyle? scale(TextStyle? style) {
      final fontSize = style?.fontSize;
      return fontSize == null
          ? style
          : style!.copyWith(fontSize: fontSize * multiplier);
    }

    return theme.copyWith(
      displayLarge: scale(theme.displayLarge),
      displayMedium: scale(theme.displayMedium),
      displaySmall: scale(theme.displaySmall),
      headlineLarge: scale(theme.headlineLarge),
      headlineMedium: scale(theme.headlineMedium),
      headlineSmall: scale(theme.headlineSmall),
      titleLarge: scale(theme.titleLarge),
      titleMedium: scale(theme.titleMedium),
      titleSmall: scale(theme.titleSmall),
      bodyLarge: scale(theme.bodyLarge),
      bodyMedium: scale(theme.bodyMedium),
      bodySmall: scale(theme.bodySmall),
      labelLarge: scale(theme.labelLarge),
      labelMedium: scale(theme.labelMedium),
      labelSmall: scale(theme.labelSmall),
    );
  }

  static InputDecorationTheme _inputDecorationTheme(ColorScheme colors) {
    return InputDecorationTheme(
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.sm,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.control),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.control),
        borderSide: BorderSide(color: colors.outline),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.control),
        borderSide: BorderSide(color: colors.primary, width: 2),
      ),
    );
  }

  static FilledButtonThemeData _filledButtonTheme() {
    return FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(0, AppControlSize.standard),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        shape: roundedBorder(AppRadius.control),
      ),
    );
  }

  static OutlinedButtonThemeData _outlinedButtonTheme() {
    return OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(0, AppControlSize.standard),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        shape: roundedBorder(AppRadius.control),
      ),
    );
  }

  static TextButtonThemeData _textButtonTheme() {
    return TextButtonThemeData(
      style: TextButton.styleFrom(
        minimumSize: const Size(0, AppControlSize.compact),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
        shape: roundedBorder(AppRadius.control),
      ),
    );
  }

  static ChipThemeData _chipTheme(TextTheme textTheme) {
    return ChipThemeData(
      labelStyle: textTheme.labelMedium,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xxs,
      ),
      shape: roundedBorder(AppRadius.control),
      side: BorderSide.none,
    );
  }

  static DialogThemeData _dialogTheme(ColorScheme colors, TextTheme textTheme) {
    return DialogThemeData(
      shape: roundedBorder(AppRadius.card),
      titleTextStyle: textTheme.titleLarge?.copyWith(
        color: colors.onSurface,
        fontWeight: FontWeight.w600,
      ),
      contentTextStyle: textTheme.bodyMedium?.copyWith(
        color: colors.onSurfaceVariant,
      ),
      actionsPadding: const EdgeInsets.fromLTRB(
        AppSpacing.sm,
        0,
        AppSpacing.sm,
        AppSpacing.xs,
      ),
    );
  }

  static PopupMenuThemeData _popupMenuTheme(TextTheme textTheme) {
    return PopupMenuThemeData(
      shape: roundedBorder(AppRadius.control),
      menuPadding: const EdgeInsets.symmetric(vertical: AppSpacing.xxs),
      labelTextStyle: WidgetStatePropertyAll(textTheme.bodyMedium),
    );
  }

  static SnackBarThemeData _snackBarTheme(
    ColorScheme colors,
    TextTheme textTheme,
  ) {
    return SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: roundedBorder(AppRadius.control),
      contentTextStyle: textTheme.bodyMedium?.copyWith(
        color: colors.onInverseSurface,
      ),
    );
  }

  static SliderThemeData _sliderTheme(ColorScheme colors) {
    return SliderThemeData(
      activeTrackColor: colors.primary,
      thumbColor: colors.primary,
      overlayColor: colors.primary.withValues(alpha: 0.12),
    );
  }

  static WidgetStateProperty<Color?> _controlColor(Color color) {
    return WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.disabled)) {
        return color.withValues(alpha: 0.38);
      }
      return color;
    });
  }

  // 根据主题类型获取对应的颜色方案
  static ColorScheme getColorScheme(ColorSchemeType type, bool isDark) {
    switch (type) {
      case ColorSchemeType.oceanBlue:
        return isDark ? _oceanBlueDark : _oceanBlueLight;
      case ColorSchemeType.forestGreen:
        return isDark ? _forestGreenDark : _forestGreenLight;
      case ColorSchemeType.sunsetOrange:
        return isDark ? _sunsetOrangeDark : _sunsetOrangeLight;
      case ColorSchemeType.lavenderPurple:
        return isDark ? _lavenderPurpleDark : _lavenderPurpleLight;
      case ColorSchemeType.sakuraPink:
        return isDark ? _sakuraPinkDark : _sakuraPinkLight;
      case ColorSchemeType.dynamic:
        return isDark ? _oceanBlueDark : _oceanBlueLight; // 动态主题的后备方案
    }
  }

  // 根据主题类型获取对应的颜色方案
  static ColorScheme _getColorScheme(ColorSchemeType type, bool isDark) {
    return getColorScheme(type, isDark);
  }

  // ========== 海洋蓝主题 ==========
  static const _oceanBlueLight = ColorScheme(
    brightness: Brightness.light,
    primary: Color(0xFF146683),
    onPrimary: Color(0xFFFFFFFF),
    primaryContainer: Color(0xFFBFE9FF),
    onPrimaryContainer: Color(0xFF001F2A),
    secondary: Color(0xFF4D616C),
    onSecondary: Color(0xFFFFFFFF),
    secondaryContainer: Color(0xFFD0E6F2),
    onSecondaryContainer: Color(0xFF081E27),
    tertiary: Color(0xFF5E5B7D),
    onTertiary: Color(0xFFFFFFFF),
    tertiaryContainer: Color(0xFFE4DFFF),
    onTertiaryContainer: Color(0xFF1A1836),
    error: Color(0xFFBA1A1A),
    onError: Color(0xFFFFFFFF),
    errorContainer: Color(0xFFFFDAD6),
    onErrorContainer: Color(0xFF410002),
    surface: Color(0xFFFAFCFF),
    onSurface: Color(0xFF171C1F),
    onSurfaceVariant: Color(0xFF40484C),
  );

  static const _oceanBlueDark = ColorScheme(
    brightness: Brightness.dark,
    primary: Color(0xFF8CCFF0),
    onPrimary: Color(0xFF003547),
    primaryContainer: Color(0xFF004D65),
    onPrimaryContainer: Color(0xFFBFE9FF),
    secondary: Color(0xFFB4CAD6),
    onSecondary: Color(0xFF1F333D),
    secondaryContainer: Color(0xFF364954),
    onSecondaryContainer: Color(0xFFD0E6F2),
    tertiary: Color(0xFFC7C2EA),
    onTertiary: Color(0xFF2F2D4C),
    tertiaryContainer: Color(0xFF464364),
    onTertiaryContainer: Color(0xFFE4DFFF),
    error: Color(0xFFFFB4AB),
    onError: Color(0xFF690005),
    errorContainer: Color(0xFF93000A),
    onErrorContainer: Color(0xFFFFB4AB),
    surface: Color(0xFF0F1417),
    onSurface: Color(0xFFDFE3E7),
    onSurfaceVariant: Color(0xFFC0C8CD),
  );

  // ========== 森林绿主题 ==========
  static const _forestGreenLight = ColorScheme(
    brightness: Brightness.light,
    primary: Color(0xFF3A6F41),
    onPrimary: Color(0xFFFFFFFF),
    primaryContainer: Color(0xFFBBF6BD),
    onPrimaryContainer: Color(0xFF00210A),
    secondary: Color(0xFF52634F),
    onSecondary: Color(0xFFFFFFFF),
    secondaryContainer: Color(0xFFD5E8CF),
    onSecondaryContainer: Color(0xFF101F10),
    tertiary: Color(0xFF38656A),
    onTertiary: Color(0xFFFFFFFF),
    tertiaryContainer: Color(0xFFBCEBF0),
    onTertiaryContainer: Color(0xFF002023),
    error: Color(0xFFBA1A1A),
    onError: Color(0xFFFFFFFF),
    errorContainer: Color(0xFFFFDAD6),
    onErrorContainer: Color(0xFF410002),
    surface: Color(0xFFFFFBFF),
    onSurface: Color(0xFF1A1C19),
    onSurfaceVariant: Color(0xFF424940),
  );

  static const _forestGreenDark = ColorScheme(
    brightness: Brightness.dark,
    primary: Color(0xFFA0D9A3),
    onPrimary: Color(0xFF0A3917),
    primaryContainer: Color(0xFF22522A),
    onPrimaryContainer: Color(0xFFBBF6BD),
    secondary: Color(0xFFB9CCB4),
    onSecondary: Color(0xFF243423),
    secondaryContainer: Color(0xFF3A4B38),
    onSecondaryContainer: Color(0xFFD5E8CF),
    tertiary: Color(0xFFA0CFD4),
    onTertiary: Color(0xFF00363B),
    tertiaryContainer: Color(0xFF1F4D52),
    onTertiaryContainer: Color(0xFFBCEBF0),
    error: Color(0xFFFFB4AB),
    onError: Color(0xFF690005),
    errorContainer: Color(0xFF93000A),
    onErrorContainer: Color(0xFFFFB4AB),
    surface: Color(0xFF1A1C19),
    onSurface: Color(0xFFE1E3DF),
    onSurfaceVariant: Color(0xFFC1C9BF),
  );

  // ========== 日落橙主题 ==========
  static const _sunsetOrangeLight = ColorScheme(
    brightness: Brightness.light,
    primary: Color(0xFF904D00),
    onPrimary: Color(0xFFFFFFFF),
    primaryContainer: Color(0xFFFFDCC2),
    onPrimaryContainer: Color(0xFF2E1500),
    secondary: Color(0xFF735A48),
    onSecondary: Color(0xFFFFFFFF),
    secondaryContainer: Color(0xFFFFDCC2),
    onSecondaryContainer: Color(0xFF2A150A),
    tertiary: Color(0xFF5D5F2E),
    onTertiary: Color(0xFFFFFFFF),
    tertiaryContainer: Color(0xFFE2E4A6),
    onTertiaryContainer: Color(0xFF1A1C00),
    error: Color(0xFFBA1A1A),
    onError: Color(0xFFFFFFFF),
    errorContainer: Color(0xFFFFDAD6),
    onErrorContainer: Color(0xFF410002),
    surface: Color(0xFFFFFBFF),
    onSurface: Color(0xFF201B16),
    onSurfaceVariant: Color(0xFF50453A),
  );

  static const _sunsetOrangeDark = ColorScheme(
    brightness: Brightness.dark,
    primary: Color(0xFFFFB871),
    onPrimary: Color(0xFF4D2700),
    primaryContainer: Color(0xFF6E3900),
    onPrimaryContainer: Color(0xFFFFDCC2),
    secondary: Color(0xFFE3C1A8),
    onSecondary: Color(0xFF42291C),
    secondaryContainer: Color(0xFF5A3F31),
    onSecondaryContainer: Color(0xFFFFDCC2),
    tertiary: Color(0xFFC6C88C),
    onTertiary: Color(0xFF2F3104),
    tertiaryContainer: Color(0xFF454819),
    onTertiaryContainer: Color(0xFFE2E4A6),
    error: Color(0xFFFFB4AB),
    onError: Color(0xFF690005),
    errorContainer: Color(0xFF93000A),
    onErrorContainer: Color(0xFFFFB4AB),
    surface: Color(0xFF18130E),
    onSurface: Color(0xFFEDE0D8),
    onSurfaceVariant: Color(0xFFD3C4B8),
  );

  // ========== 薰衣草紫主题 ==========
  static const _lavenderPurpleLight = ColorScheme(
    brightness: Brightness.light,
    primary: Color(0xFF6750A4),
    onPrimary: Color(0xFFFFFFFF),
    primaryContainer: Color(0xFFE9DDFF),
    onPrimaryContainer: Color(0xFF22005D),
    secondary: Color(0xFF625B71),
    onSecondary: Color(0xFFFFFFFF),
    secondaryContainer: Color(0xFFE8DEF8),
    onSecondaryContainer: Color(0xFF1E192B),
    tertiary: Color(0xFF7E5260),
    onTertiary: Color(0xFFFFFFFF),
    tertiaryContainer: Color(0xFFFFD9E3),
    onTertiaryContainer: Color(0xFF31101D),
    error: Color(0xFFBA1A1A),
    onError: Color(0xFFFFFFFF),
    errorContainer: Color(0xFFFFDAD6),
    onErrorContainer: Color(0xFF410002),
    surface: Color(0xFFFFFBFF),
    onSurface: Color(0xFF1C1B1E),
    onSurfaceVariant: Color(0xFF49454E),
  );

  static const _lavenderPurpleDark = ColorScheme(
    brightness: Brightness.dark,
    primary: Color(0xFFCFBCFF),
    onPrimary: Color(0xFF381E72),
    primaryContainer: Color(0xFF4F378A),
    onPrimaryContainer: Color(0xFFE9DDFF),
    secondary: Color(0xFFCCC2DC),
    onSecondary: Color(0xFF332D41),
    secondaryContainer: Color(0xFF4A4458),
    onSecondaryContainer: Color(0xFFE8DEF8),
    tertiary: Color(0xFFEFB8C8),
    onTertiary: Color(0xFF4A2532),
    tertiaryContainer: Color(0xFF633B48),
    onTertiaryContainer: Color(0xFFFFD9E3),
    error: Color(0xFFFFB4AB),
    onError: Color(0xFF690005),
    errorContainer: Color(0xFF93000A),
    onErrorContainer: Color(0xFFFFB4AB),
    surface: Color(0xFF141218),
    onSurface: Color(0xFFE6E1E6),
    onSurfaceVariant: Color(0xFFCAC4CF),
  );

  // ========== 樱花粉主题 ==========
  static const _sakuraPinkLight = ColorScheme(
    brightness: Brightness.light,
    primary: Color(0xFFB4276E),
    onPrimary: Color(0xFFFFFFFF),
    primaryContainer: Color(0xFFFFD8E8),
    onPrimaryContainer: Color(0xFF3E0025),
    secondary: Color(0xFF73565E),
    onSecondary: Color(0xFFFFFFFF),
    secondaryContainer: Color(0xFFFFD8E1),
    onSecondaryContainer: Color(0xFF2A151C),
    tertiary: Color(0xFF7C5635),
    onTertiary: Color(0xFFFFFFFF),
    tertiaryContainer: Color(0xFFFFDCC1),
    onTertiaryContainer: Color(0xFF2E1500),
    error: Color(0xFFBA1A1A),
    onError: Color(0xFFFFFFFF),
    errorContainer: Color(0xFFFFDAD6),
    onErrorContainer: Color(0xFF410002),
    surface: Color(0xFFFFFBFF),
    onSurface: Color(0xFF201A1B),
    onSurfaceVariant: Color(0xFF514347),
  );

  static const _sakuraPinkDark = ColorScheme(
    brightness: Brightness.dark,
    primary: Color(0xFFFFB0CB),
    onPrimary: Color(0xFF64003E),
    primaryContainer: Color(0xFF8E0056),
    onPrimaryContainer: Color(0xFFFFD8E8),
    secondary: Color(0xFFE3BDC6),
    onSecondary: Color(0xFF422930),
    secondaryContainer: Color(0xFF5A3F47),
    onSecondaryContainer: Color(0xFFFFD8E1),
    tertiary: Color(0xFFEDBD94),
    onTertiary: Color(0xFF48290C),
    tertiaryContainer: Color(0xFF623F20),
    onTertiaryContainer: Color(0xFFFFDCC1),
    error: Color(0xFFFFB4AB),
    onError: Color(0xFF690005),
    errorContainer: Color(0xFF93000A),
    onErrorContainer: Color(0xFFFFB4AB),
    surface: Color(0xFF1A1A1A),
    onSurface: Color(0xFFEBE0E1),
    onSurfaceVariant: Color(0xFFD5C2C6),
  );
}
