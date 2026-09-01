import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:kikoeru_flutter/l10n/app_localizations.dart';
import 'package:kikoeru_flutter/src/models/work.dart';
import 'package:kikoeru_flutter/src/providers/work_card_display_provider.dart';
import 'package:kikoeru_flutter/src/providers/works_provider.dart';
import 'package:kikoeru_flutter/src/screens/work_card_display_settings_screen.dart';
import 'package:kikoeru_flutter/src/widgets/age_rating_chip.dart';
import 'package:kikoeru_flutter/src/widgets/enhanced_work_card.dart';
import 'package:kikoeru_flutter/src/widgets/works_grid_view.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _work = Work(
  id: 1,
  title: 'A test work with a reasonably long title',
  name: 'Circle',
);

Widget _testApp(Widget child) {
  return ProviderScope(
    child: MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: S.localizationsDelegates,
      supportedLocales: S.supportedLocales,
      home: child,
    ),
  );
}

Future<void> _pumpAsyncPreferenceLoad(WidgetTester tester) async {
  for (var i = 0; i < 5; i++) {
    await tester.pump();
  }
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets(
      'large card setting reduces grid column count without changing default',
      (tester) async {
    await tester.pumpWidget(
      _testApp(
        const MediaQuery(
          data: MediaQueryData(size: Size(400, 800)),
          child: WorksGridView(
            works: [_work],
            layoutType: LayoutType.bigGrid,
          ),
        ),
      ),
    );
    await _pumpAsyncPreferenceLoad(tester);

    expect(
      tester
          .widget<SliverMasonryGrid>(find.byType(SliverMasonryGrid))
          .gridDelegate,
      isA<SliverSimpleGridDelegateWithFixedCrossAxisCount>()
          .having((delegate) => delegate.crossAxisCount, 'crossAxisCount', 2),
    );

    final container =
        ProviderScope.containerOf(tester.element(find.byType(WorksGridView)));
    await container
        .read(workCardDisplayProvider.notifier)
        .updateCardSize(WorkCardSize.large);
    await tester.pump();

    expect(
      tester
          .widget<SliverMasonryGrid>(find.byType(SliverMasonryGrid))
          .gridDelegate,
      isA<SliverSimpleGridDelegateWithFixedCrossAxisCount>()
          .having((delegate) => delegate.crossAxisCount, 'crossAxisCount', 1),
    );
  });

  testWidgets('small grid keeps a distinct layout with extra large cards',
      (tester) async {
    await tester.pumpWidget(
      _testApp(
        const MediaQuery(
          data: MediaQueryData(size: Size(400, 800)),
          child: WorksGridView(
            works: [_work],
            layoutType: LayoutType.smallGrid,
          ),
        ),
      ),
    );
    await _pumpAsyncPreferenceLoad(tester);

    final container =
        ProviderScope.containerOf(tester.element(find.byType(WorksGridView)));
    await container
        .read(workCardDisplayProvider.notifier)
        .updateCardSize(WorkCardSize.extraLarge);
    await tester.pump();

    expect(
      tester
          .widget<SliverMasonryGrid>(find.byType(SliverMasonryGrid))
          .gridDelegate,
      isA<SliverSimpleGridDelegateWithFixedCrossAxisCount>()
          .having((delegate) => delegate.crossAxisCount, 'crossAxisCount', 2),
    );
  });

  testWidgets('uses the actual constrained width for narrow grid windows',
      (tester) async {
    final originalPhysicalSize = tester.view.physicalSize;
    final originalDevicePixelRatio = tester.view.devicePixelRatio;
    addTearDown(() {
      tester.view.physicalSize = originalPhysicalSize;
      tester.view.devicePixelRatio = originalDevicePixelRatio;
    });
    tester.view.physicalSize = const Size(300, 600);
    tester.view.devicePixelRatio = 1;

    await tester.pumpWidget(
      _testApp(
        const MediaQuery(
          data: MediaQueryData(size: Size(800, 600)),
          child: WorksGridView(
            works: [_work],
            layoutType: LayoutType.bigGrid,
          ),
        ),
      ),
    );
    await _pumpAsyncPreferenceLoad(tester);

    expect(
      tester
          .widget<SliverMasonryGrid>(find.byType(SliverMasonryGrid))
          .gridDelegate,
      isA<SliverSimpleGridDelegateWithFixedCrossAxisCount>()
          .having((delegate) => delegate.crossAxisCount, 'crossAxisCount', 1),
    );
    expect(find.byType(AspectRatio), findsOneWidget);
    expect(
      tester.widget<AspectRatio>(find.byType(AspectRatio)).aspectRatio,
      1.3,
    );
  });

  testWidgets('settings screen updates card text size segmented control',
      (tester) async {
    await tester.pumpWidget(_testApp(const WorkCardDisplaySettingsScreen()));
    await _pumpAsyncPreferenceLoad(tester);

    await tester.tap(find.text('XL').last);
    await tester.pump();

    final container = ProviderScope.containerOf(
      tester.element(find.byType(WorkCardDisplaySettingsScreen)),
    );

    expect(
      container.read(workCardDisplayProvider).fontScale,
      WorkCardFontScale.extraLarge,
    );
  });

  testWidgets('list card keeps RJ and age badges in the information area',
      (tester) async {
    SharedPreferences.setMockInitialValues({
      WorkCardDisplayNotifier.keyAgeRating: true,
    });

    const listWork = Work(
      id: 123456,
      title: 'A long work title that should stay readable in list layout',
      sourceId: 'RJ123456',
      age: 'R18',
      name: 'Circle',
      hasSubtitle: true,
    );

    await tester.pumpWidget(
      _testApp(
        const MediaQuery(
          data: MediaQueryData(size: Size(800, 600)),
          child: Scaffold(
            body: EnhancedWorkCard(
              work: listWork,
              crossAxisCount: 1,
              isListLayout: true,
            ),
          ),
        ),
      ),
    );
    await _pumpAsyncPreferenceLoad(tester);

    final coverRatio = tester.widget<AspectRatio>(find.byType(AspectRatio));
    expect(coverRatio.aspectRatio, greaterThan(1.0));
    expect(find.text('RJ123456'), findsOneWidget);
    expect(find.byType(AgeRatingChip), findsOneWidget);
    expect(find.byIcon(Icons.closed_caption), findsOneWidget);

    final coverRect = tester.getRect(find.byType(AspectRatio));
    final rjRect = tester.getRect(find.text('RJ123456'));
    final ageRect = tester.getRect(find.byType(AgeRatingChip));
    final subtitleRect = tester.getRect(find.byIcon(Icons.closed_caption));
    final circleRect = tester.getRect(find.text('Circle'));
    expect(rjRect.overlaps(ageRect), isFalse);
    expect(subtitleRect.top, lessThan(coverRect.bottom));
    expect(circleRect.top, greaterThan(coverRect.bottom));
  });

  testWidgets('card action stays out of the cover badge area', (tester) async {
    SharedPreferences.setMockInitialValues({
      WorkCardDisplayNotifier.keyAgeRating: true,
    });

    const cardWork = Work(
      id: 234567,
      title: 'Card work with a removable playlist action',
      sourceId: 'RJ234567',
      age: 'R18',
    );

    await tester.pumpWidget(
      _testApp(
        const MediaQuery(
          data: MediaQueryData(size: Size(400, 800)),
          child: Scaffold(
            body: Center(
              child: SizedBox(
                width: 180,
                child: EnhancedWorkCard(
                  work: cardWork,
                  crossAxisCount: 2,
                  trailingAction: IconButton(
                    key: ValueKey('playlist-remove-action'),
                    onPressed: null,
                    icon: Icon(Icons.remove_circle_outline),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await _pumpAsyncPreferenceLoad(tester);

    final ageRect = tester.getRect(find.byType(AgeRatingChip));
    final actionRect = tester.getRect(
      find.byKey(const ValueKey('playlist-remove-action')),
    );
    expect(ageRect.overlaps(actionRect), isFalse);
  });
}
