import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kikoeru_flutter/src/models/llm_api_protocol.dart';
import 'package:kikoeru_flutter/src/providers/settings_provider.dart';
import 'package:kikoeru_flutter/src/services/llm_translator.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> _pumpAsyncPreferenceLoad() async {
  await Future<void>.delayed(const Duration(milliseconds: 100));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test(
    'legacy full Chat Completions URL is migrated without changing mode',
    () async {
      SharedPreferences.setMockInitialValues({
        LLMSettingsNotifier.apiUrlPreferenceKey:
            'https://api.openai.com/v1/chat/completions',
        LLMSettingsNotifier.apiKeyPreferenceKey: 'legacy-key',
      });
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(llmSettingsProvider);
      await _pumpAsyncPreferenceLoad();

      final settings = container.read(llmSettingsProvider);
      expect(settings.apiUrl, 'https://api.openai.com/v1');
      expect(settings.apiProtocol, LLMApiProtocol.chatCompletions);
      expect(settings.apiKey, 'legacy-key');
    },
  );

  test('Responses mode and normalized base URL are persisted', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await container
        .read(llmSettingsProvider.notifier)
        .updateSettings(
          const LLMSettings(
            apiUrl: 'https://example.com/v1/responses/',
            apiProtocol: LLMApiProtocol.responses,
          ),
        );

    final settings = container.read(llmSettingsProvider);
    final prefs = await SharedPreferences.getInstance();
    expect(settings.apiUrl, 'https://example.com/v1');
    expect(settings.apiProtocol, LLMApiProtocol.responses);
    expect(
      prefs.getString(LLMSettingsNotifier.apiUrlPreferenceKey),
      'https://example.com/v1',
    );
    expect(
      prefs.getString(LLMSettingsNotifier.apiProtocolPreferenceKey),
      LLMApiProtocol.responses.preferenceValue,
    );
  });

  test('protocol resolves the selected endpoint suffix exactly once', () {
    expect(
      LLMApiProtocol.chatCompletions.resolveEndpoint(
        'https://example.com/v1/chat/completions/',
      ),
      'https://example.com/v1/chat/completions',
    );
    expect(
      LLMApiProtocol.responses.resolveEndpoint(
        'https://example.com/v1/chat/completions',
      ),
      'https://example.com/v1/responses',
    );
    expect(
      LLMApiProtocol.anthropic.resolveEndpoint(
        'https://example.com/v1/messages/',
      ),
      'https://example.com/v1/messages',
    );
  });

  test('Chat Completions request uses messages', () {
    final request = LLMTranslator.buildRequestData(
      protocol: LLMApiProtocol.chatCompletions,
      model: 'test-model',
      prompt: 'Translate only.',
      text: 'hello',
    );

    expect(request['model'], 'test-model');
    expect(request['messages'], [
      {'role': 'system', 'content': 'Translate only.'},
      {'role': 'user', 'content': 'hello'},
    ]);
    expect(request['temperature'], 0.3);
    expect(request, isNot(contains('input')));
  });

  test('Responses request uses instructions and input', () {
    final request = LLMTranslator.buildRequestData(
      protocol: LLMApiProtocol.responses,
      model: 'test-model',
      prompt: 'Translate only.',
      text: 'hello',
    );

    expect(request, {
      'model': 'test-model',
      'instructions': 'Translate only.',
      'input': 'hello',
    });
  });

  test('Anthropic request uses Messages API fields and headers', () {
    final request = LLMTranslator.buildRequestData(
      protocol: LLMApiProtocol.anthropic,
      model: 'claude-sonnet-5',
      prompt: 'Translate only.',
      text: 'hello',
    );
    final headers = LLMTranslator.buildHeaders(
      protocol: LLMApiProtocol.anthropic,
      apiKey: 'test-key',
    );

    expect(request, {
      'model': 'claude-sonnet-5',
      'max_tokens': 4096,
      'system': 'Translate only.',
      'messages': [
        {'role': 'user', 'content': 'hello'},
      ],
      'temperature': 0.3,
    });
    expect(headers, {
      'x-api-key': 'test-key',
      'anthropic-version': '2023-06-01',
      'Content-Type': 'application/json',
    });
  });

  test('Responses output message text is extracted', () {
    final translated = LLMTranslator.extractTranslatedText(
      protocol: LLMApiProtocol.responses,
      data: {
        'output': [
          {'type': 'reasoning', 'content': []},
          {
            'type': 'message',
            'role': 'assistant',
            'content': [
              {'type': 'output_text', 'text': '  你好  '},
            ],
          },
        ],
      },
    );

    expect(translated, '你好');
  });

  test('Anthropic content blocks are extracted', () {
    final translated = LLMTranslator.extractTranslatedText(
      protocol: LLMApiProtocol.anthropic,
      data: {
        'content': [
          {'type': 'text', 'text': '  你好  '},
        ],
      },
    );

    expect(translated, '你好');
  });
}
