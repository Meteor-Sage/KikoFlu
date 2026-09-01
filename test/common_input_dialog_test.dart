import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kikoeru_flutter/l10n/app_localizations.dart';
import 'package:kikoeru_flutter/src/widgets/common_input_dialog.dart';
import 'package:kikoeru_flutter/src/widgets/responsive_dialog.dart';

Widget _testApp() {
  return MaterialApp(
    locale: const Locale('en'),
    localizationsDelegates: S.localizationsDelegates,
    supportedLocales: S.supportedLocales,
    home: Builder(
      builder: (context) => Scaffold(
        body: Center(
          child: ElevatedButton(
            onPressed: () => showCommonTextInputDialog(
              context,
              title: 'Rename item',
              labelText: 'New name',
              confirmLabel: 'Save',
              initialValue: 'Original',
              validator: (value) =>
                  value.isEmpty ? 'Name cannot be empty' : null,
            ),
            child: const Text('Open input'),
          ),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('uses the shared responsive input dialog style', (tester) async {
    await tester.pumpWidget(_testApp());
    await tester.tap(find.text('Open input'));
    await tester.pumpAndSettle();

    expect(find.byType(CommonTextInputDialog), findsOneWidget);
    expect(find.byType(ResponsiveDialog), findsOneWidget);
    expect(find.text('Rename item'), findsOneWidget);
    expect(find.text('Original'), findsOneWidget);
  });

  testWidgets('shows validation errors without closing', (tester) async {
    await tester.pumpWidget(_testApp());
    await tester.tap(find.text('Open input'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), '   ');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(find.byType(CommonTextInputDialog), findsOneWidget);
    expect(find.text('Name cannot be empty'), findsOneWidget);
  });
}
