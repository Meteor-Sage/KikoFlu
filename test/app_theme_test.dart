import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kikoeru_flutter/src/providers/text_scale_provider.dart';
import 'package:kikoeru_flutter/src/providers/theme_provider.dart';
import 'package:kikoeru_flutter/src/utils/design_tokens.dart';
import 'package:kikoeru_flutter/src/utils/theme.dart';

void main() {
  test('app text presets scale semantic TextTheme roles', () {
    final normal = AppTheme.lightTheme(
      null,
      ColorSchemeType.oceanBlue,
      const Locale('en'),
      AppTextScale.normal,
    );
    final large = AppTheme.lightTheme(
      null,
      ColorSchemeType.oceanBlue,
      const Locale('en'),
      AppTextScale.large,
    );

    final normalSize = normal.textTheme.bodyMedium!.fontSize!;
    final largeSize = large.textTheme.bodyMedium!.fontSize!;
    expect(largeSize, closeTo(normalSize * 1.12, 0.001));
  });

  test('shared component themes use design-system dimensions', () {
    final theme = AppTheme.darkTheme(
      null,
      ColorSchemeType.oceanBlue,
      const Locale('en'),
    );

    final filledStyle = theme.filledButtonTheme.style!;
    expect(
      filledStyle.minimumSize!.resolve(<WidgetState>{}),
      const Size(0, AppControlSize.standard),
    );
    expect(theme.inputDecorationTheme.border, isA<OutlineInputBorder>());
    expect(theme.dialogTheme.shape, isA<RoundedRectangleBorder>());
    expect(theme.popupMenuTheme.shape, isA<RoundedRectangleBorder>());
    expect(theme.snackBarTheme.behavior, SnackBarBehavior.floating);
  });
}
