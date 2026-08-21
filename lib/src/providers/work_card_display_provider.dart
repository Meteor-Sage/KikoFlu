import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum WorkCardSize {
  normal('normal', 0),
  large('large', 1),
  extraLarge('extra_large', 2);

  const WorkCardSize(this.value, this.columnReduction);

  final String value;
  final int columnReduction;

  int applyToCrossAxisCount(
    int crossAxisCount, {
    int minCrossAxisCount = 1,
  }) {
    final minCount = minCrossAxisCount.clamp(1, crossAxisCount).toInt();
    return (crossAxisCount - columnReduction)
        .clamp(minCount, crossAxisCount)
        .toInt();
  }

  static WorkCardSize fromValue(String? value) {
    return WorkCardSize.values.firstWhere(
      (size) => size.value == value,
      orElse: () => WorkCardSize.normal,
    );
  }
}

enum WorkCardFontScale {
  normal('normal', 1.0),
  large('large', 1.12),
  extraLarge('extra_large', 1.24);

  const WorkCardFontScale(this.value, this.multiplier);

  final String value;
  final double multiplier;

  double apply(double fontSize) => fontSize * multiplier;

  static WorkCardFontScale fromValue(String? value) {
    return WorkCardFontScale.values.firstWhere(
      (scale) => scale.value == value,
      orElse: () => WorkCardFontScale.normal,
    );
  }
}

/// 作品卡片显示设置
class WorkCardDisplaySettings {
  final bool showRating;
  final bool showPrice;
  final bool showSales;
  final bool showReleaseDate;
  final bool showCircle;
  final bool showDuration;
  final bool showSubtitleTag;
  final bool showAgeRating;
  final WorkCardSize cardSize;
  final WorkCardFontScale fontScale;

  const WorkCardDisplaySettings({
    this.showRating = true,
    this.showPrice = true,
    this.showSales = true,
    this.showReleaseDate = true,
    this.showCircle = true,
    this.showDuration = false,
    this.showSubtitleTag = true,
    this.showAgeRating = false,
    this.cardSize = WorkCardSize.normal,
    this.fontScale = WorkCardFontScale.normal,
  });

  WorkCardDisplaySettings copyWith({
    bool? showRating,
    bool? showPrice,
    bool? showSales,
    bool? showReleaseDate,
    bool? showCircle,
    bool? showDuration,
    bool? showSubtitleTag,
    bool? showAgeRating,
    WorkCardSize? cardSize,
    WorkCardFontScale? fontScale,
  }) {
    return WorkCardDisplaySettings(
      showRating: showRating ?? this.showRating,
      showPrice: showPrice ?? this.showPrice,
      showSales: showSales ?? this.showSales,
      showReleaseDate: showReleaseDate ?? this.showReleaseDate,
      showCircle: showCircle ?? this.showCircle,
      showDuration: showDuration ?? this.showDuration,
      showSubtitleTag: showSubtitleTag ?? this.showSubtitleTag,
      showAgeRating: showAgeRating ?? this.showAgeRating,
      cardSize: cardSize ?? this.cardSize,
      fontScale: fontScale ?? this.fontScale,
    );
  }

  int applyCardSize(
    int crossAxisCount, {
    int minCrossAxisCount = 1,
  }) {
    return cardSize.applyToCrossAxisCount(
      crossAxisCount,
      minCrossAxisCount: minCrossAxisCount,
    );
  }

