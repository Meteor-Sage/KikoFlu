import 'dart:ui';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/llm_api_protocol.dart';
import '../providers/settings_provider.dart';
import 'log_service.dart';
import 'translation_service.dart';

class LLMTranslator {
  LLMTranslator({Dio? dio}) : _dio = dio ?? Dio();

  final Dio _dio;

  Future<String> translate(
    String text, {
    String? sourceLang,
    Locale? locale,
    String? sourceLanguageName,
    String? targetLanguageName,
  }) async {
    if (text.isEmpty) return text;

    try {
      final prefs = await SharedPreferences.getInstance();
      final savedApiUrl =
          prefs.getString(LLMSettingsNotifier.apiUrlPreferenceKey) ??
          const LLMSettings().apiUrl;
      final apiProtocol = LLMApiProtocol.fromPreference(
        prefs.getString(LLMSettingsNotifier.apiProtocolPreferenceKey),
        apiUrl: savedApiUrl,
      );
      final apiUrl = apiProtocol.resolveEndpoint(savedApiUrl);
      final apiKey =
          prefs.getString(LLMSettingsNotifier.apiKeyPreferenceKey) ?? '';
      final model =
          prefs.getString(LLMSettingsNotifier.modelPreferenceKey) ??
          const LLMSettings().model;
      final savedPrompt = prefs.getString(
        LLMSettingsNotifier.promptPreferenceKey,
      );
      final useDefaultPrompt =
          savedPrompt == null ||
          savedPrompt.isEmpty ||
          TranslationService.isGeneratedDefaultLLMPrompt(savedPrompt);
      final prompt = useDefaultPrompt
          ? TranslationService.getDefaultLLMPrompt(
              locale ?? const Locale('zh'),
              sourceLanguageName: sourceLanguageName,
              targetLanguageName: targetLanguageName,
            )
          : savedPrompt;

      if (apiKey.isEmpty) {
        return 'Error: API Key is missing. Please configure LLM settings.';
      }

      final response = await _dio.post(
        apiUrl,
        options: Options(
          headers: buildHeaders(protocol: apiProtocol, apiKey: apiKey),
          responseType: ResponseType.json,
        ),
        data: buildRequestData(
          protocol: apiProtocol,
          model: model,
          prompt: prompt,
          text: text,
        ),
      );

      if (response.statusCode == 200) {
        return extractTranslatedText(
              protocol: apiProtocol,
              data: response.data,
            ) ??
            text;
      }
      return text;
    } catch (e) {
      logOutput('LLM translation error: $e');
      if (e is DioException) {
        if (e.response != null) {
          logOutput('Response data: ${e.response?.data}');
          return 'Error: ${e.response?.statusCode} - ${e.response?.statusMessage}';
        }
      }
      return text;
    }
  }

  static Map<String, dynamic> buildRequestData({
    required LLMApiProtocol protocol,
    required String model,
    required String prompt,
    required String text,
  }) {
    switch (protocol) {
      case LLMApiProtocol.chatCompletions:
        return {
          'model': model,
          'messages': [
            {'role': 'system', 'content': prompt},
            {'role': 'user', 'content': text},
          ],
          'temperature': 0.3,
        };
      case LLMApiProtocol.responses:
        return {'model': model, 'instructions': prompt, 'input': text};
      case LLMApiProtocol.anthropic:
        return {
          'model': model,
          'max_tokens': 4096,
          'system': prompt,
          'messages': [
            {'role': 'user', 'content': text},
          ],
          'temperature': 0.3,
        };
    }
  }

  static Map<String, String> buildHeaders({
    required LLMApiProtocol protocol,
    required String apiKey,
  }) {
    switch (protocol) {
      case LLMApiProtocol.anthropic:
        return {
          'x-api-key': apiKey,
          'anthropic-version': '2023-06-01',
          'Content-Type': 'application/json',
        };
      case LLMApiProtocol.chatCompletions:
      case LLMApiProtocol.responses:
        return {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
        };
    }
  }

  static String? extractTranslatedText({
    required LLMApiProtocol protocol,
    required dynamic data,
  }) {
    if (data is! Map) return null;

    switch (protocol) {
      case LLMApiProtocol.chatCompletions:
        final choices = data['choices'];
        if (choices is! List || choices.isEmpty) return null;
        final choice = choices.first;
        final message = choice is Map ? choice['message'] : null;
        final content = message is Map ? message['content'] : null;
        if (content is String) return _nonEmptyTrimmed(content);
        if (content is List) {
          return _joinTextBlocks(content);
        }
        return null;
      case LLMApiProtocol.responses:
        final outputText = data['output_text'];
        if (outputText is String) return _nonEmptyTrimmed(outputText);

        final output = data['output'];
        if (output is! List) return null;
        final textBlocks = <dynamic>[];
        for (final item in output) {
          if (item is! Map || item['type'] != 'message') continue;
          final content = item['content'];
          if (content is List) textBlocks.addAll(content);
        }
        return _joinTextBlocks(textBlocks);
      case LLMApiProtocol.anthropic:
        return _joinTextBlocks(
          data['content'] is List
              ? data['content'] as List<dynamic>
              : const <dynamic>[],
        );
    }
  }

  static String? _joinTextBlocks(List<dynamic> blocks) {
    final parts = <String>[];
    for (final block in blocks) {
      if (block is! Map) continue;
      final text = block['text'];
      if (text is String && text.trim().isNotEmpty) {
        parts.add(text.trim());
      }
    }
    return parts.isEmpty ? null : parts.join('\n');
  }

  static String? _nonEmptyTrimmed(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}
