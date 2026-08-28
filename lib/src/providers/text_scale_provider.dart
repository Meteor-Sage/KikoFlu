import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Global application text-size presets. Lyrics, floating lyrics and work-card
/// text keep their existing feature-specific settings and do not use this
/// provider directly.
enum AppTextScale {
  normal('normal', 1.0),
  large('large', 1.12),
  extraLarge('extra_large', 1.24);

  const AppTextScale(this.value, this.multiplier);

  final String value;
  final double multiplier;

  static AppTextScale fromValue(String? value) {
    return AppTextScale.values.firstWhere(
      (scale) => scale.value == value,
      orElse: () => AppTextScale.normal,
    );
  }
}

class AppTextScaleNotifier extends StateNotifier<AppTextScale> {
  static const String preferenceKey = 'app_text_scale';

  AppTextScaleNotifier() : super(AppTextScale.normal) {
    _load();
  }

  bool _changedLocally = false;

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (!mounted || _changedLocally) return;
      state = AppTextScale.fromValue(prefs.getString(preferenceKey));
    } catch (_) {
      // Keep the standard preset when preferences are unavailable.
    }
  }

  Future<void> setScale(AppTextScale scale) async {
    _changedLocally = true;
    state = scale;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(preferenceKey, scale.value);
    } catch (_) {
      // Keep the in-memory value when persistence is unavailable.
    }
  }

  Future<void> resetToDefault() => setScale(AppTextScale.normal);
}

final appTextScaleProvider =
    StateNotifierProvider<AppTextScaleNotifier, AppTextScale>((ref) {
      return AppTextScaleNotifier();
    });
