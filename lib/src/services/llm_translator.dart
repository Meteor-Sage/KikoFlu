import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LLMTranslator {
  final Dio _dio = Dio();

  Future<String> translate(String text, {String? sourceLang}) async {
    if (text.isEmpty) return text;

    try {
      final prefs = await SharedPreferences.getInstance();
      final apiUrl = prefs.getString('llm_settings_api_url') ??
          'https://api.openai.com/v1/chat/completions';
      final apiKey = prefs.getString('llm_settings_api_key') ?? '';
      final model = prefs.getString('llm_settings_model') ?? 'gpt-3.5-turbo';
      final prompt = prefs.getString('llm_settings_prompt') ??
          'You are a professional translator. Translate the following text into Simplified Chinese (zh-CN). Output ONLY the translated text without any explanations, notes, or markdown code blocks.';

      if (apiKey.isEmpty) {
        return 'Error: API Key is missing. Please configure LLM settings.';
      }

      final response = await _dio.post(
        apiUrl,
        options: Options(
          headers: {
            'Authorization': 'Bearer $apiKey',
            'Content-Type': 'application/json',
          },
          responseType: ResponseType.json,
        ),
        data: {
          'model': model,
          'messages': [
            {'role': 'system', 'content': prompt},
            {'role': 'user', 'content': text},
          ],
          'temperature': 0.3,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data;
        if (data != null &&
            data['choices'] != null &&
            data['choices'].isNotEmpty) {
          final content = data['choices'][0]['message']['content'];
          return content?.trim() ?? text;
        }
      }
      return text;
    } catch (e) {
      print('LLM translation error: $e');
      if (e is DioException) {
        if (e.response != null) {
          print('Response data: ${e.response?.data}');
          return 'Error: ${e.response?.statusCode} - ${e.response?.statusMessage}';
        }
      }
      return text;
    }
  }
}
