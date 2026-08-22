import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kikoeru_flutter/l10n/app_localizations.dart';
import 'package:kikoeru_flutter/src/screens/preferences_screen.dart';
import 'package:kikoeru_flutter/src/providers/settings_provider.dart';
import 'package:kikoeru_flutter/src/services/proxy_config.dart';
import 'package:shared_preferences/shared_preferences.dart';

Widget _testApp({TargetPlatform platform = TargetPlatform.android}) {
  return ProviderScope(
    child: MaterialApp(
      locale: const Locale('en'),
      theme: ThemeData(platform: platform),
      localizationsDelegates: S.localizationsDelegates,
      supportedLocales: S.supportedLocales,
      home: const PreferencesScreen(),
    ),
  );
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    ProxyConfig.enabled = false;
    ProxyConfig.address = '127.0.0.1:7890';
  });

  testWidgets('proxy address is only shown while proxy is enabled',
      (tester) async {
    await tester.pumpWidget(_testApp());
    await tester.pump();

    final proxySwitch = find.widgetWithText(SwitchListTile, 'Use proxy');
    await tester.ensureVisible(proxySwitch);
    await tester.pumpAndSettle();
    expect(find.text('Proxy address'), findsNothing);

    await tester.tap(proxySwitch);
    await tester.pump();
    expect(find.text('Proxy address'), findsOneWidget);

    await tester.tap(proxySwitch);
    await tester.pump();
    expect(find.text('Proxy address'), findsNothing);
  });

  testWidgets('translated lyrics auto-save switch toggles and persists',
      (tester) async {
    await tester.pumpWidget(_testApp());
    await tester.pump();

    final tile = find.widgetWithText(
      SwitchListTile,
      'Automatically save translated lyrics',
    );
    await tester.ensureVisible(tile);
    await tester.pump();

    expect(tester.widget<SwitchListTile>(tile).value, isTrue);
    await tester.tap(tile);
    await tester.pump();

    expect(tester.widget<SwitchListTile>(tile).value, isFalse);
    final prefs = await SharedPreferences.getInstance();
    expect(
      prefs.getBool(AutoSaveTranslatedLyricsNotifier.preferenceKey),
      isFalse,
    );
  });

  testWidgets('audio haptics exposes a working restore defaults action',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({
      'audio_haptics_enabled': true,
      'audio_haptics_intensity': 0.4,
    });

    await tester.pumpWidget(_testApp());
    await tester.pump();
    await tester.scrollUntilVisible(
      find.text('Audio Haptics (Beta)'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pump();

    final hapticsTile = find.ancestor(
      of: find.text('Audio Haptics (Beta)'),
      matching: find.byType(ListTile),
    );
    final resetButton = find.descendant(
      of: hapticsTile,
      matching: find.byTooltip('Restore Default Settings'),
    );
    await tester.tap(resetButton);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Confirm'));
    await tester.pumpAndSettle();

    final container = ProviderScope.containerOf(
      tester.element(find.byType(PreferencesScreen)),
    );
    final settings = container.read(audioHapticsSettingsProvider);
    expect(settings.enabled, isFalse);
    expect(settings.intensity, AudioHapticsSettings.defaultIntensity);
  });

  testWidgets('global audio gain updates immediately and persists',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_testApp());
    await tester.pump();
    await tester.scrollUntilVisible(
      find.text('Global Audio Gain'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pump();

    final gainSlider = tester.widget<Slider>(find.byType(Slider).first);
    gainSlider.onChanged!(6);
    await tester.pump();

    final container = ProviderScope.containerOf(
      tester.element(find.byType(PreferencesScreen)),
    );
    expect(container.read(audioGainSettingsProvider).decibels, 6);
    expect(find.text('+6 dB'), findsOneWidget);

    final prefs = await SharedPreferences.getInstance();
    expect(
      prefs.getDouble(AudioGainSettingsNotifier.preferenceKey),
      6,
    );
  });

  testWidgets('audio passthrough disables global gain adjustment',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({
      'audio_passthrough_enabled': true,
    });

    await tester.pumpWidget(_testApp());
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Global Audio Gain'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pump();

    expect(
      find.text('Unavailable while audio passthrough is enabled.'),
      findsOneWidget,
    );
    expect(tester.widget<Slider>(find.byType(Slider).first).onChanged, isNull);
  });

  testWidgets('iOS exposes attenuation without unsupported positive gain',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_testApp(platform: TargetPlatform.iOS));
    await tester.pump();
    await tester.scrollUntilVisible(
      find.text('Global Audio Gain'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pump();

    expect(
      find.text(
          'Reduce all audio globally. 0 dB preserves the original sound.'),
      findsOneWidget,
    );
    final gainSlider = tester.widget<Slider>(find.byType(Slider).first);
    expect(gainSlider.min, -12);
    expect(gainSlider.max, 0);

    gainSlider.onChanged!(-6);
    await tester.pump();
    expect(find.text('-6 dB'), findsOneWidget);
  });
}
