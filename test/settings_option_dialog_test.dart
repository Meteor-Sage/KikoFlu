import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kikoeru_flutter/src/widgets/radio_option_group.dart';
import 'package:kikoeru_flutter/src/widgets/responsive_dialog.dart';
import 'package:kikoeru_flutter/src/widgets/settings_option_dialog.dart';

void main() {
  testWidgets('renders compact options and closes after selection', (
    tester,
  ) async {
    late BuildContext context;
    int? selected;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (value) {
            context = value;
            return const Scaffold(body: SizedBox.expand());
          },
        ),
      ),
    );

    showDialog<void>(
      context: context,
      builder: (dialogContext) => CommonOptionDialog<int>(
        title: 'Page size',
        description: 'Choose how many items to show per page.',
        value: 20,
        options: const [
          RadioOption(
            value: 20,
            title: Text('20 items'),
            subtitle: Text('Recommended for most devices.'),
          ),
          RadioOption(value: 40, title: Text('40 items')),
          RadioOption(value: 60, title: Text('60 items')),
        ],
        onChanged: (value) {
          selected = value;
          return true;
        },
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(ResponsiveDialog), findsOneWidget);
    expect(
      find.text('Choose how many items to show per page.'),
      findsOneWidget,
    );
    expect(find.byType(RadioListTile<int>), findsNWidgets(3));
    final tiles = find.byType(RadioListTile<int>).evaluate().toList();
    expect(
      tester
          .getSize(find.byElementPredicate((value) => value == tiles.first))
          .height,
      greaterThanOrEqualTo(60),
    );
    for (final element in tiles.skip(1)) {
      expect(
        tester
            .getSize(find.byElementPredicate((value) => value == element))
            .height,
        lessThanOrEqualTo(48),
      );
    }

    await tester.tap(find.text('40 items'));
    await tester.pumpAndSettle();

    expect(selected, 40);
    expect(find.byType(CommonOptionDialog<int>), findsNothing);
  });

  testWidgets(
    'can keep the dialog open when handling an option asynchronously',
    (tester) async {
      late BuildContext context;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (value) {
              context = value;
              return const Scaffold(body: SizedBox.expand());
            },
          ),
        ),
      );

      showDialog<void>(
        context: context,
        builder: (dialogContext) => CommonOptionDialog<int>(
          title: 'Page size',
          value: 20,
          options: const [
            RadioOption(value: 20, title: Text('20 items')),
            RadioOption(value: 40, title: Text('40 items')),
          ],
          onChanged: (value) async {
            await Future<void>.value();
            return false;
          },
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('40 items'));
      await tester.pumpAndSettle();

      expect(find.byType(CommonOptionDialog<int>), findsOneWidget);
    },
  );
}
