import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:real_liquid_glass/real_liquid_glass.dart';
import 'package:kikoeru_flutter/src/widgets/main_bottom_navigation_bar.dart';
import 'package:kikoeru_flutter/src/widgets/liquid_glass_layout.dart';

void main() {
  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
    LiquidGlass.debugOverrideCapabilities(null);
  });

  testWidgets('keeps iOS home indicator safe area below navigation content', (
    tester,
  ) async {
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

  testWidgets('liquid glass navigation uses a bounded glass surface', (
    tester,
  ) async {
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
    'modern iOS glass bar compensates native inset and reports dock height',
    (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      LiquidGlass.debugOverrideCapabilities(
        const LiquidGlassCapabilities(
          nativeGlass: true,
          reduceTransparency: false,
          osMajorVersion: 26,
        ),
      );
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
          LiquidGlassLayout.iosNavigationBarHeight +
              LiquidGlassLayout.verticalPadding +
              34 / 3,
          0.01,
        ),
      );
      debugDefaultTargetPlatformOverride = null;
    },
  );

  testWidgets('legacy iOS and fallback bars align with the mini player', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    const destinations = [
      NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Home'),
      NavigationDestination(icon: Icon(Icons.search_outlined), label: 'Search'),
    ];
    const viewportKey = ValueKey('viewport');
    const miniPlayerSurfaceKey = ValueKey('mini-player-surface');

    Future<void> expectAligned({
      required TargetPlatform platform,
      required Size size,
    }) async {
      tester.view.physicalSize = size;
      debugDefaultTargetPlatformOverride = platform;
      LiquidGlass.debugOverrideCapabilities(
        const LiquidGlassCapabilities(
          nativeGlass: false,
          reduceTransparency: false,
          osMajorVersion: 18,
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(size: size),
            child: Scaffold(
              body: Align(
                alignment: Alignment.bottomCenter,
                child: SizedBox(
                  key: viewportKey,
                  width: size.width,
                  child: MainBottomNavigationBar(
                    selectedIndex: 0,
                    liquidGlass: true,
                    onDestinationSelected: (_) {},
                    destinations: destinations,
                    miniPlayer: const Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: LiquidGlassLayout.horizontalPadding,
                      ),
                      child: SizedBox(
                        key: miniPlayerSurfaceKey,
                        width: double.infinity,
                        height: 72,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      final viewportRect = tester.getRect(find.byKey(viewportKey));
      final miniPlayerRect = tester.getRect(find.byKey(miniPlayerSurfaceKey));
      final navigationRect = tester.getRect(find.byType(LiquidGlassBottomBar));
      expect(navigationRect.left, viewportRect.left + 12);
      expect(navigationRect.right, viewportRect.right - 12);
      expect(navigationRect.left, miniPlayerRect.left);
      expect(navigationRect.right, miniPlayerRect.right);
    }

    await expectAligned(
      platform: TargetPlatform.iOS,
      size: const Size(320, 568),
    );
    await expectAligned(
      platform: TargetPlatform.android,
      size: const Size(390, 844),
    );
    await expectAligned(
      platform: TargetPlatform.macOS,
      size: const Size(768, 1024),
    );
    await expectAligned(
      platform: TargetPlatform.windows,
      size: const Size(1280, 800),
    );
    await expectAligned(
      platform: TargetPlatform.linux,
      size: const Size(1024, 768),
    );
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('fallback glass bar adapts to available height and text scale', (
    tester,
  ) async {
    addTearDown(() => debugDefaultTargetPlatformOverride = null);

    Future<double> pumpHeight({
      required Size size,
      TargetPlatform platform = TargetPlatform.android,
      TextScaler textScaler = TextScaler.noScaling,
    }) async {
      debugDefaultTargetPlatformOverride = platform;
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(size: size, textScaler: textScaler),
            child: Scaffold(
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
        ),
      );
      return tester.getSize(find.byType(LiquidGlassBottomBar)).height;
    }

    final portraitHeight = await pumpHeight(size: const Size(390, 844));
    final compactLandscapeHeight = await pumpHeight(size: const Size(844, 390));
    final largeTextHeight = await pumpHeight(
      size: const Size(390, 844),
      textScaler: const TextScaler.linear(2),
    );
    final desktopHeight = await pumpHeight(
      size: const Size(1280, 800),
      platform: TargetPlatform.macOS,
    );

    expect(portraitHeight, 60);
    expect(compactLandscapeHeight, 56);
    expect(desktopHeight, 60);
    expect(largeTextHeight, greaterThan(portraitHeight));
    expect(portraitHeight, lessThan(LiquidGlassLayout.iosNavigationBarHeight));
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('dock bottom inset adapts to platform and orientation', (
    tester,
  ) async {
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

  testWidgets('dock extent becomes the safe inset for overlay controls', (
    tester,
  ) async {
    final extent = ValueNotifier<double>(120);
    addTearDown(extent.dispose);
    double? observedBottomPadding;
    double? observedBottomViewPadding;

    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(padding: EdgeInsets.only(bottom: 34)),
          child: LiquidGlassDockScope(
            notifier: extent,
            child: LiquidGlassDockMediaQuery(
              child: Builder(
                builder: (context) {
                  observedBottomPadding = MediaQuery.paddingOf(context).bottom;
                  observedBottomViewPadding = MediaQuery.viewPaddingOf(
                    context,
                  ).bottom;
                  return const SizedBox.expand();
                },
              ),
            ),
          ),
        ),
      ),
    );

    expect(observedBottomPadding, 120);
    expect(observedBottomViewPadding, 120);

    extent.value = 0;
    await tester.pump();
    expect(observedBottomPadding, 34);
    expect(observedBottomViewPadding, 34);
  });

  testWidgets('dock overlay keeps landscape page content behind the glass', (
    tester,
  ) async {
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
              child: const ColoredBox(key: contentKey, color: Colors.blue),
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

  testWidgets('nested scaffold FAB stays above the measured dock', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
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

    final fabRect = tester.getRect(find.byKey(fabKey));
    expect(fabRect.bottom, lessThanOrEqualTo(844 - 180));
    expect(844 - fabRect.bottom, greaterThanOrEqualTo(180));
  });
}
