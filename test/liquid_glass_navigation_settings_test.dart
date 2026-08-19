import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kikoeru_flutter/src/providers/settings_provider.dart';
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

  test('liquid glass navigation loads and persists the selected value',
      () async {
    SharedPreferences.setMockInitialValues({
      LiquidGlassNavigationNotifier.preferenceKey: false,
    });
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await _pumpAsyncPreferenceLoad();
    expect(container.read(liquidGlassNavigationProvider), isFalse);

    await container
        .read(liquidGlassNavigationProvider.notifier)
        .setEnabled(true);
    expect(container.read(liquidGlassNavigationProvider), isTrue);

    final prefs = await SharedPreferences.getInstance();
    expect(
      prefs.getBool(LiquidGlassNavigationNotifier.preferenceKey),
      isTrue,
    );
  });

  test('immediate navigation style change wins over async load', () async {
    SharedPreferences.setMockInitialValues({
      LiquidGlassNavigationNotifier.preferenceKey: false,
    });
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await container
        .read(liquidGlassNavigationProvider.notifier)
        .setEnabled(true);
    await _pumpAsyncPreferenceLoad();

    expect(container.read(liquidGlassNavigationProvider), isTrue);
  });
}
