import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kikoeru_flutter/src/widgets/async_state_view.dart';
import 'package:kikoeru_flutter/src/widgets/search_condition_chip.dart';

void main() {
  testWidgets(
    'search condition chip keeps delete behavior and compact geometry',
    (tester) async {
      var deleted = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SearchConditionChip(
              label: 'Tag: music',
              avatar: const Icon(Icons.label, size: 16),
              backgroundColor: Colors.blue,
              onDeleted: () => deleted++,
            ),
          ),
        ),
      );

      final chip = tester.widget<Chip>(find.byType(Chip));
      expect(chip.materialTapTargetSize, MaterialTapTargetSize.shrinkWrap);
      expect(chip.visualDensity, VisualDensity.compact);
      expect(find.byIcon(Icons.close), findsOneWidget);

      await tester.tap(find.byIcon(Icons.close));
      expect(deleted, 1);
    },
  );

  testWidgets('async state view preserves content order', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AsyncStateView(
            icon: Icon(Icons.error_outline),
            title: Text('Failed'),
            message: Text('Try again'),
            action: Text('Retry'),
          ),
        ),
      ),
    );

    final texts = tester
        .widgetList<Text>(find.byType(Text))
        .map((widget) => widget.data)
        .whereType<String>()
        .toList();
    expect(texts, ['Failed', 'Try again', 'Retry']);
  });
}
