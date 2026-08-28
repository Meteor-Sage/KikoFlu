import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kikoeru_flutter/l10n/app_localizations.dart';
import 'package:kikoeru_flutter/src/widgets/work_detail/work_cover_frame.dart';

Widget _testApp(Widget child) {
  return ProviderScope(
    child: MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: S.localizationsDelegates,
      supportedLocales: S.supportedLocales,
      home: Scaffold(body: child),
    ),
  );
}

void main() {
  testWidgets('renders cover layers inside a hero frame', (tester) async {
    await tester.pumpWidget(
      _testApp(
        const WorkCoverFrame(
          heroTag: 'cover-1',
          isLandscape: false,
          layers: [
            Center(child: Text('Cover Layer')),
          ],
        ),
      ),
    );

    expect(find.byType(Hero), findsOneWidget);
    expect(find.text('Cover Layer'), findsOneWidget);
    expect(find.text('Subtitle'), findsNothing);
  });

  testWidgets('uses the source cover for the Hero flight', (tester) async {
    await tester.pumpWidget(
      _testApp(
        const WorkCoverFrame(
          heroTag: 'cover-flight',
          isLandscape: false,
          layers: [Center(child: Text('Cover Layer'))],
        ),
      ),
    );

    final hero = tester.widget<Hero>(find.byType(Hero));
    final heroContext = tester.element(find.byType(Hero));
    final shuttle = hero.flightShuttleBuilder!(
      heroContext,
      const AlwaysStoppedAnimation<double>(0),
      HeroFlightDirection.push,
      heroContext,
      heroContext,
    );

    expect(identical(shuttle, hero.child), isTrue);
  });

  testWidgets('shows subtitle and age badges and handles tap', (tester) async {
    var tapCount = 0;

    await tester.pumpWidget(
      _testApp(
        WorkCoverFrame(
          heroTag: 'cover-2',
          isLandscape: true,
          showSubtitleBadge: true,
          showAgeRating: true,
          age: 'R18',
          onTap: () => tapCount++,
          layers: const [
            Center(child: Text('Cover Layer')),
          ],
        ),
      ),
    );

    expect(find.text('Subtitle'), findsOneWidget);
    expect(find.byKey(const ValueKey('work-cover-age-badge')), findsOneWidget);

    final ageBadge = tester.getRect(
      find.byKey(const ValueKey('work-cover-age-badge')),
    );
    final subtitleBadge = tester.getRect(
      find.byKey(const ValueKey('work-cover-subtitle-badge')),
    );
    expect(ageBadge.bottom, subtitleBadge.bottom);
    expect(ageBadge.left, lessThan(subtitleBadge.left));

    await tester.tap(find.text('Cover Layer'));

    expect(tapCount, 1);
  });
}
