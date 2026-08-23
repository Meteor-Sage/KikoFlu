import 'dart:ui';

import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:real_liquid_glass/real_liquid_glass.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/audio_gain_settings.dart';
import '../models/sort_options.dart';

/// Triggers when Settings screen should refresh cache-related information.
final settingsCacheRefreshTriggerProvider = StateProvider<int>((ref) => 0);

/// Triggers when Subtitle Library screen should refresh (e.g., after path change).
final subtitleLibraryRefreshTriggerProvider = StateProvider<int>((ref) => 0);

/// Controls the optional liquid-glass treatment for the main navigation and
/// the mini player. Only Apple OS versions with native Liquid Glass support
/// enable it by default; fallback remains available as an explicit choice.
class LiquidGlassNavigationNotifier extends StateNotifier<bool> {
  static const String preferenceKey = 'liquid_glass_navigation_enabled';

  LiquidGlassNavigationNotifier() : super(defaultValue) {
    _loadPreference();
  }

  static bool defaultForCapabilities(LiquidGlassCapabilities? capabilities) {
    final isApplePlatform =
        defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS;
    return isApplePlatform && capabilities?.nativeGlass == true;
  }

  static bool get defaultValue =>
      defaultForCapabilities(LiquidGlass.cachedCapabilities);

  bool _changedLocally = false;

  Future<void> _loadPreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (!mounted || _changedLocally) return;
      final savedValue = prefs.getBool(preferenceKey);
      if (savedValue != null) {
        state = savedValue;
        return;
      }

      final capabilities =
          LiquidGlass.cachedCapabilities ?? await LiquidGlass.capabilities();
      if (!mounted || _changedLocally) return;
      state = defaultForCapabilities(capabilities);
    } catch (_) {
      if (!mounted || _changedLocally) return;
      state = defaultValue;
    }
  }

  Future<void> setEnabled(bool enabled) async {
    _changedLocally = true;
    state = enabled;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(preferenceKey, enabled);
    } catch (_) {
      // Keep the in-memory value when persistence is unavailable.
    }
  }

  Future<void> resetToDefault() async {
    final capabilities =
        LiquidGlass.cachedCapabilities ?? await LiquidGlass.capabilities();
    await setEnabled(defaultForCapabilities(capabilities));
  }
}

final liquidGlassNavigationProvider =
    StateNotifierProvider<LiquidGlassNavigationNotifier, bool>((ref) {
  return LiquidGlassNavigationNotifier();
});

/// Controls the transparency of Flutter-drawn glass on non-Apple platforms.
/// Native iOS and macOS materials continue to follow the system appearance.
class FallbackGlassTransparencyNotifier extends StateNotifier<double> {
  static const String preferenceKey = 'fallback_glass_transparency';
  static const double defaultValue = 0.4;

  FallbackGlassTransparencyNotifier() : super(defaultValue) {
    _loadPreference();
  }

  bool _changedLocally = false;

  static double normalize(double value) => value.clamp(0.0, 1.0).toDouble();

  Future<void> _loadPreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (!mounted || _changedLocally) return;
      state = normalize(prefs.getDouble(preferenceKey) ?? defaultValue);
    } catch (_) {
      if (!mounted || _changedLocally) return;
      state = defaultValue;
    }
  }

  void previewTransparency(double value) {
    _changedLocally = true;
    state = normalize(value);
  }

  Future<void> setTransparency(double value) async {
    previewTransparency(value);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(preferenceKey, state);
    } catch (_) {
      // Keep the in-memory value when persistence is unavailable.
    }
  }

  Future<void> resetToDefault() => setTransparency(defaultValue);
}

final fallbackGlassTransparencyProvider = StateNotifierProvider<
    FallbackGlassTransparencyNotifier, double>((ref) {
  return FallbackGlassTransparencyNotifier();
});

/// 字幕库匹配优先级
enum SubtitleLibraryPriority {
  /// 最优先 - 字幕库优先于文件树匹配
  highest('优先', 'highest'),

  /// 最后 - 字幕库在文件树匹配之后
  lowest('滞后', 'lowest');

  final String displayName;
  final String value;
  const SubtitleLibraryPriority(this.displayName, this.value);
}

