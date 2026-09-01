import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kikoeru_flutter/l10n/app_localizations.dart';
import 'package:kikoeru_flutter/src/widgets/confirmation_dialog.dart';

Widget _testApp(Widget child) {
  return MaterialApp(
    locale: const Locale('en'),
    localizationsDelegates: S.localizationsDelegates,
    supportedLocales: S.supportedLocales,
    home: Scaffold(body: child),
  );
}

void main() {
  testWidgets('danger confirmation uses the theme error color', (tester) async {
    await tester.pumpWidget(
      _testApp(
        const CommonConfirmationDialog(
          title: 'Delete item',
          content: Text('This cannot be undone.'),
          confirmLabel: 'Delete',
          variant: ConfirmationDialogVariant.danger,
        ),
      ),
    );

    final dialogContext = tester.element(find.byType(CommonConfirmationDialog));
    final expectedColor = Theme.of(dialogContext).colorScheme.error;
    final confirmButton = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Delete'),
    );

    expect(confirmButton.style?.backgroundColor?.resolve({}), expectedColor);
    expect(find.text('Cancel'), findsOneWidget);
  });
}
