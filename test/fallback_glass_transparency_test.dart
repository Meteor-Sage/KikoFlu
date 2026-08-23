import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:real_liquid_glass/real_liquid_glass.dart';

void main() {
  tearDown(() => debugDefaultTargetPlatformOverride = null);

  testWidgets('fallback transparency reaches a visibly clear upper bound', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;

    Future<Color> surfaceColor(double transparency) async {
      const glassKey = ValueKey('glass');
      await tester.pumpWidget(
        MaterialApp(
          home: Center(
            child: LiquidGlassContainer(
              key: glassKey,
              width: 160,
              height: 64,
              fallbackIntensity: transparency,
            ),
          ),
        ),
      );

      final decorated = tester.widget<DecoratedBox>(
        find.descendant(
          of: find.byKey(glassKey),
          matching: find.byType(DecoratedBox),
        ),
      );
      return (decorated.decoration as BoxDecoration).color!;
    }

    expect((await surfaceColor(0)).a, 1);
    expect((await surfaceColor(0.86)).a, closeTo(0.21, 0.01));
    expect((await surfaceColor(1)).a, closeTo(0.08, 0.01));
    expect(find.byType(BackdropFilter), findsOneWidget);
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('high contrast keeps fallback glass nearly opaque', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.windows;
    const glassKey = ValueKey('glass');

    await tester.pumpWidget(
      const MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(highContrast: true),
          child: Center(
            child: LiquidGlassContainer(
              key: glassKey,
              width: 160,
              height: 64,
              fallbackIntensity: 1,
            ),
          ),
        ),
      ),
    );

    final decorated = tester.widget<DecoratedBox>(
      find.descendant(
        of: find.byKey(glassKey),
        matching: find.byType(DecoratedBox),
      ),
    );
    final color = (decorated.decoration as BoxDecoration).color!;
    expect(color.a, closeTo(0.98, 0.01));
    expect(find.byType(BackdropFilter), findsNothing);
    debugDefaultTargetPlatformOverride = null;
  });
}
