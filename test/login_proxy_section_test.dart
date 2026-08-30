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
    'login advanced settings are separate, aligned, and auto-save proxy',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(1400, 900);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
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

      expect(find.text('高级配置'), findsOneWidget);
      expect(find.text('代理'), findsNothing);
      expect(find.text('Cookie'), findsNothing);
      expect(find.byIcon(Icons.vpn_lock_outlined), findsNothing);
      expect(find.text('应用代理地址'), findsNothing);

      final titleCenter = tester.getCenter(find.text('添加账户'));
      final firstFieldCenter = tester.getCenter(
        find.byType(TextFormField).first,
      );
      expect(titleCenter.dx, closeTo(firstFieldCenter.dx, 0.01));

      expect(
        tester.getSize(find.widgetWithText(FilledButton, '登录')).height,
        52,
      );
      expect(
        tester.getSize(find.widgetWithText(OutlinedButton, '游客模式')).height,
        52,
      );

      await tester.tap(find.text('高级配置'));
      await tester.pumpAndSettle();
      expect(find.text('高级配置'), findsNWidgets(2));
      expect(find.text('Cookie'), findsOneWidget);
      await tester.tap(find.text('手动代理'));
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
      expect(container.read(proxySettingsProvider).mode.name, 'manual');
      expect(find.text('应用代理地址'), findsNothing);
      expect(find.text('Server Cookie'), findsNothing);

      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();
      expect(find.text('Cookie'), findsNothing);
    },
  );
}
