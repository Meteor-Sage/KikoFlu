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
        LiquidGlassLayout.navigationBarHeight +
            LiquidGlassLayout.verticalPadding +
            34 -
            LiquidGlassLayout.dockSafeAreaReduction,
      );
      debugDefaultTargetPlatformOverride = null;
    },
  );

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
}
