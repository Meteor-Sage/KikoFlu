import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class StorageService {
  static late Box _settingsBox;
  static late Box _userBox;
  static late Box _cacheBox;
  static late SharedPreferences _prefs;

  static Future<void> init() async {
    // Initialize Hive boxes
    _settingsBox = await Hive.openBox('settings');
    _userBox = await Hive.openBox('users');
    _cacheBox = await Hive.openBox('cache');

    // Initialize SharedPreferences
    _prefs = await SharedPreferences.getInstance();
  }

  // Settings
  static Future<void> setSetting(String key, dynamic value) async {
    await _settingsBox.put(key, value);
  }

  static T? getSetting<T>(String key, {T? defaultValue}) {
    return _settingsBox.get(key, defaultValue: defaultValue) as T?;
  }

  static Future<void> removeSetting(String key) async {
    await _settingsBox.delete(key);
  }

  // User data
  static Future<void> setUser(String key, dynamic value) async {
    await _userBox.put(key, value);
  }

  static T? getUser<T>(String key, {T? defaultValue}) {
    return _userBox.get(key, defaultValue: defaultValue) as T?;
  }

  static Future<void> removeUser(String key) async {
    await _userBox.delete(key);
  }

  static List<String> getAllUserKeys() {
    return _userBox.keys.cast<String>().toList();
  }

  // Cache
  static Future<void> setCache(String key, dynamic value) async {
    await _cacheBox.put(key, value);
  }

  static T? getCache<T>(String key, {T? defaultValue}) {
    return _cacheBox.get(key, defaultValue: defaultValue) as T?;
  }

  static Future<void> removeCache(String key) async {
    await _cacheBox.delete(key);
  }

  static Future<void> clearCache() async {
    await _cacheBox.clear();
  }

  // SharedPreferences methods
  static Future<void> setString(String key, String value) async {
    await _prefs.setString(key, value);
  }

  static String? getString(String key) {
    return _prefs.getString(key);
  }

  static Future<void> setBool(String key, bool value) async {
    await _prefs.setBool(key, value);
  }

  static bool? getBool(String key) {
    return _prefs.getBool(key);
  }

  static Future<void> setInt(String key, int value) async {
    await _prefs.setInt(key, value);
  }

  static int? getInt(String key) {
    return _prefs.getInt(key);
  }

  static Future<void> remove(String key) async {
    await _prefs.remove(key);
  }

  static Future<void> clear() async {
    await _prefs.clear();
  }

  // JSON Map methods for complex objects
  static Future<void> setMap(String key, Map<String, dynamic> value) async {
    await _prefs.setString(key, jsonEncode(value));
  }

  static Map<String, dynamic>? getMap(String key) {
    final jsonString = _prefs.getString(key);
    if (jsonString != null) {
      try {
        return jsonDecode(jsonString) as Map<String, dynamic>;
      } catch (e) {
        print('Error decoding JSON for key $key: $e');
        return null;
      }
    }
    return null;
  }
}