/// 字幕库优先级设置
class SubtitleLibraryPriorityNotifier
    extends StateNotifier<SubtitleLibraryPriority> {
  static const String _preferenceKey = 'subtitle_library_priority';

  SubtitleLibraryPriorityNotifier() : super(SubtitleLibraryPriority.highest) {
    _loadPreference();
  }

  Future<void> _loadPreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedValue = prefs.getString(_preferenceKey);

      if (savedValue != null) {
        final priority = SubtitleLibraryPriority.values.firstWhere(
          (p) => p.value == savedValue,
          orElse: () => SubtitleLibraryPriority.highest,
        );
        state = priority;
      }
    } catch (e) {
      // 加载失败，使用默认值
      state = SubtitleLibraryPriority.highest;
    }
  }

  Future<void> updatePriority(SubtitleLibraryPriority priority) async {
    state = priority;
    await _savePreference();
  }

  Future<void> _savePreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_preferenceKey, state.value);
    } catch (e) {
      // 保存失败时静默处理
    }
  }
}

/// 字幕库优先级提供者
final subtitleLibraryPriorityProvider = StateNotifierProvider<
    SubtitleLibraryPriorityNotifier, SubtitleLibraryPriority>((ref) {
  return SubtitleLibraryPriorityNotifier();
});

/// 音频格式类型
enum AudioFormat {
  mp3('MP3', 'mp3'),
  flac('FLAC', 'flac'),
  wav('WAV', 'wav'),
  opus('Opus', 'opus'),
  m4a('M4A', 'm4a'),
  aac('AAC', 'aac');

  final String displayName;
  final String extension;
  const AudioFormat(this.displayName, this.extension);
}

/// 翻译源
enum TranslationSource {
  google('Google 翻译', 'google'),
  youdao('Youdao 翻译', 'youdao'),
  microsoft('Microsoft 翻译', 'microsoft'),
  llm('LLM 翻译', 'llm');

  final String displayName;
  final String value;
  const TranslationSource(this.displayName, this.value);
}

/// 翻译目标语言
enum TranslationTargetLanguage {
  followApp('follow_app'),
  zhHans('zh_hans'),
  zhHant('zh_hant'),
  english('en'),
  japanese('ja'),
  russian('ru'),
  custom('custom');

  final String value;
  const TranslationTargetLanguage(this.value);

  static TranslationTargetLanguage fromValue(String? value) {
    return TranslationTargetLanguage.values.firstWhere(
      (language) => language.value == value,
      orElse: () => TranslationTargetLanguage.followApp,
    );
  }

  Locale resolveLocale(Locale appLocale) {
    return switch (this) {
      TranslationTargetLanguage.followApp => appLocale,
      TranslationTargetLanguage.zhHans =>
        const Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hans'),
      TranslationTargetLanguage.zhHant =>
        const Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant'),
      TranslationTargetLanguage.english => const Locale('en'),
      TranslationTargetLanguage.japanese => const Locale('ja'),
      TranslationTargetLanguage.russian => const Locale('ru'),
      TranslationTargetLanguage.custom => appLocale,
    };
  }
}

class TranslationLanguagePreferences {
  final TranslationTargetLanguage targetLanguage;
  final String customTargetLanguage;

  const TranslationLanguagePreferences({
    this.targetLanguage = TranslationTargetLanguage.followApp,
    this.customTargetLanguage = '',
  });

  TranslationLanguagePreferences copyWith({
    TranslationTargetLanguage? targetLanguage,
    String? customTargetLanguage,
  }) {
    return TranslationLanguagePreferences(
      targetLanguage: targetLanguage ?? this.targetLanguage,
      customTargetLanguage: customTargetLanguage ?? this.customTargetLanguage,
    );
  }
}

class LLMSettings {
  static const int minConcurrency = 1;
  static const int maxConcurrency = 10;
  static const int defaultConcurrency = 3;

  final String apiUrl;
  final String apiKey;
  final String model;
  final String prompt;
  final int concurrency;

  const LLMSettings({
    this.apiUrl = 'https://api.openai.com/v1/chat/completions',
    this.apiKey = '',
    this.model = 'gpt-3.5-turbo',
    this.prompt = '',
    this.concurrency = defaultConcurrency,
  });

  static int normalizeConcurrency(int? value) {
    final raw = value ?? defaultConcurrency;
    return raw.clamp(minConcurrency, maxConcurrency).toInt();
  }

