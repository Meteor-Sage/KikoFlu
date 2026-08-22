import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kikoeru_flutter/src/providers/settings_provider.dart';
import 'package:kikoeru_flutter/src/services/translation_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> _pumpAsyncPreferenceLoad() async {
  for (var i = 0; i < 5; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('translation language preferences default to app language', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    var preferences = container.read(translationLanguagePreferencesProvider);
    expect(preferences.targetLanguage, TranslationTargetLanguage.followApp);

    await _pumpAsyncPreferenceLoad();

    preferences = container.read(translationLanguagePreferencesProvider);
    expect(preferences.targetLanguage, TranslationTargetLanguage.followApp);
  });

  test('translated lyrics auto-save defaults to enabled and persists',
      () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    expect(container.read(autoSaveTranslatedLyricsProvider), isTrue);
    await _pumpAsyncPreferenceLoad();
    expect(container.read(autoSaveTranslatedLyricsProvider), isTrue);

    final notifier =
        container.read(autoSaveTranslatedLyricsProvider.notifier);
    await notifier.setEnabled(false);

    expect(container.read(autoSaveTranslatedLyricsProvider), isFalse);
    final prefs = await SharedPreferences.getInstance();
    expect(
      prefs.getBool(AutoSaveTranslatedLyricsNotifier.preferenceKey),
      isFalse,
    );
  });

  test('translated lyrics auto-save loads a disabled preference', () async {
    SharedPreferences.setMockInitialValues({
      AutoSaveTranslatedLyricsNotifier.preferenceKey: false,
    });
    final container = ProviderContainer();
    addTearDown(container.dispose);

    expect(container.read(autoSaveTranslatedLyricsProvider), isTrue);
    await Future<void>.delayed(const Duration(milliseconds: 20));

    expect(container.read(autoSaveTranslatedLyricsProvider), isFalse);
  });

  test('translation language preferences load and persist target values',
      () async {
    SharedPreferences.setMockInitialValues({
      TranslationLanguagePreferencesNotifier.keyTargetLanguage:
          TranslationTargetLanguage.english.value,
      TranslationLanguagePreferencesNotifier.keyCustomTargetLanguage:
          'Portuguese (Brazil)',
    });
    final container = ProviderContainer();
    addTearDown(container.dispose);

    expect(
        container.read(translationLanguagePreferencesProvider).targetLanguage,
        TranslationTargetLanguage.followApp);
    await _pumpAsyncPreferenceLoad();

    var preferences = container.read(translationLanguagePreferencesProvider);
    expect(preferences.targetLanguage, TranslationTargetLanguage.english);
    expect(preferences.customTargetLanguage, 'Portuguese (Brazil)');

    final notifier =
        container.read(translationLanguagePreferencesProvider.notifier);
    await notifier.updateTargetLanguage(TranslationTargetLanguage.custom);
    await notifier.updateCustomTargetLanguage('  Korean  ');

    preferences = container.read(translationLanguagePreferencesProvider);
    final prefs = await SharedPreferences.getInstance();

    expect(preferences.targetLanguage, TranslationTargetLanguage.custom);
    expect(preferences.customTargetLanguage, 'Korean');
    expect(
      prefs.getString(TranslationLanguagePreferencesNotifier.keyTargetLanguage),
      TranslationTargetLanguage.custom.value,
    );
    expect(
      prefs.getString(
          TranslationLanguagePreferencesNotifier.keyCustomTargetLanguage),
      'Korean',
    );
  });

  test('LLM settings normalize invalid concurrency values', () async {
    SharedPreferences.setMockInitialValues({
      'llm_settings_concurrency': 0,
    });
    final container = ProviderContainer();
    addTearDown(container.dispose);

    expect(
      container.read(llmSettingsProvider).concurrency,
      LLMSettings.defaultConcurrency,
    );
    await _pumpAsyncPreferenceLoad();

    expect(
      container.read(llmSettingsProvider).concurrency,
      LLMSettings.minConcurrency,
    );
    expect(
      const LLMSettings().copyWith(concurrency: 99).concurrency,
      LLMSettings.maxConcurrency,
    );

    await container.read(llmSettingsProvider.notifier).updateSettings(
          const LLMSettings(concurrency: -5),
        );

    final prefs = await SharedPreferences.getInstance();
    expect(
      container.read(llmSettingsProvider).concurrency,
      LLMSettings.minConcurrency,
    );
    expect(
      prefs.getInt('llm_settings_concurrency'),
      LLMSettings.minConcurrency,
    );
  });

  test('LLM default prompt uses custom target language and auto source',
      () async {
    SharedPreferences.setMockInitialValues({
      'translation_source': TranslationSource.llm.value,
      'translation_source_language': 'custom',
      TranslationLanguagePreferencesNotifier.keyTargetLanguage:
          TranslationTargetLanguage.custom.value,
      'translation_custom_source_language': 'Korean',
      TranslationLanguagePreferencesNotifier.keyCustomTargetLanguage:
          'Portuguese (Brazil)',
    });

    final prompt =
        await TranslationService().getDefaultLLMPromptForCurrentLocale();

    expect(prompt, isNot(contains('from Korean')));
    expect(prompt, contains('into Portuguese (Brazil)'));
  });

  test('identifies generated default LLM prompts', () {
    final prompt = TranslationService.getDefaultLLMPrompt(
      const Locale('en'),
      sourceLanguageName: 'Japanese',
      targetLanguageName: 'Korean',
    );

    expect(TranslationService.isGeneratedDefaultLLMPrompt(prompt), true);
    expect(
      TranslationService.isGeneratedDefaultLLMPrompt(
        'Translate casually and keep honorifics.',
      ),
      false,
    );
  });

  test('non-LLM prompt ignores custom languages and follows app language',
      () async {
    SharedPreferences.setMockInitialValues({
      'translation_source': TranslationSource.google.value,
      'locale_language': 'en',
      'translation_source_language': 'custom',
      TranslationLanguagePreferencesNotifier.keyTargetLanguage:
          TranslationTargetLanguage.custom.value,
      'translation_custom_source_language': 'Korean',
      TranslationLanguagePreferencesNotifier.keyCustomTargetLanguage:
          'Portuguese (Brazil)',
    });

    final prompt =
        await TranslationService().getDefaultLLMPromptForCurrentLocale();

    expect(prompt, isNot(contains('from Korean')));
    expect(prompt, isNot(contains('Portuguese (Brazil)')));
    expect(prompt, contains('into English'));
  });
}
