import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 作品卡片显示设置
class WorkCardDisplaySettings {
  final bool showRating;
  final bool showPrice;
  final bool showSales;
  final bool showReleaseDate;
  final bool showCircle;

  const WorkCardDisplaySettings({
    this.showRating = true,
    this.showPrice = true,
    this.showSales = true,
    this.showReleaseDate = true,
    this.showCircle = true,
  });

  WorkCardDisplaySettings copyWith({
    bool? showRating,
    bool? showPrice,
    bool? showSales,
    bool? showReleaseDate,
    bool? showCircle,
  }) {
    return WorkCardDisplaySettings(
      showRating: showRating ?? this.showRating,
      showPrice: showPrice ?? this.showPrice,
      showSales: showSales ?? this.showSales,
      showReleaseDate: showReleaseDate ?? this.showReleaseDate,
      showCircle: showCircle ?? this.showCircle,
    );
  }
}

/// 作品卡片显示设置 Provider
class WorkCardDisplayNotifier extends StateNotifier<WorkCardDisplaySettings> {
  static const String _keyPrefix = 'work_card_display_';
  static const String _keyRating = '${_keyPrefix}rating';
  static const String _keyPrice = '${_keyPrefix}price';
  static const String _keySales = '${_keyPrefix}sales';
  static const String _keyReleaseDate = '${_keyPrefix}release_date';
  static const String _keyCircle = '${_keyPrefix}circle';

  WorkCardDisplayNotifier() : super(const WorkCardDisplaySettings()) {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      state = WorkCardDisplaySettings(
        showRating: prefs.getBool(_keyRating) ?? true,
        showPrice: prefs.getBool(_keyPrice) ?? true,
        showSales: prefs.getBool(_keySales) ?? true,
        showReleaseDate: prefs.getBool(_keyReleaseDate) ?? true,
        showCircle: prefs.getBool(_keyCircle) ?? true,
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

  Future<void> toggleSales() async {
    state = state.copyWith(showSales: !state.showSales);
    await _saveSettings();
  }

  Future<void> toggleReleaseDate() async {
    state = state.copyWith(showReleaseDate: !state.showReleaseDate);
    await _saveSettings();
  }

  Future<void> toggleCircle() async {
    state = state.copyWith(showCircle: !state.showCircle);
    await _saveSettings();
  }

  Future<void> _saveSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyRating, state.showRating);
      await prefs.setBool(_keyPrice, state.showPrice);
      await prefs.setBool(_keySales, state.showSales);
      await prefs.setBool(_keyReleaseDate, state.showReleaseDate);
      await prefs.setBool(_keyCircle, state.showCircle);
    } catch (e) {
      // 保存失败时静默处理
    }
  }
}

final workCardDisplayProvider =
    StateNotifierProvider<WorkCardDisplayNotifier, WorkCardDisplaySettings>(
  (ref) => WorkCardDisplayNotifier(),
);
