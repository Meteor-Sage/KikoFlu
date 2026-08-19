import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kikoeru_flutter/src/models/audio_gain_settings.dart';
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

  test('audio gain normalizes to safe half-decibel steps', () {
    expect(AudioGainSettings.normalize(double.nan), 0);
    expect(AudioGainSettings.normalize(-30), -12);
    expect(AudioGainSettings.normalize(-2.24), -2);
    expect(AudioGainSettings.normalize(-2.26), -2.5);
    expect(AudioGainSettings.normalize(4.74), 4.5);
    expect(AudioGainSettings.normalize(4.76), 5);
    expect(AudioGainSettings.normalize(30), 12);
    expect(AudioGainSettings.linearMultiplier(0), 1);
    expect(AudioGainSettings.linearMultiplier(-6), closeTo(0.5012, 0.0001));
    expect(AudioGainSettings.linearMultiplier(6), closeTo(1.9953, 0.0001));
  });

  test('audio gain loads, persists, and resets', () async {
    SharedPreferences.setMockInitialValues({
      AudioGainSettingsNotifier.preferenceKey: 4.74,
    });
    final container = ProviderContainer();
    addTearDown(container.dispose);

    expect(container.read(audioGainSettingsProvider).decibels, 0);
    await _pumpAsyncPreferenceLoad();
    expect(container.read(audioGainSettingsProvider).decibels, 4.5);

    await container.read(audioGainSettingsProvider.notifier).setDecibels(7.3);
    expect(container.read(audioGainSettingsProvider).decibels, 7.5);

    var prefs = await SharedPreferences.getInstance();
    expect(
      prefs.getDouble(AudioGainSettingsNotifier.preferenceKey),
      7.5,
    );

    await container.read(audioGainSettingsProvider.notifier).resetToDefault();
    expect(container.read(audioGainSettingsProvider).decibels, 0);

    prefs = await SharedPreferences.getInstance();
    expect(
      prefs.getDouble(AudioGainSettingsNotifier.preferenceKey),
      0,
    );
  });

  test('immediate gain update wins over asynchronous preference loading',
      () async {
    SharedPreferences.setMockInitialValues({
      AudioGainSettingsNotifier.preferenceKey: 10,
    });
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await container.read(audioGainSettingsProvider.notifier).setDecibels(3);
    await _pumpAsyncPreferenceLoad();

    expect(container.read(audioGainSettingsProvider).decibels, 3);
  });
}