  LLMSettings copyWith({
    String? apiUrl,
    String? apiKey,
    String? model,
    String? prompt,
    int? concurrency,
  }) {
    return LLMSettings(
      apiUrl: apiUrl ?? this.apiUrl,
      apiKey: apiKey ?? this.apiKey,
      model: model ?? this.model,
      prompt: prompt ?? this.prompt,
      concurrency: concurrency == null
          ? this.concurrency
          : normalizeConcurrency(concurrency),
    );
  }
}

class LLMSettingsNotifier extends StateNotifier<LLMSettings> {
  static const String _prefix = 'llm_settings_';

  LLMSettingsNotifier() : super(const LLMSettings()) {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      state = LLMSettings(
        apiUrl: prefs.getString('${_prefix}api_url') ?? state.apiUrl,
        apiKey: prefs.getString('${_prefix}api_key') ?? state.apiKey,
        model: prefs.getString('${_prefix}model') ?? state.model,
        prompt: prefs.getString('${_prefix}prompt') ?? state.prompt,
        concurrency: LLMSettings.normalizeConcurrency(
          prefs.getInt('${_prefix}concurrency'),
        ),
      );
    } catch (e) {
      // ignore
    }
  }

  Future<void> updateSettings(LLMSettings settings) async {
    final normalizedSettings = settings.copyWith(
      concurrency: LLMSettings.normalizeConcurrency(settings.concurrency),
    );
    state = normalizedSettings;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('${_prefix}api_url', normalizedSettings.apiUrl);
      await prefs.setString('${_prefix}api_key', normalizedSettings.apiKey);
      await prefs.setString('${_prefix}model', normalizedSettings.model);
      await prefs.setString('${_prefix}prompt', normalizedSettings.prompt);
      await prefs.setInt(
        '${_prefix}concurrency',
        normalizedSettings.concurrency,
      );
    } catch (e) {
      // ignore
    }
  }
}

final llmSettingsProvider =
    StateNotifierProvider<LLMSettingsNotifier, LLMSettings>((ref) {
  return LLMSettingsNotifier();
});

/// 翻译源设置
class TranslationSourceNotifier extends StateNotifier<TranslationSource> {
  static const String _preferenceKey = 'translation_source';

  TranslationSourceNotifier() : super(TranslationSource.google) {
    _loadPreference();
  }

  Future<void> _loadPreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedValue = prefs.getString(_preferenceKey);

      if (savedValue != null) {
        final source = TranslationSource.values.firstWhere(
          (s) => s.value == savedValue,
          orElse: () => TranslationSource.google,
        );
        state = source;
      }
    } catch (e) {
      state = TranslationSource.google;
    }
  }

  Future<void> updateSource(TranslationSource source) async {
    state = source;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_preferenceKey, state.value);
    } catch (e) {
      // ignore
    }
  }
}

final translationSourceProvider =
    StateNotifierProvider<TranslationSourceNotifier, TranslationSource>((ref) {
  return TranslationSourceNotifier();
});

/// Controls whether translated lyrics are written to the subtitle library.
class AutoSaveTranslatedLyricsNotifier extends StateNotifier<bool> {
  static const String preferenceKey = 'auto_save_translated_lyrics';

  AutoSaveTranslatedLyricsNotifier() : super(true) {
    _preferenceLoad = _loadPreference();
  }

  late final Future<void> _preferenceLoad;
  bool _changedLocally = false;

  Future<void> _loadPreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (!mounted || _changedLocally) return;
      state = prefs.getBool(preferenceKey) ?? true;
    } catch (_) {
      if (!mounted || _changedLocally) return;
      state = true;
    }
  }

  Future<bool> resolvedEnabled() async {
    await _preferenceLoad;
    return state;
  }

  Future<void> setEnabled(bool enabled) async {
    _changedLocally = true;
    state = enabled;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(preferenceKey, enabled);
    } catch (_) {
      // Keep the in-memory value when persistence is unavailable.
    }
  }
}

final autoSaveTranslatedLyricsProvider =
    StateNotifierProvider<AutoSaveTranslatedLyricsNotifier, bool>((ref) {
  return AutoSaveTranslatedLyricsNotifier();
});

