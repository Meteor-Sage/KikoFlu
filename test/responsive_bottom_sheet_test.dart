import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kikoeru_flutter/l10n/app_localizations.dart';
import 'package:kikoeru_flutter/src/models/work.dart';
import 'package:kikoeru_flutter/src/widgets/file_selection_dialog.dart';
import 'package:kikoeru_flutter/src/widgets/responsive_dialog.dart';
import 'package:shared_preferences/shared_preferences.dart';

Widget _testApp(Widget home) {
  return ProviderScope(
    child: MaterialApp(
      theme: ThemeData(platform: TargetPlatform.iOS),
      locale: const Locale('en'),
      localizationsDelegates: S.localizationsDelegates,
      supportedLocales: S.supportedLocales,
      home: home,
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('responsive bottom sheet is dismissible by tapping the barrier',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      _testApp(
        Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => showResponsiveBottomSheet<void>(
                context: context,
                builder: (context) => const BottomSheetMenu(
                  children: [ListTile(title: Text('Sheet action'))],
                ),
              ),
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    expect(find.text('Sheet action'), findsOneWidget);

    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();
    expect(find.text('Sheet action'), findsNothing);
  });

  testWidgets('download selector uses the shared sheet without nested dialog',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      _testApp(
        Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => showResponsiveBottomSheet<void>(
                context: context,
                builder: (context) => const FileSelectionDialog(
                  work: Work(id: 1, title: 'Download test', children: []),
                ),
              ),
              child: const Text('Download'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Download'));
    await tester.pumpAndSettle();
    expect(find.text('Select Files to Download'), findsOneWidget);
    expect(find.byType(Dialog), findsNothing);
    expect(find.byIcon(Icons.close), findsNothing);

    final cancelButton = find.widgetWithText(TextButton, 'Cancel');
    final downloadButton = find.widgetWithText(FilledButton, 'Download (0)');
    expect(cancelButton, findsOneWidget);
    expect(downloadButton, findsOneWidget);
    expect(tester.getSize(cancelButton), tester.getSize(downloadButton));
    expect(
      find.descendant(
        of: downloadButton,
        matching: find.byIcon(Icons.download),
      ),
      findsNothing,
    );

    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();
    expect(find.text('Select Files to Download'), findsNothing);
  });
}
