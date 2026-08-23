import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kikoeru_flutter/l10n/app_localizations.dart';
import 'package:kikoeru_flutter/src/providers/settings_provider.dart';
import 'package:kikoeru_flutter/src/screens/ui_settings_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

Widget _testApp(
  ProviderContainer container, {
  TextScaler textScaler = TextScaler.noScaling,
}) {
  return UncontrolledProviderScope(
    container: container,
    child: MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: S.localizationsDelegates,
      supportedLocales: S.supportedLocales,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(textScaler: textScaler),
        child: child!,
      ),
      home: const UiSettingsScreen(),
    ),
  );
}

Future<ProviderContainer> _enabledContainer() async {
  final container = ProviderContainer();
  await container
      .read(liquidGlassNavigationProvider.notifier)
      .setEnabled(true);
  return container;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('shows the transparency slider on fallback platforms',
      (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);
    final container = await _enabledContainer();
    addTearDown(container.dispose);

    await tester.pumpWidget(
      _testApp(container, textScaler: const TextScaler.linear(1.5)),
    );
    await tester.scrollUntilVisible(
      find.byType(Slider),
      200,
      scrollable: find.byType(Scrollable).first,
    );

    expect(find.text('Liquid Glass Transparency'), findsOneWidget);
    expect(tester.widget<Slider>(find.byType(Slider)).value, 0.86);
    expect(tester.takeException(), isNull);
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('keeps native Apple glass under system control', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);
    final container = await _enabledContainer();
    addTearDown(container.dispose);

    await tester.pumpWidget(_testApp(container));
    await tester.drag(find.byType(ListView), const Offset(0, -1000));
    await tester.pump();

    expect(find.text('Liquid Glass Transparency'), findsNothing);
    expect(find.byType(Slider), findsNothing);
    debugDefaultTargetPlatformOverride = null;
  });
}
