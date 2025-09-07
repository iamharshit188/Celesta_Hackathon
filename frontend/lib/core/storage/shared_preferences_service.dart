import 'package:shared_preferences/shared_preferences.dart';
import 'package:wpfactcheck/core/error/exceptions.dart';

class SharedPreferencesService {
  static SharedPreferences? _prefs;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  static SharedPreferences get _instance {
    if (_prefs == null) {
      throw CacheException(message: 'SharedPreferences not initialized');
    }
    return _prefs!;
  }

  // String operations
  static Future<bool> setString(String key, String value) async {
    try {
      return await _instance.setString(key, value);
    } catch (e) {
      throw CacheException(message: 'Failed to save string: $e');
    }
  }

  static String? getString(String key, {String? defaultValue}) {
    try {
      return _instance.getString(key) ?? defaultValue;
    } catch (e) {
      throw CacheException(message: 'Failed to get string: $e');
    }
  }

  // Boolean operations
  static Future<bool> setBool(String key, bool value) async {
    try {
      return await _instance.setBool(key, value);
    } catch (e) {
      throw CacheException(message: 'Failed to save boolean: $e');
    }
  }

  static bool getBool(String key, {bool defaultValue = false}) {
    try {
      return _instance.getBool(key) ?? defaultValue;
    } catch (e) {
      throw CacheException(message: 'Failed to get boolean: $e');
    }
  }

  // Integer operations
  static Future<bool> setInt(String key, int value) async {
    try {
      return await _instance.setInt(key, value);
    } catch (e) {
      throw CacheException(message: 'Failed to save integer: $e');
    }
  }

  static int getInt(String key, {int defaultValue = 0}) {
    try {
      return _instance.getInt(key) ?? defaultValue;
    } catch (e) {
      throw CacheException(message: 'Failed to get integer: $e');
    }
  }

  // Double operations
  static Future<bool> setDouble(String key, double value) async {
    try {
      return await _instance.setDouble(key, value);
    } catch (e) {
      throw CacheException(message: 'Failed to save double: $e');
    }
  }

  static double getDouble(String key, {double defaultValue = 0.0}) {
    try {
      return _instance.getDouble(key) ?? defaultValue;
    } catch (e) {
      throw CacheException(message: 'Failed to get double: $e');
    }
  }

  // String list operations
  static Future<bool> setStringList(String key, List<String> value) async {
    try {
      return await _instance.setStringList(key, value);
    } catch (e) {
      throw CacheException(message: 'Failed to save string list: $e');
    }
  }

  static List<String> getStringList(String key, {List<String>? defaultValue}) {
    try {
      return _instance.getStringList(key) ?? defaultValue ?? [];
    } catch (e) {
      throw CacheException(message: 'Failed to get string list: $e');
    }
  }

  // Utility methods
  static bool containsKey(String key) {
    try {
      return _instance.containsKey(key);
    } catch (e) {
      throw CacheException(message: 'Failed to check key existence: $e');
    }
  }

  static Future<bool> remove(String key) async {
    try {
      return await _instance.remove(key);
    } catch (e) {
      throw CacheException(message: 'Failed to remove key: $e');
    }
  }

  static Future<bool> clear() async {
    try {
      return await _instance.clear();
    } catch (e) {
      throw CacheException(message: 'Failed to clear preferences: $e');
    }
  }

  static Set<String> getKeys() {
    try {
      return _instance.getKeys();
    } catch (e) {
      throw CacheException(message: 'Failed to get keys: $e');
    }
  }

  // App-specific convenience methods
  static Future<void> saveLastNewsSync(DateTime timestamp) async {
    await setString('last_news_sync', timestamp.toIso8601String());
  }

  static DateTime? getLastNewsSync() {
    final value = getString('last_news_sync');
    return value != null ? DateTime.tryParse(value) : null;
  }

  static Future<void> saveSelectedNewsCategory(String category) async {
    await setString('selected_news_category', category);
  }

  static String getSelectedNewsCategory() {
    return getString('selected_news_category', defaultValue: 'general') ?? 'general';
  }

  static Future<void> saveAppLaunchCount(int count) async {
    await setInt('app_launch_count', count);
  }

  static int getAppLaunchCount() {
    return getInt('app_launch_count');
  }

  static Future<void> incrementAppLaunchCount() async {
    final currentCount = getAppLaunchCount();
    await saveAppLaunchCount(currentCount + 1);
  }

  static Future<void> saveFirstLaunchDate(DateTime date) async {
    await setString('first_launch_date', date.toIso8601String());
  }

  static DateTime? getFirstLaunchDate() {
    final value = getString('first_launch_date');
    return value != null ? DateTime.tryParse(value) : null;
  }
}
