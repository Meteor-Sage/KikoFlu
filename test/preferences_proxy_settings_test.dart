import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kikoeru_flutter/l10n/app_localizations.dart';
import 'package:kikoeru_flutter/src/screens/preferences_screen.dart';
import 'package:kikoeru_flutter/src/providers/settings_provider.dart';
import 'package:kikoeru_flutter/src/services/proxy_config.dart';
import 'package:shared_preferences/shared_preferences.dart';

Widget _testApp() {
  return const ProviderScope(
    child: MaterialApp(
      locale: Locale('en'),
      localizationsDelegates: S.localizationsDelegates,
      supportedLocales: S.supportedLocales,
      home: PreferencesScreen(),
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
    expect(find.text('Proxy address'), findsNothing);

    await tester.tap(proxySwitch);
    await tester.pump();
    expect(find.text('Proxy address'), findsOneWidget);

    await tester.tap(proxySwitch);
    await tester.pump();
    expect(find.text('Proxy address'), findsNothing);
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

    await tester.tap(find.byTooltip('Restore Default Settings'));
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
}
