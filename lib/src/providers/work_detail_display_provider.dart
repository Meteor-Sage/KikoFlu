import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 作品详情页显示设置
class WorkDetailDisplaySettings {
  final bool showRating;
  final bool showPrice;
  final bool showDuration;
  final bool showSales;
  final bool showExternalLinks;
  final bool showReleaseDate;
  final bool showTranslateButton;
  final bool showSubtitleTag;
  final bool showAgeRating;
  final bool showRecommendations;

  const WorkDetailDisplaySettings({
    this.showRating = true,
    this.showPrice = true,
    this.showDuration = true,
    this.showSales = true,
    this.showExternalLinks = true,
    this.showReleaseDate = true,
    this.showTranslateButton = true,
    this.showSubtitleTag = true,
    this.showAgeRating = false,
    this.showRecommendations = true,
  });

  WorkDetailDisplaySettings copyWith({
    bool? showRating,
    bool? showPrice,
    bool? showDuration,
    bool? showSales,
    bool? showExternalLinks,
    bool? showReleaseDate,
    bool? showTranslateButton,
    bool? showSubtitleTag,
    bool? showAgeRating,
    bool? showRecommendations,
  }) {
    return WorkDetailDisplaySettings(
      showRating: showRating ?? this.showRating,
      showPrice: showPrice ?? this.showPrice,
      showDuration: showDuration ?? this.showDuration,
      showSales: showSales ?? this.showSales,
      showExternalLinks: showExternalLinks ?? this.showExternalLinks,
      showReleaseDate: showReleaseDate ?? this.showReleaseDate,
      showTranslateButton: showTranslateButton ?? this.showTranslateButton,
      showSubtitleTag: showSubtitleTag ?? this.showSubtitleTag,
      showAgeRating: showAgeRating ?? this.showAgeRating,
      showRecommendations: showRecommendations ?? this.showRecommendations,
    );
  }
}

/// 作品详情页显示设置 Provider
class WorkDetailDisplayNotifier
    extends StateNotifier<WorkDetailDisplaySettings> {
  static const String _keyPrefix = 'work_detail_display_';
  static const String _keyRating = '${_keyPrefix}rating';
  static const String _keyPrice = '${_keyPrefix}price';
  static const String _keyDuration = '${_keyPrefix}duration';
  static const String _keySales = '${_keyPrefix}sales';
  static const String _keyExternalLinks = '${_keyPrefix}external_links';
  static const String _keyReleaseDate = '${_keyPrefix}release_date';
  static const String _keyTranslateButton = '${_keyPrefix}translate_button';
  static const String _keySubtitleTag = '${_keyPrefix}subtitle_tag';
  static const String keyAgeRating = '${_keyPrefix}age_rating';
  static const String _keyRecommendations = '${_keyPrefix}recommendations';
  bool _changedLocally = false;

  WorkDetailDisplayNotifier() : super(const WorkDetailDisplaySettings()) {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (!mounted || _changedLocally) return;
      state = WorkDetailDisplaySettings(
        showRating: prefs.getBool(_keyRating) ?? true,
        showPrice: prefs.getBool(_keyPrice) ?? true,
        showDuration: prefs.getBool(_keyDuration) ?? true,
        showSales: prefs.getBool(_keySales) ?? true,
        showExternalLinks: prefs.getBool(_keyExternalLinks) ?? true,
        showReleaseDate: prefs.getBool(_keyReleaseDate) ?? true,
        showTranslateButton: prefs.getBool(_keyTranslateButton) ?? true,
        showSubtitleTag: prefs.getBool(_keySubtitleTag) ?? true,
        showAgeRating: prefs.getBool(keyAgeRating) ?? false,
        showRecommendations: prefs.getBool(_keyRecommendations) ?? true,
      );
    } catch (e) {
      // 加载失败，使用默认值
    }
  }

  Future<void> toggleRating() async {
    _applyLocalChange(state.copyWith(showRating: !state.showRating));
    await _saveSettings();
  }

  Future<void> togglePrice() async {
    _applyLocalChange(state.copyWith(showPrice: !state.showPrice));
    await _saveSettings();
  }

  Future<void> toggleDuration() async {
    _applyLocalChange(state.copyWith(showDuration: !state.showDuration));
    await _saveSettings();
  }

  Future<void> toggleSales() async {
    _applyLocalChange(state.copyWith(showSales: !state.showSales));
    await _saveSettings();
  }

  Future<void> toggleExternalLinks() async {
    _applyLocalChange(
      state.copyWith(showExternalLinks: !state.showExternalLinks),
    );
    await _saveSettings();
  }

  Future<void> toggleReleaseDate() async {
    _applyLocalChange(state.copyWith(showReleaseDate: !state.showReleaseDate));
    await _saveSettings();
  }

  Future<void> toggleTranslateButton() async {
    _applyLocalChange(
      state.copyWith(showTranslateButton: !state.showTranslateButton),
    );
    await _saveSettings();
  }

  Future<void> toggleSubtitleTag() async {
    _applyLocalChange(state.copyWith(showSubtitleTag: !state.showSubtitleTag));
    await _saveSettings();
  }

  Future<void> toggleAgeRating() async {
    _applyLocalChange(state.copyWith(showAgeRating: !state.showAgeRating));
    await _saveSettings();
  }

  Future<void> toggleRecommendations() async {
    _applyLocalChange(
      state.copyWith(showRecommendations: !state.showRecommendations),
    );
    await _saveSettings();
  }

  Future<void> resetToDefault() async {
    _applyLocalChange(const WorkDetailDisplaySettings());
    await _saveSettings();
  }

  void _applyLocalChange(WorkDetailDisplaySettings nextState) {
    _changedLocally = true;
    state = nextState;
  }

  Future<void> _saveSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyRating, state.showRating);
      await prefs.setBool(_keyPrice, state.showPrice);
      await prefs.setBool(_keyDuration, state.showDuration);
      await prefs.setBool(_keySales, state.showSales);
      await prefs.setBool(_keyExternalLinks, state.showExternalLinks);
      await prefs.setBool(_keyReleaseDate, state.showReleaseDate);
      await prefs.setBool(_keyTranslateButton, state.showTranslateButton);
      await prefs.setBool(_keySubtitleTag, state.showSubtitleTag);
      await prefs.setBool(keyAgeRating, state.showAgeRating);
      await prefs.setBool(_keyRecommendations, state.showRecommendations);
    } catch (e) {
      // 保存失败时静默处理
    }
  }
}

final workDetailDisplayProvider =
    StateNotifierProvider<WorkDetailDisplayNotifier, WorkDetailDisplaySettings>(
  (ref) => WorkDetailDisplayNotifier(),
);
