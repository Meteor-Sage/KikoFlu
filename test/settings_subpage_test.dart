import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kikoeru_flutter/l10n/app_localizations.dart';
import 'package:kikoeru_flutter/src/providers/player_buttons_provider.dart';
import 'package:kikoeru_flutter/src/providers/player_lyric_style_provider.dart';
import 'package:kikoeru_flutter/src/providers/settings_provider.dart';
import 'package:kikoeru_flutter/src/screens/audio_format_settings_screen.dart';
import 'package:kikoeru_flutter/src/screens/player_buttons_settings_screen.dart';
import 'package:kikoeru_flutter/src/screens/player_lyric_style_screen.dart';
import 'package:kikoeru_flutter/src/widgets/settings_section.dart';
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
    list.onReorder(0, 3);

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
    list.onReorder(0, 2);
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
    list.onReorder(0, 2);
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
}
