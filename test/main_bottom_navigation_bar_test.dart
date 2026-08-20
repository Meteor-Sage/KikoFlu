import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:real_liquid_glass/real_liquid_glass.dart';
import 'package:kikoeru_flutter/src/widgets/main_bottom_navigation_bar.dart';
import 'package:kikoeru_flutter/src/widgets/liquid_glass_layout.dart';

void main() {
  testWidgets('keeps iOS home indicator safe area below navigation content',
      (tester) async {
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(
          size: Size(390, 844),
          padding: EdgeInsets.only(bottom: 34),
        ),
        child: MaterialApp(
          home: Scaffold(
            bottomNavigationBar: MainBottomNavigationBar(
              selectedIndex: 0,
              onDestinationSelected: (_) {},
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.home_outlined),
                  label: 'Home',
                ),
                NavigationDestination(
                  icon: Icon(Icons.search_outlined),
                  label: 'Search',
                ),
              ],
            ),
          ),
        ),
      ),
    );

    expect(
      tester.getSize(find.byType(MainBottomNavigationBar)).height,
      MainBottomNavigationBar.navigationBarHeight + 34,
    );
  });

  testWidgets('liquid glass navigation uses a bounded glass surface',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          bottomNavigationBar: MainBottomNavigationBar(
            selectedIndex: 0,
            liquidGlass: true,
            onDestinationSelected: (_) {},
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.home_outlined),
                label: 'Home',
              ),
              NavigationDestination(
                icon: Icon(Icons.search_outlined),
                label: 'Search',
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.byType(LiquidGlassBottomBar), findsOneWidget);
    expect(find.byType(NavigationRail), findsNothing);
  });

  testWidgets(
    'iOS glass bar compensates native inset and reports dock height',
    (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);
      double? reportedExtent;

      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(
              size: Size(390, 844),
              padding: EdgeInsets.only(bottom: 34),
              viewPadding: EdgeInsets.only(bottom: 34),
            ),
            child: Scaffold(
              body: Align(
                alignment: Alignment.bottomCenter,
                child: SizedBox(
                  width: 390,
                  child: MainBottomNavigationBar(
                    selectedIndex: 0,
                    liquidGlass: true,
                    onLayoutExtentChanged: (extent) => reportedExtent = extent,
                    onDestinationSelected: (_) {},
                    destinations: const [
                      NavigationDestination(
                        icon: Icon(Icons.home_outlined),
                        label: 'Home',
                      ),
                      NavigationDestination(
                        icon: Icon(Icons.search_outlined),
                        label: 'Search',
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(
        tester.getSize(find.byType(LiquidGlassBottomBar)).width,
        390 - LiquidGlassLayout.horizontalPadding * 2 + 40,
      );
      expect(
        reportedExtent,
        closeTo(
          LiquidGlassLayout.navigationBarHeight +
              LiquidGlassLayout.verticalPadding +
              34 / 3,
          0.01,
        ),
      );
      debugDefaultTargetPlatformOverride = null;
    },
  );

  testWidgets('dock bottom inset adapts to platform and orientation',
      (tester) async {
    double? observedInset;

    Future<void> pumpInset({
      required TargetPlatform platform,
      required Size size,
      required double systemBottom,
    }) async {
      debugDefaultTargetPlatformOverride = platform;
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(
              size: size,
              viewPadding: EdgeInsets.only(bottom: systemBottom),
            ),
            child: Builder(
              builder: (context) {
                observedInset = LiquidGlassLayout.dockBottomInset(context);
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
      );
    }

    addTearDown(() => debugDefaultTargetPlatformOverride = null);
    await pumpInset(
      platform: TargetPlatform.iOS,
      size: const Size(390, 844),
      systemBottom: 34,
    );
    expect(observedInset, closeTo(34 / 3, 0.01));

    await pumpInset(
      platform: TargetPlatform.iOS,
      size: const Size(844, 390),
      systemBottom: 21,
    );
    expect(observedInset, closeTo(21 * 0.25, 0.01));

    await pumpInset(
      platform: TargetPlatform.android,
      size: const Size(390, 844),
      systemBottom: 24,
    );
    expect(observedInset, 24);
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('dock extent becomes the safe inset for overlay controls',
      (tester) async {
    final extent = ValueNotifier<double>(120);
    addTearDown(extent.dispose);
    double? observedBottomPadding;

    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(
            padding: EdgeInsets.only(bottom: 34),
          ),
          child: LiquidGlassDockScope(
            notifier: extent,
            child: LiquidGlassDockMediaQuery(
              child: Builder(
                builder: (context) {
                  observedBottomPadding =
                      MediaQuery.paddingOf(context).bottom;
                  return const SizedBox.expand();
                },
              ),
            ),
          ),
        ),
      ),
    );

    expect(observedBottomPadding, 120);

    extent.value = 0;
    await tester.pump();
    expect(observedBottomPadding, 34);
  });

  testWidgets('dock overlay keeps landscape page content behind the glass',
      (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);
    const contentKey = ValueKey('landscape-content');
    const dockKey = ValueKey('landscape-dock');
    double? reportedExtent;

    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(
            size: Size(800, 600),
            viewPadding: EdgeInsets.only(bottom: 20),
          ),
          child: Scaffold(
            body: LiquidGlassDockOverlay(
              onExtentChanged: (extent) => reportedExtent = extent,
              dock: const SizedBox(key: dockKey, height: 72),
              child: const ColoredBox(
                key: contentKey,
                color: Colors.blue,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    final contentRect = tester.getRect(find.byKey(contentKey));
    final dockRect = tester.getRect(find.byKey(dockKey));
    expect(contentRect.bottom, 600);
    expect(dockRect.bottom, closeTo(600 - 20 * 0.25, 0.01));
    expect(dockRect.top, lessThan(contentRect.bottom));
    expect(reportedExtent, closeTo(72 + 20 * 0.25, 0.01));
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('nested scaffold FAB stays above the measured dock',
      (tester) async {
    final extent = ValueNotifier<double>(180);
    addTearDown(extent.dispose);
    const fabKey = ValueKey('nested-fab');

    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(size: Size(390, 844)),
          child: LiquidGlassDockScope(
            notifier: extent,
            child: LiquidGlassDockMediaQuery(
              child: Scaffold(
                body: LiquidGlassDockMediaQuery(
                  child: Scaffold(
                    floatingActionButton: FloatingActionButton(
                      key: fabKey,
                      onPressed: () {},
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    expect(tester.getRect(find.byKey(fabKey)).bottom, lessThan(844 - 180));
  });
}