/// 翻译语言设置
class TranslationLanguagePreferencesNotifier
    extends StateNotifier<TranslationLanguagePreferences> {
  static const String keyTargetLanguage = 'translation_target_language';
  static const String keyCustomTargetLanguage =
      'translation_custom_target_language';

  TranslationLanguagePreferencesNotifier()
      : super(const TranslationLanguagePreferences()) {
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final preferences = TranslationLanguagePreferences(
        targetLanguage: TranslationTargetLanguage.fromValue(
          prefs.getString(keyTargetLanguage),
        ),
        customTargetLanguage: prefs.getString(keyCustomTargetLanguage) ?? '',
      );
      if (!mounted) return;
      state = preferences;
    } catch (e) {
      if (!mounted) return;
      state = const TranslationLanguagePreferences();
    }
  }

  Future<void> updateTargetLanguage(
    TranslationTargetLanguage targetLanguage,
  ) async {
    state = state.copyWith(targetLanguage: targetLanguage);
    await _savePreferences();
  }

  Future<void> updateCustomTargetLanguage(String languageName) async {
    state = state.copyWith(customTargetLanguage: languageName.trim());
    await _savePreferences();
  }

  Future<void> _savePreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(keyTargetLanguage, state.targetLanguage.value);
      await prefs.setString(
        keyCustomTargetLanguage,
        state.customTargetLanguage,
      );
    } catch (e) {
      // ignore
    }
  }
}

final translationLanguagePreferencesProvider = StateNotifierProvider<
    TranslationLanguagePreferencesNotifier,
    TranslationLanguagePreferences>((ref) {
  return TranslationLanguagePreferencesNotifier();
});

/// 音频格式优先级设置
class AudioFormatPreference {
  final List<AudioFormat> priority;

  const AudioFormatPreference({
    this.priority = const [
      AudioFormat.mp3,
      AudioFormat.flac,
      AudioFormat.wav,
      AudioFormat.opus,
      AudioFormat.m4a,
      AudioFormat.aac,
    ],
  });

  AudioFormatPreference copyWith({List<AudioFormat>? priority}) {
    return AudioFormatPreference(
      priority: priority ?? this.priority,
    );
  }
}

/// 音频格式优先级控制器
class AudioFormatPreferenceNotifier
    extends StateNotifier<AudioFormatPreference> {
  static const String _preferenceKey = 'audio_format_preference';
  bool _changedLocally = false;

  AudioFormatPreferenceNotifier() : super(const AudioFormatPreference()) {
    _loadPreference();
  }

  Future<void> _loadPreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_changedLocally) return;
      final savedOrder = prefs.getStringList(_preferenceKey);

      if (savedOrder != null && savedOrder.isNotEmpty) {
        final priority = savedOrder
            .map((ext) => AudioFormat.values.firstWhere(
                  (format) => format.extension == ext,
                  orElse: () => AudioFormat.mp3,
                ))
            .toList();

        // 确保所有格式都存在
        for (final format in AudioFormat.values) {
          if (!priority.contains(format)) {
            priority.add(format);
          }
        }

        state = AudioFormatPreference(priority: priority);
      }
    } catch (e) {
      // 加载失败，使用默认值
      state = const AudioFormatPreference();
    }
  }

  Future<void> updatePriority(List<AudioFormat> newPriority) async {
    _changedLocally = true;
    state = state.copyWith(priority: newPriority);
    await _savePreference();
  }

  Future<void> _savePreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final order = state.priority.map((format) => format.extension).toList();
      await prefs.setStringList(_preferenceKey, order);
    } catch (e) {
      // 保存失败时静默处理
    }
  }

  Future<void> resetToDefault() async {
    _changedLocally = true;
    state = const AudioFormatPreference();
    await _savePreference();
  }
}

/// 音频格式优先级提供者
final audioFormatPreferenceProvider =
    StateNotifierProvider<AudioFormatPreferenceNotifier, AudioFormatPreference>(
        (ref) {
  return AudioFormatPreferenceNotifier();
});

/// 下一首预加载阈值档位
enum PreloadThresholdMode {
  off('off'),
  seconds10('seconds10'),
  seconds20('seconds20'),
  seconds30('seconds30'),
  custom('custom');

  final String value;
  const PreloadThresholdMode(this.value);

  static PreloadThresholdMode fromValue(String? v) => values.firstWhere(
        (m) => m.value == v,
        orElse: () => PreloadThresholdMode.seconds10,
      );
}

/// 下一首预加载设置
class PreloadNextSettings {
  static const int minSeconds = 1;
  static const int maxSeconds = 300;
  static const int defaultCustomSeconds = 30;

