import 'package:translator/translator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'youdao_translator.dart';
import 'microsoft_translator.dart';
import 'llm_translator.dart';
import '../utils/global_keys.dart';

class TranslationService {
  static final TranslationService _instance = TranslationService._internal();
  factory TranslationService() => _instance;
  TranslationService._internal();

  final GoogleTranslator _googleTranslator = GoogleTranslator();
  final YoudaoTranslator _youdaoTranslator = YoudaoTranslator();
  final MicrosoftTranslator _microsoftTranslator = MicrosoftTranslator();
  final LLMTranslator _llmTranslator = LLMTranslator();
  static const String _cachePrefix = 'translation_cache_';
  static const String _targetLang = 'zh-cn'; // 目标语言：简体中文

  /// 翻译文本到中文
  Future<String> translate(String text, {String? sourceLang}) async {
    if (text.isEmpty) return text;

    // 检查缓存
    final cachedTranslation = await _getCachedTranslation(text, sourceLang);
    if (cachedTranslation != null) {
      return cachedTranslation;
    }

    final prefs = await SharedPreferences.getInstance();
    final selectedSource = prefs.getString('translation_source') ?? 'google';

    // 构建尝试列表
    final sourcesToTry = <String>[selectedSource];

    // 默认回退顺序
    final fallbackOrder = ['youdao', 'microsoft', 'google', 'llm'];

    for (final source in fallbackOrder) {
      if (source == selectedSource) continue;

      // 特殊检查 LLM
      if (source == 'llm') {
        final apiKey = prefs.getString('llm_settings_api_key') ?? '';
        if (apiKey.isEmpty) continue;
      }

      sourcesToTry.add(source);
    }

    for (final source in sourcesToTry) {
      try {
        String result;
        if (source == 'youdao') {
          result =
              await _youdaoTranslator.translate(text, sourceLang: sourceLang);
        } else if (source == 'microsoft') {
          result = await _microsoftTranslator.translate(text,
              sourceLang: sourceLang);
        } else if (source == 'llm') {
          result = await _llmTranslator.translate(text, sourceLang: sourceLang);
        } else {
          // Google 翻译
          final translation = await _googleTranslator.translate(
            text,
            from: sourceLang ?? 'auto',
            to: _targetLang,
          );
          result = translation.text;
        }

        // 如果成功且不是首选源，提示用户
        if (source != selectedSource) {
          _showFallbackNotification(source);
        }

        // 缓存结果
        await _cacheTranslation(text, result, sourceLang);

        return result;
      } catch (e) {
        print('Translation error with $source: $e');
        // 继续尝试下一个
      }
    }

    return text; // 所有尝试都失败，返回原文
  }

