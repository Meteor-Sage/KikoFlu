import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:real_liquid_glass/real_liquid_glass.dart';

void main() {
  testWidgets('legacy material scope reaches native glass parameters',
      (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);

    await tester.pumpWidget(
      const MaterialApp(
        home: LiquidGlassLegacyMaterialScope(
          enabled: true,
          child: SizedBox(
            width: 160,
            height: 64,
            child: LiquidGlassContainer(child: Text('Legacy material')),
          ),
        ),
      ),
    );

    final nativeView = tester.widget<UiKitView>(find.byType(UiKitView));
    expect(nativeView.viewType, 'real_liquid_glass/glass_view');
    expect(
      (nativeView.creationParams as Map<String, Object?>)[
          'forceLegacyMaterial'],
      isTrue,
    );
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('legacy material scope bypasses the modern iOS tab bar',
      (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);

    await tester.pumpWidget(
      MaterialApp(
        home: LiquidGlassLegacyMaterialScope(
          enabled: true,
          child: SizedBox(
            width: 320,
            height: 64,
            child: LiquidGlassBottomBar(
              items: const [
                LiquidGlassBarItem(
                  icon: Icons.home_outlined,
                  sfSymbol: 'house',
                  label: 'Home',
                ),
                LiquidGlassBarItem(
                  icon: Icons.search_outlined,
                  sfSymbol: 'magnifyingglass',
                  label: 'Search',
                ),
              ],
              currentIndex: 0,
              onTap: (_) {},
            ),
          ),
        ),
      ),
    );

    final viewTypes = tester
        .widgetList<UiKitView>(find.byType(UiKitView))
        .map((view) => view.viewType);
    expect(viewTypes, contains('real_liquid_glass/glass_view'));
    expect(viewTypes, isNot(contains('real_liquid_glass/tab_bar')));
    debugDefaultTargetPlatformOverride = null;
  });

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