  final PreloadThresholdMode mode;
  final int customSeconds;

  const PreloadNextSettings({
    this.mode = PreloadThresholdMode.seconds10,
    this.customSeconds = defaultCustomSeconds,
  });

  /// 生效阈值秒数，null 表示关闭预加载
  int? get effectiveSeconds {
    switch (mode) {
      case PreloadThresholdMode.off:
        return null;
      case PreloadThresholdMode.seconds10:
        return 10;
      case PreloadThresholdMode.seconds20:
        return 20;
      case PreloadThresholdMode.seconds30:
        return 30;
      case PreloadThresholdMode.custom:
        return customSeconds.clamp(minSeconds, maxSeconds);
    }
  }

  PreloadNextSettings copyWith({
    PreloadThresholdMode? mode,
    int? customSeconds,
  }) {
    return PreloadNextSettings(
      mode: mode ?? this.mode,
      customSeconds: customSeconds ?? this.customSeconds,
    );
  }
}

/// 下一首预加载设置控制器
class PreloadNextSettingsNotifier extends StateNotifier<PreloadNextSettings> {
  static const String _modeKey = 'preload_next_mode';
  static const String _customKey = 'preload_next_custom_seconds';

  PreloadNextSettingsNotifier() : super(const PreloadNextSettings()) {
    _load();
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (!mounted) return;
      final customRaw = prefs.getInt(_customKey);
      const custom = PreloadNextSettings.defaultCustomSeconds;
      final stored = customRaw ?? custom;
      final normalized = stored.clamp(
        PreloadNextSettings.minSeconds,
        PreloadNextSettings.maxSeconds,
      );
      state = PreloadNextSettings(
        mode: PreloadThresholdMode.fromValue(prefs.getString(_modeKey)),
        customSeconds: normalized,
      );
    } catch (_) {
      if (!mounted) return;
      state = const PreloadNextSettings();
    }
  }

  Future<void> updateMode(PreloadThresholdMode mode) async {
    state = state.copyWith(mode: mode);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_modeKey, mode.value);
    } catch (_) {
      // ignore
    }
  }

  Future<void> updateCustomSeconds(int seconds) async {
    final normalized = seconds.clamp(
      PreloadNextSettings.minSeconds,
      PreloadNextSettings.maxSeconds,
    );
    state = state.copyWith(customSeconds: normalized);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_customKey, normalized);
    } catch (_) {
      // ignore
    }
  }
}

/// 下一首预加载设置提供者
final preloadNextSettingsProvider =
    StateNotifierProvider<PreloadNextSettingsNotifier, PreloadNextSettings>(
        (ref) {
  return PreloadNextSettingsNotifier();
});

/// 防社死设置
class PrivacyModeSettings {
  final bool enabled;
  final bool blurCover;
  final bool blurCoverInApp;
  final bool maskTitle;
  final String customTitle;

  const PrivacyModeSettings({
    this.enabled = false,
    this.blurCover = true,
    this.blurCoverInApp = false,
    this.maskTitle = false,
    this.customTitle = '正在播放音频',
  });

  PrivacyModeSettings copyWith({
    bool? enabled,
    bool? blurCover,
    bool? blurCoverInApp,
    bool? maskTitle,
    String? customTitle,
  }) {
    return PrivacyModeSettings(
      enabled: enabled ?? this.enabled,
      blurCover: blurCover ?? this.blurCover,
      blurCoverInApp: blurCoverInApp ?? this.blurCoverInApp,
      maskTitle: maskTitle ?? this.maskTitle,
      customTitle: customTitle ?? this.customTitle,
    );
  }
}

/// 防社死设置控制器
class PrivacyModeSettingsNotifier extends StateNotifier<PrivacyModeSettings> {
  static const String _enabledKey = 'privacy_mode_enabled';
  static const String _blurCoverKey = 'privacy_mode_blur_cover';
  static const String _blurCoverInAppKey = 'privacy_mode_blur_cover_in_app';
  static const String _maskTitleKey = 'privacy_mode_mask_title';
  static const String _customTitleKey = 'privacy_mode_custom_title';
  bool _changedLocally = false;

