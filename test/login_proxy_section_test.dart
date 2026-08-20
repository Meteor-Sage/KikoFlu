import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kikoeru_flutter/l10n/app_localizations.dart';
import 'package:kikoeru_flutter/src/providers/proxy_provider.dart';
import 'package:kikoeru_flutter/src/screens/login_screen.dart';
import 'package:kikoeru_flutter/src/services/proxy_config.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets(
    'login proxy section is compact and saves on editing completion',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      ProxyConfig.enabled = false;
      ProxyConfig.address = '';
      final container = ProviderContainer();
      addTearDown(() {
        container.dispose();
        ProxyConfig.enabled = false;
        ProxyConfig.address = '';
      });

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            locale: Locale('zh'),
            localizationsDelegates: S.localizationsDelegates,
            supportedLocales: S.supportedLocales,
            home: LoginScreen(isAddingAccount: true),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('代理'), findsOneWidget);
      expect(find.byIcon(Icons.vpn_lock_outlined), findsNothing);
      expect(find.text('应用代理地址'), findsNothing);

      await tester.ensureVisible(find.text('代理'));
      await tester.tap(find.text('代理'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(SwitchListTile, '使用代理'));
      await tester.pumpAndSettle();

      final proxyField = find.byWidgetPredicate(
        (widget) =>
            widget is TextField && widget.decoration?.labelText == '代理地址',
      );
      expect(proxyField, findsOneWidget);
      await tester.enterText(proxyField, 'http://127.0.0.1:7890');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      expect(container.read(proxySettingsProvider).address, '127.0.0.1:7890');
      expect(find.text('应用代理地址'), findsNothing);

      await tester.ensureVisible(find.text('Cookie'));
      await tester.tap(find.text('Cookie'));
      await tester.pumpAndSettle();
      expect(find.text('Server Cookie'), findsNothing);
    },
  );
}
