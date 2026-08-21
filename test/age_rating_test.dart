import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kikoeru_flutter/l10n/app_localizations.dart';
import 'package:kikoeru_flutter/src/models/work.dart';
import 'package:kikoeru_flutter/src/utils/age_rating.dart';
import 'package:kikoeru_flutter/src/widgets/age_rating_chip.dart';

Widget _testApp(Widget child) {
  return MaterialApp(
    locale: const Locale('en'),
    localizationsDelegates: S.localizationsDelegates,
    supportedLocales: S.supportedLocales,
    home: child,
  );
}

void main() {
  test('maps Kikoeru age_category_string into Work.age', () {
    final work = Work.fromJson(const <String, dynamic>{
      'id': 1,
      'title': 'Test work',
      'age_category_string': 'adult',
    });

    expect(work.age, 'adult');
  });

  test('keeps an explicit age value for custom servers', () {
    final work = Work.fromJson(const <String, dynamic>{
      'id': 1,
      'title': 'Test work',
      'age': 'R15',
      'age_category_string': 'adult',
    });

    expect(work.age, 'R15');
  });

  test('normalizes known server age categories', () {
    expect(AgeRatingFormatter.level('adult'), AgeRatingLevel.r18);
    expect(AgeRatingFormatter.level('R-15'), AgeRatingLevel.r15);
    expect(AgeRatingFormatter.level('general'), AgeRatingLevel.general);
    expect(AgeRatingFormatter.level('custom'), AgeRatingLevel.unknown);
    expect(AgeRatingFormatter.hasValue('  '), isFalse);
  });

  testWidgets('renders adult as the R18 chip label', (tester) async {
    await tester.pumpWidget(_testApp(const AgeRatingChip(age: 'adult')));

    expect(find.text('R18'), findsOneWidget);
  });
}