  PrivacyModeSettingsNotifier() : super(const PrivacyModeSettings()) {
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (!mounted || _changedLocally) return;
      final blurCover = prefs.getBool(_blurCoverKey) ?? true;
      final blurCoverInApp = prefs.getBool(_blurCoverInAppKey) ?? false;

      state = PrivacyModeSettings(
        enabled: prefs.getBool(_enabledKey) ?? false,
        blurCover: blurCover,
        blurCoverInApp: blurCoverInApp,
        maskTitle: prefs.getBool(_maskTitleKey) ?? false,
        customTitle: prefs.getString(_customTitleKey) ?? '正在播放音频',
      );
    } catch (e) {
      // 加载失败，使用默认值
      state = const PrivacyModeSettings();
    }
  }

  Future<void> setEnabled(bool enabled) async {
    _changedLocally = true;
    state = state.copyWith(enabled: enabled);
    await _savePreference(_enabledKey, enabled);
  }

  Future<void> setBlurCover(bool blur) async {
    _changedLocally = true;
    state = state.copyWith(blurCover: blur);
    await _savePreference(_blurCoverKey, blur);
  }

  Future<void> setBlurCoverInApp(bool blur) async {
    _changedLocally = true;
    state = state.copyWith(blurCoverInApp: blur);
    await _savePreference(_blurCoverInAppKey, blur);
  }

  Future<void> setMaskTitle(bool mask) async {
    _changedLocally = true;
    state = state.copyWith(maskTitle: mask);
    await _savePreference(_maskTitleKey, mask);
  }

  Future<void> setCustomTitle(String title) async {
    _changedLocally = true;
    state = state.copyWith(customTitle: title);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_customTitleKey, title);
  }

  Future<void> resetToDefault() async {
    _changedLocally = true;
    state = const PrivacyModeSettings();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_enabledKey, state.enabled);
      await prefs.setBool(_blurCoverKey, state.blurCover);
      await prefs.setBool(_blurCoverInAppKey, state.blurCoverInApp);
      await prefs.setBool(_maskTitleKey, state.maskTitle);
      await prefs.setString(_customTitleKey, state.customTitle);
    } catch (_) {
      // ignore
    }
  }

  Future<void> _savePreference(String key, bool value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(key, value);
    } catch (e) {
      // 保存失败时静默处理
    }
  }
}

/// 防社死设置提供者
final privacyModeSettingsProvider =
    StateNotifierProvider<PrivacyModeSettingsNotifier, PrivacyModeSettings>(
        (ref) {
  return PrivacyModeSettingsNotifier();
});

class AudioHapticsSettings {
  static const double minIntensity = 0.2;
  static const double maxIntensity = 1.0;
  static const double defaultIntensity = 0.85;

  final bool enabled;
  final double intensity;

  const AudioHapticsSettings({
    this.enabled = false,
    this.intensity = defaultIntensity,
  });

  AudioHapticsSettings copyWith({
    bool? enabled,
    double? intensity,
  }) {
    return AudioHapticsSettings(
      enabled: enabled ?? this.enabled,
      intensity: normalizeIntensity(intensity ?? this.intensity),
    );
  }

  static double normalizeIntensity(double value) {
    return value.clamp(minIntensity, maxIntensity).toDouble();
  }
}

class AudioHapticsSettingsNotifier extends StateNotifier<AudioHapticsSettings> {
  static const String _enabledKey = 'audio_haptics_enabled';
  static const String _intensityKey = 'audio_haptics_intensity';
  bool _changedLocally = false;

  AudioHapticsSettingsNotifier() : super(const AudioHapticsSettings()) {
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (!mounted || _changedLocally) return;
      if (!mounted) return;
      state = AudioHapticsSettings(
        enabled: prefs.getBool(_enabledKey) ?? false,
        intensity: AudioHapticsSettings.normalizeIntensity(
          prefs.getDouble(_intensityKey) ??
              AudioHapticsSettings.defaultIntensity,
        ),
      );
    } catch (_) {
      if (!mounted) return;
      state = const AudioHapticsSettings();
    }
  }

  Future<void> setEnabled(bool enabled) async {
    _changedLocally = true;
    state = state.copyWith(enabled: enabled);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_enabledKey, enabled);
    } catch (_) {
      // ignore
    }
  }

  Future<void> setIntensity(double intensity) async {
    _changedLocally = true;
    final normalized = AudioHapticsSettings.normalizeIntensity(intensity);
    state = state.copyWith(intensity: normalized);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(_intensityKey, normalized);
    } catch (_) {
      // ignore
    }
  }

  Future<void> resetToDefault() async {
    _changedLocally = true;
    state = const AudioHapticsSettings();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_enabledKey, state.enabled);
      await prefs.setDouble(_intensityKey, state.intensity);
    } catch (_) {
      // ignore
    }
  }
}

