import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:wpfactcheck/core/constants/app_constants.dart';
import 'package:wpfactcheck/core/error/exceptions.dart';

class SecureStorageService {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  // User data
  Future<void> saveUserName(String name) async {
    try {
      await _storage.write(key: AppConstants.userNameKey, value: name);
    } catch (e) {
      throw CacheException(message: 'Failed to save user name: $e');
    }
  }

  Future<String?> getUserName() async {
    try {
      return await _storage.read(key: AppConstants.userNameKey);
    } catch (e) {
      throw CacheException(message: 'Failed to get user name: $e');
    }
  }

  // Theme preference
  Future<void> saveThemeMode(String themeMode) async {
    try {
      await _storage.write(key: AppConstants.themeKey, value: themeMode);
    } catch (e) {
      throw CacheException(message: 'Failed to save theme mode: $e');
    }
  }

  Future<String?> getThemeMode() async {
    try {
      return await _storage.read(key: AppConstants.themeKey);
    } catch (e) {
      throw CacheException(message: 'Failed to get theme mode: $e');
    }
  }

  // Onboarding status
  Future<void> setOnboardingCompleted(bool completed) async {
    try {
      await _storage.write(
        key: AppConstants.onboardingKey, 
        value: completed.toString(),
      );
    } catch (e) {
      throw CacheException(message: 'Failed to save onboarding status: $e');
    }
  }

  Future<bool> isOnboardingCompleted() async {
    try {
      final value = await _storage.read(key: AppConstants.onboardingKey);
      return value == 'true';
    } catch (e) {
      throw CacheException(message: 'Failed to get onboarding status: $e');
    }
  }

  // API keys and sensitive data
  Future<void> saveApiKey(String key, String value) async {
    try {
      await _storage.write(key: key, value: value);
    } catch (e) {
      throw CacheException(message: 'Failed to save API key: $e');
    }
  }

  Future<String?> getApiKey(String key) async {
    try {
      return await _storage.read(key: key);
    } catch (e) {
      throw CacheException(message: 'Failed to get API key: $e');
    }
  }

  // Last sync timestamp
  Future<void> saveLastSyncTimestamp(DateTime timestamp) async {
    try {
      await _storage.write(
        key: AppConstants.lastSyncKey,
        value: timestamp.toIso8601String(),
      );
    } catch (e) {
      throw CacheException(message: 'Failed to save sync timestamp: $e');
    }
  }

  Future<DateTime?> getLastSyncTimestamp() async {
    try {
      final value = await _storage.read(key: AppConstants.lastSyncKey);
      return value != null ? DateTime.tryParse(value) : null;
    } catch (e) {
      throw CacheException(message: 'Failed to get sync timestamp: $e');
    }
  }

  // Model hash for integrity check
  Future<void> saveModelHash(String hash) async {
    try {
      await _storage.write(key: AppConstants.modelHashKey, value: hash);
    } catch (e) {
      throw CacheException(message: 'Failed to save model hash: $e');
    }
  }

  Future<String?> getModelHash() async {
    try {
      return await _storage.read(key: AppConstants.modelHashKey);
    } catch (e) {
      throw CacheException(message: 'Failed to get model hash: $e');
    }
  }

  // Generic methods
  Future<void> saveString(String key, String value) async {
    try {
      await _storage.write(key: key, value: value);
    } catch (e) {
      throw CacheException(message: 'Failed to save string: $e');
    }
  }

  Future<String?> getString(String key) async {
    try {
      return await _storage.read(key: key);
    } catch (e) {
      throw CacheException(message: 'Failed to get string: $e');
    }
  }

  Future<void> saveBool(String key, bool value) async {
    try {
      await _storage.write(key: key, value: value.toString());
    } catch (e) {
      throw CacheException(message: 'Failed to save boolean: $e');
    }
  }

  Future<bool?> getBool(String key) async {
    try {
      final value = await _storage.read(key: key);
      return value != null ? value == 'true' : null;
    } catch (e) {
      throw CacheException(message: 'Failed to get boolean: $e');
    }
  }

  Future<void> saveInt(String key, int value) async {
    try {
      await _storage.write(key: key, value: value.toString());
    } catch (e) {
      throw CacheException(message: 'Failed to save integer: $e');
    }
  }

  Future<int?> getInt(String key) async {
    try {
      final value = await _storage.read(key: key);
      return value != null ? int.tryParse(value) : null;
    } catch (e) {
      throw CacheException(message: 'Failed to get integer: $e');
    }
  }

  // Utility methods
  Future<bool> containsKey(String key) async {
    try {
      return await _storage.containsKey(key: key);
    } catch (e) {
      throw CacheException(message: 'Failed to check key existence: $e');
    }
  }

  Future<void> delete(String key) async {
    try {
      await _storage.delete(key: key);
    } catch (e) {
      throw CacheException(message: 'Failed to delete key: $e');
    }
  }

  Future<void> deleteAll() async {
    try {
      await _storage.deleteAll();
    } catch (e) {
      throw CacheException(message: 'Failed to delete all data: $e');
    }
  }

  Future<Map<String, String>> readAll() async {
    try {
      return await _storage.readAll();
    } catch (e) {
      throw CacheException(message: 'Failed to read all data: $e');
    }
  }
}
