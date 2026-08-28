import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:real_liquid_glass/real_liquid_glass.dart';

void main() {
  testWidgets(
    'uses Flutter glass during route transitions and restores native glass',
    (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      final navigatorKey = GlobalKey<NavigatorState>();

      Widget glassPage() => const Scaffold(
        body: Center(
          child: LiquidGlassRouteTransitionFallback(
            child: SizedBox(
              width: 160,
              height: 64,
              child: LiquidGlassContainer(child: Text('Mini player')),
            ),
          ),
        ),
      );

      await tester.pumpWidget(
        MaterialApp(navigatorKey: navigatorKey, home: glassPage()),
      );
      await tester.pumpAndSettle();
      expect(find.byType(UiKitView), findsOneWidget);

      navigatorKey.currentState!.push(
        MaterialPageRoute<void>(builder: (_) => glassPage()),
      );
      await tester.pump();
      expect(find.byType(UiKitView), findsNothing);

      await tester.pumpAndSettle();
      expect(find.byType(UiKitView), findsOneWidget);
      debugDefaultTargetPlatformOverride = null;
    },
  );
}