  double scaleFontSize(double fontSize) {
    return fontScale.apply(fontSize);
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
  static const String _keyDuration = '${_keyPrefix}duration';
  static const String _keySubtitleTag = '${_keyPrefix}subtitle_tag';
  static const String keyAgeRating = '${_keyPrefix}age_rating';
  static const String keyCardSize = '${_keyPrefix}card_size';
  static const String keyFontScale = '${_keyPrefix}font_scale';

  final Set<String> _dirtyKeys = {};

  WorkCardDisplayNotifier() : super(const WorkCardDisplaySettings()) {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (!mounted) return;

      final loadedSettings = WorkCardDisplaySettings(
        showRating: prefs.getBool(_keyRating) ?? true,
        showPrice: prefs.getBool(_keyPrice) ?? true,
        showSales: prefs.getBool(_keySales) ?? true,
        showReleaseDate: prefs.getBool(_keyReleaseDate) ?? true,
        showCircle: prefs.getBool(_keyCircle) ?? true,
        showDuration: prefs.getBool(_keyDuration) ?? false,
        showSubtitleTag: prefs.getBool(_keySubtitleTag) ?? true,
        showAgeRating: prefs.getBool(keyAgeRating) ?? false,
        cardSize: WorkCardSize.fromValue(prefs.getString(keyCardSize)),
        fontScale: WorkCardFontScale.fromValue(prefs.getString(keyFontScale)),
      );

      if (_dirtyKeys.isEmpty) {
        state = loadedSettings;
        return;
      }

      state = loadedSettings.copyWith(
        showRating: _dirtyKeys.contains(_keyRating) ? state.showRating : null,
        showPrice: _dirtyKeys.contains(_keyPrice) ? state.showPrice : null,
        showSales: _dirtyKeys.contains(_keySales) ? state.showSales : null,
        showReleaseDate:
            _dirtyKeys.contains(_keyReleaseDate) ? state.showReleaseDate : null,
        showCircle: _dirtyKeys.contains(_keyCircle) ? state.showCircle : null,
        showDuration:
            _dirtyKeys.contains(_keyDuration) ? state.showDuration : null,
        showSubtitleTag:
            _dirtyKeys.contains(_keySubtitleTag) ? state.showSubtitleTag : null,
        showAgeRating:
            _dirtyKeys.contains(keyAgeRating) ? state.showAgeRating : null,
        cardSize: _dirtyKeys.contains(keyCardSize) ? state.cardSize : null,
        fontScale: _dirtyKeys.contains(keyFontScale) ? state.fontScale : null,
      );
      _dirtyKeys.clear();
    } catch (e) {
      // 加载失败，使用默认值
    }
  }

  void _applyLocalChange(WorkCardDisplaySettings nextState, String key) {
    _dirtyKeys.add(key);
    state = nextState;
  }

  Future<void> toggleRating() async {
    _applyLocalChange(
      state.copyWith(showRating: !state.showRating),
      _keyRating,
    );
    await _saveSettings();
  }

  Future<void> togglePrice() async {
    _applyLocalChange(
      state.copyWith(showPrice: !state.showPrice),
      _keyPrice,
    );
    await _saveSettings();
  }

  Future<void> toggleSales() async {
    _applyLocalChange(
      state.copyWith(showSales: !state.showSales),
      _keySales,
    );
    await _saveSettings();
  }

  Future<void> toggleReleaseDate() async {
    _applyLocalChange(
      state.copyWith(showReleaseDate: !state.showReleaseDate),
      _keyReleaseDate,
    );
    await _saveSettings();
  }

  Future<void> toggleCircle() async {
    _applyLocalChange(
      state.copyWith(showCircle: !state.showCircle),
      _keyCircle,
    );
    await _saveSettings();
  }

  Future<void> toggleDuration() async {
    _applyLocalChange(
      state.copyWith(showDuration: !state.showDuration),
      _keyDuration,
    );
    await _saveSettings();
  }

  Future<void> toggleSubtitleTag() async {
    _applyLocalChange(
      state.copyWith(showSubtitleTag: !state.showSubtitleTag),
      _keySubtitleTag,
    );
    await _saveSettings();
  }

  Future<void> toggleAgeRating() async {
    _applyLocalChange(
      state.copyWith(showAgeRating: !state.showAgeRating),
      keyAgeRating,
    );
    await _saveSettings();
  }

  Future<void> updateCardSize(WorkCardSize cardSize) async {
    _applyLocalChange(state.copyWith(cardSize: cardSize), keyCardSize);
    await _saveSettings();
  }

  Future<void> updateFontScale(WorkCardFontScale fontScale) async {
    _applyLocalChange(state.copyWith(fontScale: fontScale), keyFontScale);
    await _saveSettings();
  }

  Future<void> resetToDefault() async {
    _dirtyKeys.addAll({
      _keyRating,
      _keyPrice,
      _keySales,
      _keyReleaseDate,
      _keyCircle,
      _keyDuration,
      _keySubtitleTag,
      keyAgeRating,
      keyCardSize,
      keyFontScale,
    });
    state = const WorkCardDisplaySettings();
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
      await prefs.setBool(_keyDuration, state.showDuration);
      await prefs.setBool(_keySubtitleTag, state.showSubtitleTag);
      await prefs.setBool(keyAgeRating, state.showAgeRating);
      await prefs.setString(keyCardSize, state.cardSize.value);
      await prefs.setString(keyFontScale, state.fontScale.value);
    } catch (e) {
      // 保存失败时静默处理
    }
  }
}

final workCardDisplayProvider =
    StateNotifierProvider<WorkCardDisplayNotifier, WorkCardDisplaySettings>(
  (ref) => WorkCardDisplayNotifier(),
);