final audioHapticsSettingsProvider =
    StateNotifierProvider<AudioHapticsSettingsNotifier, AudioHapticsSettings>(
        (ref) {
  return AudioHapticsSettingsNotifier();
});

class AudioGainSettingsNotifier extends StateNotifier<AudioGainSettings> {
  static const String preferenceKey = 'global_audio_gain_db';
  bool _changedLocally = false;

  AudioGainSettingsNotifier() : super(const AudioGainSettings()) {
    _loadPreference();
  }

  Future<void> _loadPreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (!mounted || _changedLocally) return;
      state = AudioGainSettings(
        decibels: AudioGainSettings.normalize(
          prefs.getDouble(preferenceKey) ?? AudioGainSettings.defaultDecibels,
        ),
      );
    } catch (_) {
      if (!mounted || _changedLocally) return;
      state = const AudioGainSettings();
    }
  }

  Future<void> setDecibels(double decibels) async {
    _changedLocally = true;
    state = AudioGainSettings(
      decibels: AudioGainSettings.normalize(decibels),
    );
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(preferenceKey, state.decibels);
    } catch (_) {
      // Keep the in-memory setting when persistence is unavailable.
    }
  }

  Future<void> resetToDefault() {
    return setDecibels(AudioGainSettings.defaultDecibels);
  }
}

final audioGainSettingsProvider =
    StateNotifierProvider<AudioGainSettingsNotifier, AudioGainSettings>((ref) {
  return AudioGainSettingsNotifier();
});

/// 分页大小设置
class PageSizeNotifier extends StateNotifier<int> {
  static const String _preferenceKey = 'page_size_preference';
  static const int defaultSize = 40;

  PageSizeNotifier() : super(defaultSize) {
    _loadPreference();
  }

  Future<void> _loadPreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedValue = prefs.getInt(_preferenceKey);
      if (savedValue != null && [20, 40, 60, 100].contains(savedValue)) {
        state = savedValue;
      }
    } catch (e) {
      state = defaultSize;
    }
  }

  Future<void> updatePageSize(int size) async {
    if (![20, 40, 60, 100].contains(size)) return;
    state = size;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_preferenceKey, size);
    } catch (e) {
      // ignore
    }
  }
}

/// 分页大小提供者
final pageSizeProvider = StateNotifierProvider<PageSizeNotifier, int>((ref) {
  return PageSizeNotifier();
});

/// 屏幕常亮设置
class KeepScreenAwakeNotifier extends StateNotifier<bool> {
  static const String preferenceKey = 'keep_screen_awake_enabled';

  KeepScreenAwakeNotifier() : super(false) {
    _loadPreference();
  }

  Future<void> _loadPreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (!mounted) return;
      state = prefs.getBool(preferenceKey) ?? false;
    } catch (e) {
      if (!mounted) return;
      state = false;
    }
  }

  Future<void> setEnabled(bool enabled) async {
    state = enabled;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(preferenceKey, enabled);
    } catch (e) {
      // ignore
    }
  }
}

final keepScreenAwakeProvider =
    StateNotifierProvider<KeepScreenAwakeNotifier, bool>((ref) {
  return KeepScreenAwakeNotifier();
});

/// 默认排序设置状态
class DefaultSortState {
  final SortOrder order;
  final SortDirection direction;

  const DefaultSortState({
    this.order = SortOrder.release,
    this.direction = SortDirection.desc,
  });
}

/// 音频直通模式设置
class AudioPassthroughNotifier extends StateNotifier<bool> {
  static const String _preferenceKey = 'audio_passthrough_enabled';

  AudioPassthroughNotifier() : super(false) {
    _loadPreference();
  }

  Future<void> _loadPreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      state = prefs.getBool(_preferenceKey) ?? false;
    } catch (e) {
      state = false;
    }
  }

  Future<void> toggle(bool enabled) async {
    state = enabled;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_preferenceKey, enabled);
    } catch (e) {
      // ignore
    }
  }
}

