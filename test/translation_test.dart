import 'package:flutter_test/flutter_test.dart';
import 'package:kikoeru_flutter/src/services/youdao_translator.dart';
import 'package:kikoeru_flutter/src/services/microsoft_translator.dart';
import 'package:translator/translator.dart';

void main() {
  group('Translation Sources Availability Test', () {
    // 测试有道翻译源
    test('Youdao Translator should translate "Hello" to Chinese', () async {
      final translator = YoudaoTranslator();
      const sourceText = 'Hello';

      print('Testing Youdao Translator...');
      final startTime = DateTime.now();

      final result = await translator.translate(sourceText);

      final duration = DateTime.now().difference(startTime);
      print('Youdao Translation Result: "$sourceText" -> "$result"');
      print('Time taken: ${duration.inMilliseconds}ms');

      // 验证结果不为空且不等于原文（表示翻译发生了）
      expect(result, isNotEmpty);
      expect(result, isNot(equals(sourceText)));
      // 验证包含常见的翻译结果
      expect(result, anyOf(contains('你好'), contains('您好'), contains('喂')));
    });

    // 测试微软翻译源
    test('Microsoft Translator should translate "Hello" to Chinese', () async {
      final translator = MicrosoftTranslator();
      const sourceText = 'Hello';

      print('Testing Microsoft Translator...');
      final startTime = DateTime.now();

      final result = await translator.translate(sourceText);

      final duration = DateTime.now().difference(startTime);
      print('Microsoft Translation Result: "$sourceText" -> "$result"');
      print('Time taken: ${duration.inMilliseconds}ms');

      expect(result, isNotEmpty);
      expect(result, isNot(equals(sourceText)));
      expect(result, anyOf(contains('你好'), contains('您好')));
    });

    // 测试 Google 翻译源
    test('Google Translator should translate "Hello" to Chinese', () async {
      final translator = GoogleTranslator();
      const sourceText = 'Hello';

      print('Testing Google Translator...');
      final startTime = DateTime.now();

      try {
        final result = await translator.translate(sourceText, to: 'zh-cn');

        final duration = DateTime.now().difference(startTime);
        print('Google Translation Result: "$sourceText" -> "${result.text}"');
        print('Time taken: ${duration.inMilliseconds}ms');

        expect(result.text, isNotEmpty);
        expect(result.text, isNot(equals(sourceText)));
        expect(result.text, anyOf(contains('你好'), contains('您好')));
      } catch (e) {
        print('Google Translator failed: $e');
        print('Note: Google Translate might be blocked in your region.');
        // 如果是因为网络原因失败，我们不希望测试直接挂掉，而是输出警告
        // 但如果是为了测试"可用性"，失败就是不可用。
        // 这里选择抛出异常让测试失败，以便用户知道不可用。
        rethrow;
      }
    });
  });
}
