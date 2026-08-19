import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:real_liquid_glass/real_liquid_glass.dart';
import 'package:kikoeru_flutter/src/widgets/main_bottom_navigation_bar.dart';

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
}
