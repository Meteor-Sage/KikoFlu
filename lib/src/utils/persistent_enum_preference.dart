import 'package:shared_preferences/shared_preferences.dart';

class PersistentEnumPreference<T extends Enum> {
  PersistentEnumPreference({
    required this.key,
    required List<T> values,
    required this.fallback,
  }) : _values = List.unmodifiable(values);

  final String key;
  final List<T> _values;
  final T fallback;

  bool _changedLocally = false;

  Future<T?> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_changedLocally) return null;

      final savedValue = prefs.getString(key);
      return _values.firstWhere(
        (value) => value.name == savedValue,
        orElse: () => fallback,
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> save(T value) async {
    _changedLocally = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(key, value.name);
    } catch (_) {
      // Keep the in-memory selection when preferences are unavailable.
    }
  }
}
