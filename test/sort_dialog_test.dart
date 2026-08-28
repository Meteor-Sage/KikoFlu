import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kikoeru_flutter/l10n/app_localizations.dart';
import 'package:kikoeru_flutter/src/models/sort_options.dart';
import 'package:kikoeru_flutter/src/widgets/responsive_dialog.dart';
import 'package:kikoeru_flutter/src/widgets/sort_dialog.dart';

Widget _testApp({
  required Size size,
  required ValueChanged<BuildContext> onContext,
}) {
  return MaterialApp(
    locale: const Locale('en'),
    localizationsDelegates: S.localizationsDelegates,
    supportedLocales: S.supportedLocales,
    home: MediaQuery(
      data: MediaQueryData(size: size),
      child: Builder(
        builder: (context) {
          onContext(context);
          return const Scaffold(body: SizedBox.expand());
        },
      ),
    ),
  );
}

void main() {
  testWidgets('uses compact left-aligned sections across sort callers', (
    tester,
  ) async {
    late BuildContext context;
    SortOrder? selectedOrder;

    await tester.pumpWidget(
      _testApp(
        size: const Size(390, 844),
        onContext: (value) => context = value,
      ),
    );

    showDialog<void>(
      context: context,
      builder: (context) => CommonSortDialog(
        title: 'Sort Options',
        currentOption: SortOrder.updatedAt,
        currentDirection: SortDirection.desc,
        availableOptions: const [
          SortOrder.updatedAt,
          SortOrder.release,
          SortOrder.review,
          SortOrder.dlCount,
        ],
        onSort: (order, direction) => selectedOrder = order,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(ResponsiveDialog), findsOneWidget);
    expect(find.byType(ResponsiveAlertDialog), findsNothing);
    expect(find.byKey(const ValueKey('sort-field-section')), findsOneWidget);
    expect(
      tester.getTopLeft(find.text('Sort Field')).dx,
      lessThan(tester.getCenter(find.byType(ResponsiveDialog)).dx),
    );

    final tiles = find.byWidgetPredicate((widget) => widget is RadioListTile);
    expect(tiles, findsNWidgets(6));
    for (final element in tiles.evaluate()) {
      expect(
        tester.getSize(find.byElementPredicate((e) => e == element)).height,
        lessThanOrEqualTo(48),
      );
    }

    await tester.tap(find.text('Reviews'));
    await tester.pumpAndSettle();

    expect(selectedOrder, SortOrder.review);
    expect(find.byType(CommonSortDialog), findsNothing);
  });

  testWidgets('keeps the compact sections side by side in landscape', (
    tester,
  ) async {
    late BuildContext context;
    SortDirection? selectedDirection;

    await tester.pumpWidget(
      _testApp(
        size: const Size(900, 500),
        onContext: (value) => context = value,
      ),
    );

    showDialog<void>(
      context: context,
      builder: (context) => CommonSortDialog(
        currentOption: SortOrder.release,
        currentDirection: SortDirection.desc,
        availableOptions: const [SortOrder.release, SortOrder.dlCount],
        autoClose: false,
        onSort: (order, direction) => selectedDirection = direction,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Sort Options'), findsOneWidget);
    final fieldLeft = tester
        .getTopLeft(find.byKey(const ValueKey('sort-field-section')))
        .dx;
    final directionLeft = tester
        .getTopLeft(find.byKey(const ValueKey('sort-direction-section')))
        .dx;
    expect(fieldLeft, lessThan(directionLeft));

    await tester.tap(find.text('Ascending'));
    await tester.pump();
    expect(selectedDirection, SortDirection.asc);
    expect(find.byType(CommonSortDialog), findsOneWidget);

    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();
    expect(find.byType(CommonSortDialog), findsNothing);
  });
}