/// 音频直通模式提供者
final audioPassthroughProvider =
    StateNotifierProvider<AudioPassthroughNotifier, bool>((ref) {
  return AudioPassthroughNotifier();
});

/// 默认排序设置
class DefaultSortNotifier extends StateNotifier<DefaultSortState> {
  static const String _orderKey = 'default_sort_order';
  static const String _directionKey = 'default_sort_direction';

  DefaultSortNotifier() : super(const DefaultSortState()) {
    _loadPreference();
  }

  Future<void> _loadPreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final orderValue = prefs.getString(_orderKey);
      final directionValue = prefs.getString(_directionKey);

      SortOrder order = SortOrder.release;
      if (orderValue != null) {
        order = SortOrder.values.firstWhere(
          (e) => e.value == orderValue,
          orElse: () => SortOrder.release,
        );
      }

      SortDirection direction = SortDirection.desc;
      if (directionValue != null) {
        direction = SortDirection.values.firstWhere(
          (e) => e.value == directionValue,
          orElse: () => SortDirection.desc,
        );
      }

      state = DefaultSortState(order: order, direction: direction);
    } catch (e) {
      // ignore
    }
  }

  Future<void> updateDefaultSort(
      SortOrder order, SortDirection direction) async {
    state = DefaultSortState(order: order, direction: direction);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_orderKey, order.value);
      await prefs.setString(_directionKey, direction.value);
    } catch (e) {
      // ignore
    }
  }
}

/// 默认排序提供者
final defaultSortProvider =
    StateNotifierProvider<DefaultSortNotifier, DefaultSortState>((ref) {
  return DefaultSortNotifier();
});

/// 屏蔽列表状态
class BlockedItemsState {
  final List<String> tags;
  final List<String> cvs;
  final List<String> circles;

  const BlockedItemsState({
    this.tags = const [],
    this.cvs = const [],
    this.circles = const [],
  });

  BlockedItemsState copyWith({
    List<String>? tags,
    List<String>? cvs,
    List<String>? circles,
  }) {
    return BlockedItemsState(
      tags: tags ?? this.tags,
      cvs: cvs ?? this.cvs,
      circles: circles ?? this.circles,
    );
  }
}

/// 屏蔽列表通知器
class BlockedItemsNotifier extends StateNotifier<BlockedItemsState> {
  static const String _tagsKey = 'blocked_tags';
  static const String _cvsKey = 'blocked_cvs';
  static const String _circlesKey = 'blocked_circles';

  BlockedItemsNotifier() : super(const BlockedItemsState()) {
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final tags = prefs.getStringList(_tagsKey) ?? [];
      final cvs = prefs.getStringList(_cvsKey) ?? [];
      final circles = prefs.getStringList(_circlesKey) ?? [];
      state = BlockedItemsState(tags: tags, cvs: cvs, circles: circles);
    } catch (e) {
      // ignore
    }
  }

  Future<void> _savePreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_tagsKey, state.tags);
      await prefs.setStringList(_cvsKey, state.cvs);
      await prefs.setStringList(_circlesKey, state.circles);
    } catch (e) {
      // ignore
    }
  }

  Future<void> addTag(String tag) async {
    if (!state.tags.contains(tag)) {
      state = state.copyWith(tags: [...state.tags, tag]);
      await _savePreferences();
    }
  }

  Future<void> removeTag(String tag) async {
    state = state.copyWith(tags: state.tags.where((t) => t != tag).toList());
    await _savePreferences();
  }

  Future<void> addCv(String cv) async {
    if (!state.cvs.contains(cv)) {
      state = state.copyWith(cvs: [...state.cvs, cv]);
      await _savePreferences();
    }
  }

  Future<void> removeCv(String cv) async {
    state = state.copyWith(cvs: state.cvs.where((c) => c != cv).toList());
    await _savePreferences();
  }

  Future<void> addCircle(String circle) async {
    if (!state.circles.contains(circle)) {
      state = state.copyWith(circles: [...state.circles, circle]);
      await _savePreferences();
    }
  }

  Future<void> removeCircle(String circle) async {
    state = state.copyWith(
        circles: state.circles.where((c) => c != circle).toList());
    await _savePreferences();
  }
}

/// 屏蔽列表提供者
final blockedItemsProvider =
    StateNotifierProvider<BlockedItemsNotifier, BlockedItemsState>((ref) {
  return BlockedItemsNotifier();
});
