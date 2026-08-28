import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kikoeru_flutter/l10n/app_localizations.dart';
import 'package:kikoeru_flutter/src/providers/player_buttons_provider.dart';
import 'package:kikoeru_flutter/src/providers/player_lyric_style_provider.dart';
import 'package:kikoeru_flutter/src/providers/settings_provider.dart';
import 'package:kikoeru_flutter/src/providers/theme_provider.dart';
import 'package:kikoeru_flutter/src/screens/audio_format_settings_screen.dart';
import 'package:kikoeru_flutter/src/screens/player_buttons_settings_screen.dart';
import 'package:kikoeru_flutter/src/screens/player_lyric_style_screen.dart';
import 'package:kikoeru_flutter/src/screens/ui_settings_screen.dart';
import 'package:kikoeru_flutter/src/screens/theme_settings_screen.dart';
import 'package:kikoeru_flutter/src/widgets/settings_section.dart';
import 'package:real_liquid_glass/real_liquid_glass.dart';
import 'package:shared_preferences/shared_preferences.dart';

Widget _testApp(Widget home, {ProviderContainer? container}) {
  final app = MaterialApp(
    locale: const Locale('en'),
    localizationsDelegates: S.localizationsDelegates,
    supportedLocales: S.supportedLocales,
    home: home,
  );
  return container == null
      ? app
      : UncontrolledProviderScope(container: container, child: app);
}

