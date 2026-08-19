import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kikoeru_flutter/src/providers/work_card_display_provider.dart';
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

  test('uses current card size and font scale by default', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    expect(
        container.read(workCardDisplayProvider).cardSize, WorkCardSize.normal);
    expect(container.read(workCardDisplayProvider).fontScale,
        WorkCardFontScale.normal);
    await _pumpAsyncPreferenceLoad();

    final settings = container.read(workCardDisplayProvider);
    expect(settings.applyCardSize(2), 2);
    expect(settings.scaleFontSize(12), 12);
  });

  test('loads and persists card size and font scale preferences', () async {
    SharedPreferences.setMockInitialValues({
      WorkCardDisplayNotifier.keyCardSize: WorkCardSize.large.value,
      WorkCardDisplayNotifier.keyFontScale: WorkCardFontScale.extraLarge.value,
    });
    final container = ProviderContainer();
    addTearDown(container.dispose);

    expect(
        container.read(workCardDisplayProvider).cardSize, WorkCardSize.normal);
    await _pumpAsyncPreferenceLoad();

    var settings = container.read(workCardDisplayProvider);
    expect(settings.cardSize, WorkCardSize.large);
    expect(settings.fontScale, WorkCardFontScale.extraLarge);
    expect(settings.applyCardSize(3), 2);

    await container
        .read(workCardDisplayProvider.notifier)
        .updateCardSize(WorkCardSize.extraLarge);
    await container
        .read(workCardDisplayProvider.notifier)
        .updateFontScale(WorkCardFontScale.large);

    settings = container.read(workCardDisplayProvider);
    final prefs = await SharedPreferences.getInstance();

    expect(settings.cardSize, WorkCardSize.extraLarge);
    expect(settings.fontScale, WorkCardFontScale.large);
    expect(prefs.getString(WorkCardDisplayNotifier.keyCardSize),
        WorkCardSize.extraLarge.value);
    expect(prefs.getString(WorkCardDisplayNotifier.keyFontScale),
        WorkCardFontScale.large.value);
  });

  test('card size can move back from default to large sizes repeatedly',
      () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    await _pumpAsyncPreferenceLoad();

    final notifier = container.read(workCardDisplayProvider.notifier);

    await notifier.updateCardSize(WorkCardSize.large);
    expect(
        container.read(workCardDisplayProvider).cardSize, WorkCardSize.large);
    expect(container.read(workCardDisplayProvider).applyCardSize(2), 1);

    await notifier.updateCardSize(WorkCardSize.normal);
    expect(
        container.read(workCardDisplayProvider).cardSize, WorkCardSize.normal);
    expect(container.read(workCardDisplayProvider).applyCardSize(2), 2);

    await notifier.updateCardSize(WorkCardSize.extraLarge);
    expect(container.read(workCardDisplayProvider).cardSize,
        WorkCardSize.extraLarge);
    expect(container.read(workCardDisplayProvider).applyCardSize(3), 1);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString(WorkCardDisplayNotifier.keyCardSize),
        WorkCardSize.extraLarge.value);
  });

  test('reset restores and persists all work card defaults', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    await _pumpAsyncPreferenceLoad();

    final notifier = container.read(workCardDisplayProvider.notifier);
    await notifier.toggleRating();
    await notifier.toggleDuration();
    await notifier.updateCardSize(WorkCardSize.extraLarge);
    await notifier.updateFontScale(WorkCardFontScale.large);
    await notifier.resetToDefault();

    final settings = container.read(workCardDisplayProvider);
    expect(settings.showRating, isTrue);
    expect(settings.showDuration, isFalse);
    expect(settings.cardSize, WorkCardSize.normal);
    expect(settings.fontScale, WorkCardFontScale.normal);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('work_card_display_rating'), isTrue);
    expect(prefs.getBool('work_card_display_duration'), isFalse);
    expect(
      prefs.getString(WorkCardDisplayNotifier.keyCardSize),
      WorkCardSize.normal.value,
    );
    expect(
      prefs.getString(WorkCardDisplayNotifier.keyFontScale),
      WorkCardFontScale.normal.value,
    );
  });
}
