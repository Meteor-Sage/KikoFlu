import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:real_liquid_glass/real_liquid_glass.dart';

void main() {
  for (final platform in [TargetPlatform.iOS, TargetPlatform.macOS]) {
    testWidgets(
      'keeps native glass mounted during $platform route transitions',
      (tester) async {
        debugDefaultTargetPlatformOverride = platform;
        try {
          final nativeViewType = platform == TargetPlatform.iOS
              ? UiKitView
              : AppKitView;
          final navigatorKey = GlobalKey<NavigatorState>();

          Widget glassPage() => const Scaffold(
            body: Center(
              child: SizedBox(
                width: 160,
                height: 64,
                child: LiquidGlassContainer(child: Text('Mini player')),
              ),
            ),
          );

          await tester.pumpWidget(
            MaterialApp(navigatorKey: navigatorKey, home: glassPage()),
          );
          await tester.pumpAndSettle();
          expect(find.byType(nativeViewType), findsOneWidget);
          final originalNativeView = tester.element(find.byType(nativeViewType));

          navigatorKey.currentState!.push(
            MaterialPageRoute<void>(builder: (_) => glassPage()),
          );
          await tester.pump();
          expect(find.byType(nativeViewType), findsWidgets);
          expect(originalNativeView.mounted, isTrue);

          await tester.pumpAndSettle();
          expect(find.byType(nativeViewType), findsOneWidget);

          navigatorKey.currentState!.pop();
          await tester.pump();
          expect(find.byType(nativeViewType), findsWidgets);
          expect(originalNativeView.mounted, isTrue);
        } finally {
          debugDefaultTargetPlatformOverride = null;
        }
      },
    );
  }
}