Future<void> _pumpPreferences() async {
  for (var i = 0; i < 5; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('settings subpage puts restore defaults in the app bar',
      (tester) async {
    var resetCount = 0;

    await tester.pumpWidget(
      _testApp(
        SettingsSubpageScaffold(
          title: 'Display settings',
          body: const SizedBox(),
          onRestoreDefaults: () => resetCount++,
        ),
      ),
    );

    expect(find.text('Display settings'), findsOneWidget);
    expect(find.byTooltip('Restore Default Settings'), findsOneWidget);

    await tester.tap(find.byTooltip('Restore Default Settings'));
    expect(resetCount, 1);
  });

  testWidgets('reorderable settings page reports the new order immediately',
      (tester) async {
    List<String>? updatedOrder;

    await tester.pumpWidget(
      _testApp(
        SettingsReorderablePage<String>(
          title: 'Order',
          infoTitle: 'Priority',
          infoDescription: 'Drag to reorder',
          items: const ['a', 'b', 'c'],
          itemKey: (item) => item,
          itemBuilder: (context, item, index) => ListTile(title: Text(item)),
          onOrderChanged: (items) => updatedOrder = items,
          onRestoreDefaults: () {},
        ),
      ),
    );

    final list = tester.widget<ReorderableListView>(
      find.byType(ReorderableListView),
    );
    list.onReorder!(0, 3);

    expect(updatedOrder, ['b', 'c', 'a']);
    expect(find.text('Save Settings'), findsNothing);
  });

  testWidgets('player button reorder auto-saves without a save button',
      (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final provider = !Platform.isAndroid && !Platform.isIOS
        ? playerButtonsConfigDesktopProvider
        : playerButtonsConfigMobileProvider;
    final preferenceKey = !Platform.isAndroid && !Platform.isIOS
        ? 'player_buttons_config_desktop'
        : 'player_buttons_config';

    await tester.pumpWidget(
      _testApp(const PlayerButtonsSettingsScreen(), container: container),
    );
    await tester.pump();

    final initial = List<PlayerButtonType>.of(
      container.read(provider).buttonOrder,
    );
    final list = tester.widget<ReorderableListView>(
      find.byType(ReorderableListView),
    );
    list.onReorder!(0, 2);
    await tester.pump();
    await tester.runAsync(_pumpPreferences);

    final expected = List<PlayerButtonType>.of(initial);
    expected.insert(1, expected.removeAt(0));
    expect(container.read(provider).buttonOrder, expected);
    expect(find.text('Save Settings'), findsNothing);

    final prefs = await SharedPreferences.getInstance();
    expect(
      prefs.getString(preferenceKey),
      expected.map((button) => button.key).join(','),
    );
  });

  testWidgets('audio format reorder auto-saves without a save button',
      (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await tester.pumpWidget(
      _testApp(const AudioFormatSettingsScreen(), container: container),
    );
    await tester.pump();

    final initial = List<AudioFormat>.of(
      container.read(audioFormatPreferenceProvider).priority,
    );
    final list = tester.widget<ReorderableListView>(
      find.byType(ReorderableListView),
    );
    list.onReorder!(0, 2);
    await tester.pump();
    await tester.runAsync(_pumpPreferences);

    final expected = List<AudioFormat>.of(initial);
    expected.insert(1, expected.removeAt(0));
    expect(container.read(audioFormatPreferenceProvider).priority, expected);
    expect(find.text('Save Settings'), findsNothing);

    final prefs = await SharedPreferences.getInstance();
    expect(
      prefs.getStringList('audio_format_preference'),
      expected.map((format) => format.extension).toList(),
    );
  });

  testWidgets('lyric style restores defaults from the app bar', (tester) async {
    SharedPreferences.setMockInitialValues({
      'player_lyric_miniFontSize': 18.0,
    });
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await tester.pumpWidget(
      _testApp(const PlayerLyricStyleScreen(), container: container),
    );
    await tester.runAsync(_pumpPreferences);
    await tester.pump();

    final restoreButton = find.byTooltip('Restore Default Style');
    expect(restoreButton, findsOneWidget);
    expect(
      find.ancestor(of: restoreButton, matching: find.byType(AppBar)),
      findsOneWidget,
    );

    await tester.tap(restoreButton);
    await tester.pumpAndSettle();
    expect(find.text('Reset Style'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Reset'));
    await tester.pumpAndSettle();
    expect(
      container.read(playerLyricSettingsProvider).miniFontSize,
      const PlayerLyricSettings().miniFontSize,
    );
  });

  testWidgets('theme settings restores defaults from the app bar',
      (tester) async {
    LiquidGlass.debugOverrideCapabilities(LiquidGlassCapabilities.none);
    addTearDown(() => LiquidGlass.debugOverrideCapabilities(null));
    SharedPreferences.setMockInitialValues({
      'theme_mode': AppThemeMode.dark.index,
      'color_scheme_type': ColorSchemeType.dynamic.index,
      LiquidGlassNavigationNotifier.preferenceKey: true,
      FallbackGlassTransparencyNotifier.preferenceKey: 0.25,
    });
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await tester.pumpWidget(
      _testApp(const ThemeSettingsScreen(), container: container),
    );
    await tester.runAsync(_pumpPreferences);
    await tester.pump();

    await tester.tap(find.byTooltip('Restore Default Settings'));
    await tester.pumpAndSettle();
    expect(
      find.text('Are you sure you want to restore the default settings?'),
      findsOneWidget,
    );

    await tester.tap(find.widgetWithText(FilledButton, 'Confirm'));
    await tester.pumpAndSettle();
    expect(
      container.read(themeSettingsProvider).themeMode,
      AppThemeMode.system,
    );
    expect(
      container.read(themeSettingsProvider).colorSchemeType,
      ColorSchemeType.oceanBlue,
    );
    expect(container.read(liquidGlassNavigationProvider), isFalse);
    expect(
      container.read(fallbackGlassTransparencyProvider),
      FallbackGlassTransparencyNotifier.defaultValue,
    );
  });

  testWidgets('page settings group player and content options separately',
      (tester) async {
    tester.view.physicalSize = const Size(390, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final container = ProviderContainer();
    addTearDown(container.dispose);

    await tester.pumpWidget(
      _testApp(const UiSettingsScreen(), container: container),
    );
    await tester.pump();

    expect(find.byType(SettingsSectionCard), findsNWidgets(2));
    expect(find.text('Liquid Glass Navigation'), findsNothing);

    final playerCard = find.ancestor(
      of: find.text('Player Button Settings'),
      matching: find.byType(SettingsSectionCard),
    );
    final contentCard = find.ancestor(
      of: find.text('Work Detail Display Settings'),
      matching: find.byType(SettingsSectionCard),
    );
    expect(playerCard, findsOneWidget);
    expect(contentCard, findsOneWidget);
    expect(playerCard.evaluate().single, isNot(contentCard.evaluate().single));
  });

  test('immediate reorder wins over asynchronous stored preference loading',
      () async {
    SharedPreferences.setMockInitialValues({
      'player_buttons_config': 'speed,repeat,seek_backward',
      'audio_format_preference': ['wav', 'flac', 'mp3'],
    });
    final container = ProviderContainer();
    addTearDown(container.dispose);

    const buttonOrder = [
      PlayerButtonType.mark,
      PlayerButtonType.seekForward,
      PlayerButtonType.seekBackward,
    ];
    const formatOrder = [AudioFormat.opus, AudioFormat.mp3, AudioFormat.flac];
    await container
        .read(playerButtonsConfigMobileProvider.notifier)
        .updateButtonOrder(buttonOrder);
    await container
        .read(audioFormatPreferenceProvider.notifier)
        .updatePriority(formatOrder);
    await _pumpPreferences();

    expect(
      container.read(playerButtonsConfigMobileProvider).buttonOrder,
      buttonOrder,
    );
    expect(
      container.read(audioFormatPreferenceProvider).priority,
      formatOrder,
    );
  });

  test('theme and audio haptics reset to persisted defaults', () async {
    SharedPreferences.setMockInitialValues({
      'theme_mode': AppThemeMode.dark.index,
      'color_scheme_type': ColorSchemeType.dynamic.index,
      'audio_haptics_enabled': true,
      'audio_haptics_intensity': 0.4,
    });
    final container = ProviderContainer();
    addTearDown(container.dispose);

    container.read(themeSettingsProvider);
    container.read(audioHapticsSettingsProvider);
    await _pumpPreferences();

    await container.read(themeSettingsProvider.notifier).resetToDefault();
    await container
        .read(audioHapticsSettingsProvider.notifier)
        .resetToDefault();

    final theme = container.read(themeSettingsProvider);
    final haptics = container.read(audioHapticsSettingsProvider);
    expect(theme.themeMode, AppThemeMode.system);
    expect(theme.colorSchemeType, ColorSchemeType.oceanBlue);
    expect(haptics.enabled, isFalse);
    expect(haptics.intensity, AudioHapticsSettings.defaultIntensity);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getInt('theme_mode'), AppThemeMode.system.index);
    expect(
      prefs.getInt('color_scheme_type'),
      ColorSchemeType.oceanBlue.index,
    );
    expect(prefs.getBool('audio_haptics_enabled'), isFalse);
    expect(
      prefs.getDouble('audio_haptics_intensity'),
      AudioHapticsSettings.defaultIntensity,
    );
  });

  test('immediate settings reset wins over asynchronous preference loading',
      () async {
    SharedPreferences.setMockInitialValues({
      'theme_mode': AppThemeMode.dark.index,
      'color_scheme_type': ColorSchemeType.dynamic.index,
      'audio_haptics_enabled': true,
      'audio_haptics_intensity': 0.4,
    });
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await container.read(themeSettingsProvider.notifier).resetToDefault();
    await container
        .read(audioHapticsSettingsProvider.notifier)
        .resetToDefault();
    await _pumpPreferences();

    expect(
      container.read(themeSettingsProvider).themeMode,
      AppThemeMode.system,
    );
    expect(container.read(audioHapticsSettingsProvider).enabled, isFalse);
  });
}
