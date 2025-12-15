import 'package:hive_flutter/hive_flutter.dart';
import '../../core/constants/app_constants.dart';
import '../../core/errors/exceptions.dart';
import '../../core/utils/logger.dart';

/// Storage Service
/// Provides persistent storage using Hive
class StorageService {
  static StorageService? _instance;
  static StorageService get instance => _instance ??= StorageService._();

  StorageService._();

  Box? _cacheBox;
  Box? _settingsBox;

  /// Initialize Hive and open boxes
  Future<void> init() async {
    try {
      await Hive.initFlutter();
      AppLogger.info('Hive initialized', tag: 'StorageService');

      // Open boxes
      _cacheBox = await Hive.openBox(AppConstants.cacheBoxName);
      _settingsBox = await Hive.openBox(AppConstants.settingsBoxName);

      AppLogger.info('Storage boxes opened', tag: 'StorageService');
    } catch (e, stack) {
      AppLogger.error('Failed to initialize storage', tag: 'StorageService', error: e, stackTrace: stack);
      throw CacheException('Failed to initialize storage: $e');
    }
  }

  /// Get cache box
  Box get cacheBox {
    if (_cacheBox == null || !_cacheBox!.isOpen) {
      throw CacheException('Cache box is not initialized');
    }
    return _cacheBox!;
  }

  /// Get settings box
  Box get settingsBox {
    if (_settingsBox == null || !_settingsBox!.isOpen) {
      throw CacheException('Settings box is not initialized');
    }
    return _settingsBox!;
  }

  /// Save data to cache box
  Future<void> saveToCache(String key, dynamic value) async {
    try {
      await cacheBox.put(key, value);
      AppLogger.debug('Saved to cache: $key', tag: 'StorageService');
    } catch (e, stack) {
      AppLogger.error('Failed to save to cache', tag: 'StorageService', error: e, stackTrace: stack);
      throw CacheException('Failed to save to cache: $e');
    }
  }

  /// Get data from cache box
  dynamic getFromCache(String key) {
    try {
      return cacheBox.get(key);
    } catch (e, stack) {
      AppLogger.error('Failed to get from cache', tag: 'StorageService', error: e, stackTrace: stack);
      throw CacheException('Failed to get from cache: $e');
    }
  }

  /// Delete data from cache box
  Future<void> deleteFromCache(String key) async {
    try {
      await cacheBox.delete(key);
      AppLogger.debug('Deleted from cache: $key', tag: 'StorageService');
    } catch (e, stack) {
      AppLogger.error('Failed to delete from cache', tag: 'StorageService', error: e, stackTrace: stack);
      throw CacheException('Failed to delete from cache: $e');
    }
  }

  /// Clear all cache
  Future<void> clearCache() async {
    try {
      await cacheBox.clear();
      AppLogger.info('Cache cleared', tag: 'StorageService');
    } catch (e, stack) {
      AppLogger.error('Failed to clear cache', tag: 'StorageService', error: e, stackTrace: stack);
      throw CacheException('Failed to clear cache: $e');
    }
  }

  /// Save setting
  Future<void> saveSetting(String key, dynamic value) async {
    try {
      await settingsBox.put(key, value);
      AppLogger.debug('Saved setting: $key', tag: 'StorageService');
    } catch (e, stack) {
      AppLogger.error('Failed to save setting', tag: 'StorageService', error: e, stackTrace: stack);
      throw CacheException('Failed to save setting: $e');
    }
  }

  /// Get setting
  dynamic getSetting(String key, {dynamic defaultValue}) {
    try {
      return settingsBox.get(key, defaultValue: defaultValue);
    } catch (e, stack) {
      AppLogger.error('Failed to get setting', tag: 'StorageService', error: e, stackTrace: stack);
      return defaultValue;
    }
  }

  /// Check if key exists in cache
  bool hasKey(String key) {
    return cacheBox.containsKey(key);
  }

  /// Get all keys from cache
  Iterable<dynamic> get allKeys => cacheBox.keys;

  /// Get cache size in bytes (approximate)
  int get cacheSize {
    return cacheBox.length;
  }

  /// Compact cache box (optimize storage)
  Future<void> compactCache() async {
    try {
      await cacheBox.compact();
      AppLogger.info('Cache compacted', tag: 'StorageService');
    } catch (e, stack) {
      AppLogger.error('Failed to compact cache', tag: 'StorageService', error: e, stackTrace: stack);
      throw CacheException('Failed to compact cache: $e');
    }
  }

  /// Close all boxes
  Future<void> close() async {
    try {
      await _cacheBox?.close();
      await _settingsBox?.close();
      AppLogger.info('Storage boxes closed', tag: 'StorageService');
    } catch (e, stack) {
      AppLogger.error('Failed to close storage', tag: 'StorageService', error: e, stackTrace: stack);
    }
  }
}
