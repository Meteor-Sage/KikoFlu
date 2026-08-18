import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kikoeru_flutter/l10n/app_localizations.dart';
import 'package:kikoeru_flutter/src/screens/preferences_screen.dart';
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
}
