import 'dart:convert';
import '../../core/utils/logger.dart';
import '../../core/errors/exceptions.dart';
import '../models/cache_data.dart';
import 'storage_service.dart';

/// Cache Manager
/// Manages caching with TTL and provides cache statistics
class CacheManager {
  static CacheManager? _instance;
  static CacheManager get instance => _instance ??= CacheManager._();

  CacheManager._();

  final _storage = StorageService.instance;

  /// Save data to cache with optional TTL
  Future<void> save(
    String key,
    dynamic data, {
    Duration? ttl,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final cacheData = CacheData(
        key: key,
        data: data,
        timestamp: DateTime.now(),
        ttl: ttl,
        metadata: metadata,
      );

      final jsonData = jsonEncode(cacheData.toJson());
      await _storage.saveToCache(key, jsonData);

      AppLogger.debug('Cache saved: $key (TTL: ${ttl?.inSeconds ?? "∞"}s)', tag: 'CacheManager');
    } catch (e, stack) {
      AppLogger.error('Failed to save cache', tag: 'CacheManager', error: e, stackTrace: stack);
      throw CacheException('Failed to save cache: $e');
    }
  }

  /// Get data from cache
  /// Returns null if not found or expired
  Future<dynamic> get(String key, {bool ignoreExpiry = false}) async {
    try {
      final jsonData = _storage.getFromCache(key);
      if (jsonData == null) {
        AppLogger.debug('Cache miss: $key', tag: 'CacheManager');
        return null;
      }

      final cacheData = CacheData.fromJson(jsonDecode(jsonData));

      // Check if expired
      if (!ignoreExpiry && cacheData.isExpired) {
        AppLogger.debug('Cache expired: $key', tag: 'CacheManager');
        await delete(key); // Clean up expired cache
        return null;
      }

      AppLogger.debug(
        'Cache hit: $key (Age: ${cacheData.ageInSeconds}s)',
        tag: 'CacheManager',
      );
      return cacheData.data;
    } catch (e, stack) {
      AppLogger.error('Failed to get cache', tag: 'CacheManager', error: e, stackTrace: stack);
      return null;
    }
  }

  /// Get cache data with metadata
  Future<CacheData?> getCacheData(String key) async {
    try {
      final jsonData = _storage.getFromCache(key);
      if (jsonData == null) return null;

      return CacheData.fromJson(jsonDecode(jsonData));
    } catch (e, stack) {
      AppLogger.error('Failed to get cache data', tag: 'CacheManager', error: e, stackTrace: stack);
      return null;
    }
  }

  /// Delete cache by key
  Future<void> delete(String key) async {
    try {
      await _storage.deleteFromCache(key);
      AppLogger.debug('Cache deleted: $key', tag: 'CacheManager');
    } catch (e, stack) {
      AppLogger.error('Failed to delete cache', tag: 'CacheManager', error: e, stackTrace: stack);
      throw CacheException('Failed to delete cache: $e');
    }
  }

  /// Clear all cache
  Future<void> clearAll() async {
    try {
      await _storage.clearCache();
      AppLogger.info('All cache cleared', tag: 'CacheManager');
    } catch (e, stack) {
      AppLogger.error('Failed to clear all cache', tag: 'CacheManager', error: e, stackTrace: stack);
      throw CacheException('Failed to clear all cache: $e');
    }
  }

  /// Clear only expired cache entries
  Future<int> clearExpired() async {
    try {
      final keys = _storage.allKeys.toList();
      int deletedCount = 0;

      for (final key in keys) {
        final cacheData = await getCacheData(key.toString());
        if (cacheData != null && cacheData.isExpired) {
          await delete(key.toString());
          deletedCount++;
        }
      }

      AppLogger.info('Cleared $deletedCount expired cache entries', tag: 'CacheManager');
      return deletedCount;
    } catch (e, stack) {
      AppLogger.error('Failed to clear expired cache', tag: 'CacheManager', error: e, stackTrace: stack);
      throw CacheException('Failed to clear expired cache: $e');
    }
  }

  /// Check if cache exists and is valid
  Future<bool> isValid(String key) async {
    final cacheData = await getCacheData(key);
    return cacheData != null && cacheData.isValid;
  }

  /// Get cache statistics
  Future<CacheStats> getStats() async {
    try {
      final keys = _storage.allKeys.toList();
      int totalCount = keys.length;
      int validCount = 0;
      int expiredCount = 0;
      int totalSize = 0;

      for (final key in keys) {
        final jsonData = _storage.getFromCache(key.toString());
        if (jsonData != null) {
          totalSize += (jsonData as String).length;

          try {
            final cacheData = CacheData.fromJson(jsonDecode(jsonData));
            if (cacheData.isValid) {
              validCount++;
            } else {
              expiredCount++;
            }
          } catch (_) {
            // Skip invalid entries
          }
        }
      }

      return CacheStats(
        totalCount: totalCount,
        validCount: validCount,
        expiredCount: expiredCount,
        totalSizeBytes: totalSize,
      );
    } catch (e, stack) {
      AppLogger.error('Failed to get cache stats', tag: 'CacheManager', error: e, stackTrace: stack);
      return CacheStats(
        totalCount: 0,
        validCount: 0,
        expiredCount: 0,
        totalSizeBytes: 0,
      );
    }
  }

  /// Get all cache keys
  List<String> getAllKeys() {
    return _storage.allKeys.map((k) => k.toString()).toList();
  }

  /// Compact cache storage
  Future<void> compact() async {
    try {
      await _storage.compactCache();
      AppLogger.info('Cache compacted', tag: 'CacheManager');
    } catch (e, stack) {
      AppLogger.error('Failed to compact cache', tag: 'CacheManager', error: e, stackTrace: stack);
      throw CacheException('Failed to compact cache: $e');
    }
  }

  /// Watch for cache changes
  Stream<dynamic> watch(String key) {
    return _storage.cacheBox.watch(key: key);
  }
}

/// Cache Statistics
class CacheStats {
  final int totalCount;
  final int validCount;
  final int expiredCount;
  final int totalSizeBytes;

  CacheStats({
    required this.totalCount,
    required this.validCount,
    required this.expiredCount,
    required this.totalSizeBytes,
  });

  /// Get total size in KB
  double get totalSizeKB => totalSizeBytes / 1024;

  /// Get total size in MB
  double get totalSizeMB => totalSizeKB / 1024;

  /// Get formatted size
  String get formattedSize {
    if (totalSizeMB >= 1) {
      return '${totalSizeMB.toStringAsFixed(2)} MB';
    } else if (totalSizeKB >= 1) {
      return '${totalSizeKB.toStringAsFixed(2)} KB';
    } else {
      return '$totalSizeBytes bytes';
    }
  }

  /// Get hit rate percentage
  double get hitRate {
    if (totalCount == 0) return 0;
    return (validCount / totalCount) * 100;
  }

  @override
  String toString() {
    return 'CacheStats(total: $totalCount, valid: $validCount, expired: $expiredCount, size: $formattedSize)';
  }
}
