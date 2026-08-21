import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kikoeru_flutter/src/providers/work_detail_display_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> _pumpAsyncPreferenceLoad() async {
  for (var i = 0; i < 5; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('age rating is disabled by default and persists when toggled', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    expect(
      container.read(workDetailDisplayProvider).showAgeRating,
      isFalse,
    );
    await _pumpAsyncPreferenceLoad();

    final notifier = container.read(workDetailDisplayProvider.notifier);
    await notifier.toggleAgeRating();

    expect(container.read(workDetailDisplayProvider).showAgeRating, isTrue);
    final prefs = await SharedPreferences.getInstance();
    expect(
      prefs.getBool(WorkDetailDisplayNotifier.keyAgeRating),
      isTrue,
    );

    await notifier.resetToDefault();
    expect(container.read(workDetailDisplayProvider).showAgeRating, isFalse);
  });
}
