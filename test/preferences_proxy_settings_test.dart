import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kikoeru_flutter/l10n/app_localizations.dart';
import 'package:kikoeru_flutter/src/screens/preferences_screen.dart';
import 'package:kikoeru_flutter/src/providers/settings_provider.dart';
import 'package:kikoeru_flutter/src/services/proxy_config.dart';
import 'package:kikoeru_flutter/src/widgets/responsive_dialog.dart';
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
    ProxyConfig.mode = ProxyMode.system;
    ProxyConfig.address = '127.0.0.1:7890';
  });

  testWidgets('proxy settings open as one dialog with manual address field', (
    tester,
  ) async {
    await tester.pumpWidget(_testApp());
    await tester.pump();

    await tester.scrollUntilVisible(
      find.text('Proxy'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(find.text('System proxy'), findsOneWidget);
    expect(find.text('Proxy address'), findsNothing);

    await tester.tap(find.text('Proxy').first);
    await tester.pumpAndSettle();
    expect(find.byType(ResponsiveDialog), findsOneWidget);
    expect(find.text('Manual proxy'), findsOneWidget);

    await tester.tap(find.text('Manual proxy'));
    await tester.pumpAndSettle();
    expect(find.text('Proxy address'), findsOneWidget);

    await tester.tap(find.text('Direct'));
    await tester.pumpAndSettle();
    expect(find.text('Proxy address'), findsNothing);

    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();
    expect(find.byType(ResponsiveDialog), findsNothing);
  });

  testWidgets('preload custom threshold uses an inline editor', (tester) async {
    SharedPreferences.setMockInitialValues({
      'preload_next_mode': 'seconds10',
      'preload_next_custom_seconds': 45,
    });

    await tester.pumpWidget(_testApp());
    await tester.pumpAndSettle();
    final preloadTile = find.text('Preload Next Track').first;
    await tester.ensureVisible(preloadTile);
    await tester.pump();
    await tester.tap(find.text('Preload Next Track').first);
    await tester.pumpAndSettle();

    expect(find.byType(ResponsiveDialog), findsOneWidget);
    await tester.tap(find.text('Custom'));
    await tester.pumpAndSettle();
    expect(find.text('Custom Preload Threshold'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);

    await tester.enterText(find.byType(TextField), '60');
    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('preload_next_mode'), 'custom');
    expect(prefs.getInt('preload_next_custom_seconds'), 60);
  });

  testWidgets('translated lyrics auto-save switch toggles and persists', (
    tester,
  ) async {
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

  testWidgets('audio gain and haptics omit restore defaults actions', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 1600);
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

    expect(find.text('Global Audio Gain'), findsOneWidget);
    expect(find.byTooltip('Restore Default Settings'), findsNothing);
    expect(
      find.descendant(
        of: find.ancestor(
          of: find.text('Audio Haptics (Beta)'),
          matching: find.byType(ListTile),
        ),
        matching: find.byType(Switch),
      ),
      findsOneWidget,
    );
  });

  testWidgets('global audio gain updates immediately and persists', (
    tester,
  ) async {
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
    expect(prefs.getDouble(AudioGainSettingsNotifier.preferenceKey), 6);
  });

  testWidgets('audio passthrough disables global gain adjustment', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({'audio_passthrough_enabled': true});

    await tester.pumpWidget(_testApp());
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Global Audio Gain'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pump();

    expect(
      find.text('Unavailable while audio passthrough is on'),
      findsOneWidget,
    );
    expect(tester.widget<Slider>(find.byType(Slider).first).onChanged, isNull);
  });

  testWidgets('iOS exposes attenuation without unsupported positive gain', (
    tester,
  ) async {
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
      find.text('Reduce all audio; 0 dB keeps the original level'),
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
