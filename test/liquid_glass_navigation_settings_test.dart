import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kikoeru_flutter/src/providers/settings_provider.dart';
import 'package:real_liquid_glass/real_liquid_glass.dart';
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
    LiquidGlass.debugOverrideCapabilities(null);
  });

  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
    LiquidGlass.debugOverrideCapabilities(null);
  });

  test('defaults on only when the Apple OS supports native glass', () {
    const supported = LiquidGlassCapabilities(
      nativeGlass: true,
      reduceTransparency: false,
      osMajorVersion: 26,
    );
    const fallbackOnly = LiquidGlassCapabilities(
      nativeGlass: false,
      reduceTransparency: false,
      osMajorVersion: 18,
    );

    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    expect(
      LiquidGlassNavigationNotifier.defaultForCapabilities(supported),
      isTrue,
    );
    expect(
      LiquidGlassNavigationNotifier.defaultForCapabilities(fallbackOnly),
      isFalse,
    );

    debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
    expect(
      LiquidGlassNavigationNotifier.defaultForCapabilities(supported),
      isTrue,
    );
    expect(
      LiquidGlassNavigationNotifier.defaultForCapabilities(fallbackOnly),
      isFalse,
    );

    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    expect(
      LiquidGlassNavigationNotifier.defaultForCapabilities(supported),
      isFalse,
    );
  });

  test('saved opt-in remains enabled on a fallback-only Apple OS', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    LiquidGlass.debugOverrideCapabilities(
      const LiquidGlassCapabilities(
        nativeGlass: false,
        reduceTransparency: false,
        osMajorVersion: 18,
      ),
    );
    SharedPreferences.setMockInitialValues({
      LiquidGlassNavigationNotifier.preferenceKey: true,
    });
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(liquidGlassNavigationProvider);

    await _pumpAsyncPreferenceLoad();

    expect(container.read(liquidGlassNavigationProvider), isTrue);
  });

  test('first run adopts the preloaded native capability default', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
    LiquidGlass.debugOverrideCapabilities(
      const LiquidGlassCapabilities(
        nativeGlass: true,
        reduceTransparency: false,
        osMajorVersion: 26,
      ),
    );
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(liquidGlassNavigationProvider);

    await _pumpAsyncPreferenceLoad();

    expect(container.read(liquidGlassNavigationProvider), isTrue);
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

  test('fallback glass transparency loads, normalizes, and persists',
      () async {
    SharedPreferences.setMockInitialValues({
      FallbackGlassTransparencyNotifier.preferenceKey: 0.4,
    });
    final container = ProviderContainer();
    addTearDown(container.dispose);

    container.read(fallbackGlassTransparencyProvider);
    await _pumpAsyncPreferenceLoad();
    expect(container.read(fallbackGlassTransparencyProvider), 0.4);

    await container
        .read(fallbackGlassTransparencyProvider.notifier)
        .setTransparency(1.5);
    expect(container.read(fallbackGlassTransparencyProvider), 1.0);

    final prefs = await SharedPreferences.getInstance();
    expect(
      prefs.getDouble(FallbackGlassTransparencyNotifier.preferenceKey),
      1.0,
    );
  });

  test('fallback glass transparency preview wins over async load', () async {
    SharedPreferences.setMockInitialValues({
      FallbackGlassTransparencyNotifier.preferenceKey: 0.2,
    });
    final container = ProviderContainer();
    addTearDown(container.dispose);

    container
        .read(fallbackGlassTransparencyProvider.notifier)
        .previewTransparency(0.7);
    await _pumpAsyncPreferenceLoad();

    expect(container.read(fallbackGlassTransparencyProvider), 0.7);
  });
}
