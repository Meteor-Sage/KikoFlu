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

  const WorkDetailDisplaySettings({
    this.showRating = true,
    this.showPrice = true,
    this.showDuration = true,
    this.showSales = true,
    this.showExternalLinks = true,
    this.showReleaseDate = true,
    this.showTranslateButton = true,
  });

  WorkDetailDisplaySettings copyWith({
    bool? showRating,
    bool? showPrice,
    bool? showDuration,
    bool? showSales,
    bool? showExternalLinks,
    bool? showReleaseDate,
    bool? showTranslateButton,
  }) {
    return WorkDetailDisplaySettings(
      showRating: showRating ?? this.showRating,
      showPrice: showPrice ?? this.showPrice,
      showDuration: showDuration ?? this.showDuration,
      showSales: showSales ?? this.showSales,
      showExternalLinks: showExternalLinks ?? this.showExternalLinks,
      showReleaseDate: showReleaseDate ?? this.showReleaseDate,
      showTranslateButton: showTranslateButton ?? this.showTranslateButton,
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

  WorkDetailDisplayNotifier() : super(const WorkDetailDisplaySettings()) {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      state = WorkDetailDisplaySettings(
        showRating: prefs.getBool(_keyRating) ?? true,
        showPrice: prefs.getBool(_keyPrice) ?? true,
        showDuration: prefs.getBool(_keyDuration) ?? true,
        showSales: prefs.getBool(_keySales) ?? true,
        showExternalLinks: prefs.getBool(_keyExternalLinks) ?? true,
        showReleaseDate: prefs.getBool(_keyReleaseDate) ?? true,
        showTranslateButton: prefs.getBool(_keyTranslateButton) ?? true,
      );
    } catch (e) {
      // 加载失败，使用默认值
    }
  }

  Future<void> toggleRating() async {
    state = state.copyWith(showRating: !state.showRating);
    await _saveSettings();
  }

  Future<void> togglePrice() async {
    state = state.copyWith(showPrice: !state.showPrice);
    await _saveSettings();
  }

  Future<void> toggleDuration() async {
    state = state.copyWith(showDuration: !state.showDuration);
    await _saveSettings();
  }

  Future<void> toggleSales() async {
    state = state.copyWith(showSales: !state.showSales);
    await _saveSettings();
  }

  Future<void> toggleExternalLinks() async {
    state = state.copyWith(showExternalLinks: !state.showExternalLinks);
    await _saveSettings();
  }

  Future<void> toggleReleaseDate() async {
    state = state.copyWith(showReleaseDate: !state.showReleaseDate);
    await _saveSettings();
  }

  Future<void> toggleTranslateButton() async {
    state = state.copyWith(showTranslateButton: !state.showTranslateButton);
    await _saveSettings();
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
    } catch (e) {
      // 保存失败时静默处理
    }
  }
}

final workDetailDisplayProvider =
    StateNotifierProvider<WorkDetailDisplayNotifier, WorkDetailDisplaySettings>(
  (ref) => WorkDetailDisplayNotifier(),
);
