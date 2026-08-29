import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kikoeru_flutter/l10n/app_localizations.dart';
import 'package:kikoeru_flutter/src/utils/local_file_url.dart';
import 'package:kikoeru_flutter/src/widgets/text_preview_screen.dart';

Widget _testApp(String filePath) {
  return MaterialApp(
    locale: const Locale('en'),
    localizationsDelegates: S.localizationsDelegates,
    supportedLocales: S.supportedLocales,
    home: TextPreviewScreen(
      textUrl: LocalFileUrl.fromPath(filePath),
      title: 'track01.srt',
    ),
  );
}

void main() {
  testWidgets(
    'search action precedes edit and navigates case-insensitive matches',
    (tester) async {
      final tempDir = Directory.systemTemp.createTempSync(
        'text_preview_search_',
      );
      addTearDown(() async {
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.runAsync(() async {
          for (var attempt = 0; attempt < 5; attempt++) {
            try {
              if (await tempDir.exists()) {
                await tempDir.delete(recursive: true);
              }
              return;
            } on FileSystemException {
              await Future<void>.delayed(const Duration(milliseconds: 50));
            }
          }
        });
      });

      final lines = <String>[
        'Alpha opening line',
        ...List.generate(100, (index) => 'filler subtitle line $index'),
        'middle ALPHA line',
        ...List.generate(100, (index) => 'more filler line $index'),
        'closing alpha line',
      ];
      final subtitle = File('${tempDir.path}/track01.srt');
      subtitle.writeAsStringSync(lines.join('\n'));

      await tester.pumpWidget(_testApp(subtitle.path));
      final searchAction = find.byKey(
        const ValueKey('text-preview-search-action'),
      );
      for (var attempt = 0;
          attempt < 40 && searchAction.evaluate().isEmpty;
          attempt++) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 25)),
        );
        await tester.pump();
      }

      final editAction = find.byIcon(Icons.edit);
      expect(searchAction, findsOneWidget);
      expect(editAction, findsOneWidget);
      expect(
        tester.getCenter(searchAction).dx,
        lessThan(tester.getCenter(editAction).dx),
      );

      await tester.tap(searchAction);
      await tester.pump();
      final searchField = find.byKey(
        const ValueKey('text-preview-search-field'),
      );
      expect(searchField, findsOneWidget);

      await tester.enterText(searchField, 'alpha');
      await tester.pump(const Duration(milliseconds: 250));
      expect(find.text('1/3'), findsOneWidget);

      final selectable = tester.widget<SelectableText>(
        find.byKey(const ValueKey('text-preview-content')),
      );
      final highlightedSpans = selectable.textSpan!.children!
          .whereType<TextSpan>()
          .where((span) => span.style?.backgroundColor != null);
      expect(highlightedSpans, hasLength(3));

      final scrollable = tester.widget<SingleChildScrollView>(
        find.byType(SingleChildScrollView),
      );
      expect(scrollable.controller!.position.maxScrollExtent, greaterThan(0));
      expect(scrollable.controller!.offset, 0);

      await tester.tap(find.byKey(const ValueKey('text-preview-search-next')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1));
      await tester.pump(const Duration(milliseconds: 250));
      expect(find.text('2/3'), findsOneWidget);
      expect(scrollable.controller!.offset, greaterThan(0));

      await tester.tap(
        find.byKey(const ValueKey('text-preview-search-previous')),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1));
      await tester.pump(const Duration(milliseconds: 250));
      expect(find.text('1/3'), findsOneWidget);

      await tester.enterText(searchField, 'missing');
      await tester.pump();
      expect(find.text('0/0'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('text-preview-search-close')));
      await tester.pump();
      expect(searchField, findsNothing);
    },
  );
}