  void _showFallbackNotification(String sourceName) {
    String displayName = sourceName;
    if (sourceName == 'youdao') {
      displayName = 'Youdao 翻译';
    } else if (sourceName == 'microsoft') {
      displayName = 'Microsoft 翻译';
    } else if (sourceName == 'google') {
      displayName = 'Google 翻译';
    } else if (sourceName == 'llm') {
      displayName = 'LLM 翻译';
    }

    rootScaffoldMessengerKey.currentState?.showSnackBar(
      SnackBar(
        content: Text('翻译失败，已自动切换至 $displayName'),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// 批量翻译
  Future<List<String>> translateBatch(List<String> texts,
      {String? sourceLang}) async {
    if (texts.isEmpty) return [];

    // 获取并发设置
    final prefs = await SharedPreferences.getInstance();
    final source = prefs.getString('translation_source') ?? 'google';
    int concurrency = 1;
    if (source == 'llm') {
      concurrency = prefs.getInt('llm_settings_concurrency') ?? 3;
    }

    final results = List<String>.filled(texts.length, '');
    int currentIndex = 0;

    Future<void> worker() async {
      while (true) {
        int index;
        if (currentIndex >= texts.length) return;
        index = currentIndex++;

        try {
          final translated =
              await translate(texts[index], sourceLang: sourceLang);
          results[index] = translated;
        } catch (e) {
          print('Translation batch item $index failed: $e');
          results[index] = texts[index];
        }
      }
    }

    final workers = List.generate(concurrency, (_) => worker());
    await Future.wait(workers);

    return results;
  }

  /// 分块翻译长文本
  /// 每块最多 1500 字符，避免超过翻译 API 的 URL 长度限制
  Future<String> translateLongText(
    String text, {
    String? sourceLang,
    Function(int current, int total)? onProgress,
  }) async {
    if (text.isEmpty) return text;

    // Google Translate 通过 URL 传参，URL 长度有限制
    // 考虑到 URL 编码后长度会增加，保守设置为 1500 字符
    const maxChunkSize = 1500;
    final chunks = <String>[];
    final lines = text.split('\n');

    String currentChunk = '';
    for (final line in lines) {
      // 预估加上换行符后的长度
      final estimatedLength = currentChunk.length + line.length + 1;

      if (estimatedLength > maxChunkSize && currentChunk.isNotEmpty) {
        // 当前块已满，保存并开始新块
        chunks.add(currentChunk);
        currentChunk = '';
      }

      // 如果单行就超过限制，按字符强制分割
      if (line.length > maxChunkSize) {
        if (currentChunk.isNotEmpty) {
          chunks.add(currentChunk);
          currentChunk = '';
        }

        for (int i = 0; i < line.length; i += maxChunkSize) {
          final endIndex =
              (i + maxChunkSize > line.length) ? line.length : i + maxChunkSize;
          chunks.add(line.substring(i, endIndex));
        }
      } else {
        // 正常情况，添加到当前块
        if (currentChunk.isNotEmpty) currentChunk += '\n';
        currentChunk += line;
      }
    }

    // 添加最后一块
    if (currentChunk.isNotEmpty) {
      chunks.add(currentChunk);
    }

    // 获取并发设置
    final prefs = await SharedPreferences.getInstance();
    final source = prefs.getString('translation_source') ?? 'google';
    int concurrency = 1;
    if (source == 'llm') {
      concurrency = prefs.getInt('llm_settings_concurrency') ?? 3;
    }

    // 并发翻译
    final results = List<String>.filled(chunks.length, '');
    int currentIndex = 0;
    int completedCount = 0;

    Future<void> worker() async {
      while (true) {
        int index;
        if (currentIndex >= chunks.length) return;
        index = currentIndex++;

        try {
          final translated =
              await translate(chunks[index], sourceLang: sourceLang);
          results[index] = translated;
        } catch (e) {
          print('Translation chunk $index failed: $e');
          results[index] = chunks[index];
        } finally {
          completedCount++;
          onProgress?.call(completedCount, chunks.length);
        }
      }
    }

    final workers = List.generate(concurrency, (_) => worker());
    await Future.wait(workers);

    return results.join('\n');
  }

  /// 获取缓存的翻译
  Future<String?> _getCachedTranslation(String text, String? sourceLang) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = _getCacheKey(text, sourceLang);
      final cached = prefs.getString(key);
      if (cached != null) {
        final data = json.decode(cached);
        // 缓存7天有效
        final timestamp = data['timestamp'] as int;
        if (DateTime.now().millisecondsSinceEpoch - timestamp <
            7 * 24 * 60 * 60 * 1000) {
          return data['translation'] as String;
        }
      }
    } catch (e) {
      print('Cache read error: $e');
    }
    return null;
  }

  /// 缓存翻译结果
  Future<void> _cacheTranslation(
      String text, String translation, String? sourceLang) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = _getCacheKey(text, sourceLang);
      final data = json.encode({
        'translation': translation,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });
      await prefs.setString(key, data);
    } catch (e) {
      print('Cache write error: $e');
    }
  }

  /// 生成缓存键
  String _getCacheKey(String text, String? sourceLang) {
    final lang = sourceLang ?? 'auto';
    return '$_cachePrefix${lang}_${text.hashCode}';
  }

  /// 清除所有翻译缓存
  Future<void> clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      for (final key in keys) {
        if (key.startsWith(_cachePrefix)) {
          await prefs.remove(key);
        }
      }
    } catch (e) {
      print('Cache clear error: $e');
    }
  }

  /// 检测语言
  Future<String> detectLanguage(String text) async {
    try {
      final translation = await _googleTranslator.translate(text, from: 'auto');
      return translation.sourceLanguage.code;
    } catch (e) {
      print('Language detection error: $e');
      return 'unknown';
    }
  }
}
