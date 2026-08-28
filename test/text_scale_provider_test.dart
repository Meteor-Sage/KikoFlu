import 'package:flutter_test/flutter_test.dart';
import 'package:kikoeru_flutter/src/providers/text_scale_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> _flushPreferenceLoad() async {
  for (var i = 0; i < 4; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('uses normal scale by default and for unknown persisted values', () {
    expect(AppTextScale.fromValue(null), AppTextScale.normal);
    expect(AppTextScale.fromValue('future_value'), AppTextScale.normal);
    expect(AppTextScale.large.multiplier, 1.12);
    expect(AppTextScale.extraLarge.multiplier, 1.24);
  });

  test('loads and persists the selected scale', () async {
    SharedPreferences.setMockInitialValues({
      AppTextScaleNotifier.preferenceKey: AppTextScale.large.value,
    });
    final notifier = AppTextScaleNotifier();
    addTearDown(notifier.dispose);

    await _flushPreferenceLoad();
    expect(notifier.state, AppTextScale.large);

    await notifier.setScale(AppTextScale.extraLarge);
    final prefs = await SharedPreferences.getInstance();
    expect(
      prefs.getString(AppTextScaleNotifier.preferenceKey),
      AppTextScale.extraLarge.value,
    );
  });

  test('does not overwrite a local change with a pending load', () async {
    SharedPreferences.setMockInitialValues({
      AppTextScaleNotifier.preferenceKey: AppTextScale.large.value,
    });
    final notifier = AppTextScaleNotifier();
    addTearDown(notifier.dispose);

    await notifier.setScale(AppTextScale.extraLarge);
    await _flushPreferenceLoad();

    expect(notifier.state, AppTextScale.extraLarge);
  });
}
