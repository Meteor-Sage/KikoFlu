import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kikoeru_flutter/src/services/platform_appearance_service.dart';
import 'package:real_liquid_glass/real_liquid_glass.dart';

void main() {
  test('macOS system theme resolves from native effective appearance', () {
    expect(
      PlatformAppearanceService.resolveMacOSThemeMode(
        ThemeMode.system,
        Brightness.dark,
      ),
      ThemeMode.dark,
    );
    expect(
      PlatformAppearanceService.resolveMacOSThemeMode(
        ThemeMode.system,
        Brightness.light,
      ),
      ThemeMode.light,
    );
  });

  test('explicit theme mode is never replaced by system appearance', () {
    expect(
      PlatformAppearanceService.resolveMacOSThemeMode(
        ThemeMode.light,
        Brightness.dark,
      ),
      ThemeMode.light,
    );
    expect(
      PlatformAppearanceService.resolveMacOSThemeMode(
        ThemeMode.dark,
        Brightness.light,
      ),
      ThemeMode.dark,
    );
  });

  testWidgets('fallback glass follows the app theme instead of the platform', (
    tester,
  ) async {
    final originalPlatform = debugDefaultTargetPlatformOverride;
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    try {
      Future<Color> pumpAndReadSurface(ThemeMode mode) async {
        const glassKey = ValueKey('glass');
        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData.light(),
            darkTheme: ThemeData.dark(),
            themeMode: mode,
            home: const Center(
              child: LiquidGlassContainer(
                key: glassKey,
                width: 120,
                height: 48,
                fallbackIntensity: 0,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final decorated = tester.widget<DecoratedBox>(
          find.descendant(
            of: find.byKey(glassKey),
            matching: find.byType(DecoratedBox),
          ),
        );
        return (decorated.decoration as BoxDecoration).color!;
      }

      expect(await pumpAndReadSurface(ThemeMode.dark), const Color(0xFF1C1C1E));
      expect(
        await pumpAndReadSurface(ThemeMode.light),
        const Color(0xFFF2F2F7),
      );
    } finally {
      debugDefaultTargetPlatformOverride = originalPlatform;
    }
  });
}
