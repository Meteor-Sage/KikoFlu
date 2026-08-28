import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kikoeru_flutter/l10n/app_localizations.dart';
import 'package:kikoeru_flutter/src/providers/text_scale_provider.dart';
import 'package:kikoeru_flutter/src/providers/theme_provider.dart';
import 'package:kikoeru_flutter/src/utils/theme.dart';
import 'package:kikoeru_flutter/src/widgets/age_rating_chip.dart';
import 'package:kikoeru_flutter/src/widgets/pagination_bar.dart';
import 'package:kikoeru_flutter/src/widgets/settings_section.dart';
import 'package:shared_preferences/shared_preferences.dart';

Widget _testApp({
  required Brightness brightness,
  required AppTextScale textScale,
  TextScaler systemTextScaler = TextScaler.noScaling,
}) {
  final theme = brightness == Brightness.dark
      ? AppTheme.darkTheme(
          null,
          ColorSchemeType.oceanBlue,
          const Locale('en'),
          textScale,
        )
      : AppTheme.lightTheme(
          null,
          ColorSchemeType.oceanBlue,
          const Locale('en'),
          textScale,
        );

  return ProviderScope(
    child: MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: S.localizationsDelegates,
      supportedLocales: S.supportedLocales,
      theme: theme,
      darkTheme: theme,
      themeMode: brightness == Brightness.dark
          ? ThemeMode.dark
          : ThemeMode.light,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(textScaler: systemTextScaler),
        child: child!,
      ),
      home: Scaffold(
        appBar: AppBar(title: const Text('Interface settings')),
        body: const SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SettingsSectionList(
                children: [
                  SettingsListTile(
                    icon: Icons.palette_outlined,
                    title: 'Appearance',
                    subtitle: 'Theme and component presentation',
                    trailing: Icon(Icons.chevron_right),
                  ),
                  SettingsSwitchTile(
                    icon: Icons.visibility_outlined,
                    title: 'Show metadata',
                    subtitle: 'Use semantic text styles',
                    value: true,
                    onChanged: null,
                  ),
                ],
              ),
              SizedBox(height: 16),
              TextField(
                decoration: InputDecoration(
                  labelText: 'Keyword',
                  prefixIcon: Icon(Icons.search),
                ),
              ),
              SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  AgeRatingChip(age: 'all'),
                  Chip(label: Text('Selected filter')),
                ],
              ),
              SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  FilledButton(onPressed: null, child: Text('Confirm')),
                  OutlinedButton(onPressed: null, child: Text('Cancel')),
                  TextButton(onPressed: null, child: Text('More')),
                ],
              ),
              SizedBox(height: 16),
              PaginationBar(
                currentPage: 1,
                pageSize: 20,
                totalCount: 10,
                hasMore: false,
                isLoading: false,
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  final viewports = <String, Size>{
    'mobile portrait': const Size(390, 844),
    'desktop landscape': const Size(1280, 720),
  };

  for (final brightness in Brightness.values) {
    for (final viewport in viewports.entries) {
      for (final textScale in AppTextScale.values) {
        testWidgets(
          '${brightness.name}, ${viewport.key}, ${textScale.name} renders',
          (tester) async {
            tester.view.physicalSize = viewport.value;
            tester.view.devicePixelRatio = 1;
            addTearDown(tester.view.resetPhysicalSize);
            addTearDown(tester.view.resetDevicePixelRatio);

            await tester.pumpWidget(
              _testApp(brightness: brightness, textScale: textScale),
            );
            await tester.pump();

            expect(find.text('Interface settings'), findsOneWidget);
            expect(find.text('Keyword'), findsOneWidget);
            expect(find.byType(PaginationBar), findsOneWidget);
            expect(tester.takeException(), isNull);
          },
        );
      }
    }
  }

  testWidgets('system text scaling remains additive to app preset', (
    tester,
  ) async {
    const textKey = ValueKey('scaled-text');

    Widget scaledApp(TextScaler scaler) {
      final theme = AppTheme.lightTheme(
        null,
        ColorSchemeType.oceanBlue,
        const Locale('en'),
        AppTextScale.large,
      );
      return MaterialApp(
        theme: theme,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: scaler),
          child: child!,
        ),
        home: Scaffold(
          body: Text(
            'System scaling',
            key: textKey,
            style: theme.textTheme.bodyMedium,
          ),
        ),
      );
    }

    await tester.pumpWidget(scaledApp(TextScaler.noScaling));
    final normalHeight = tester.getSize(find.byKey(textKey)).height;

    await tester.pumpWidget(scaledApp(const TextScaler.linear(1.5)));
    final scaledHeight = tester.getSize(find.byKey(textKey)).height;

    expect(scaledHeight, greaterThan(normalHeight));
  });
}
