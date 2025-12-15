import 'package:hive/hive.dart';

part 'cache_data.g.dart';

/// Cache Data Model
/// Wraps cached data with metadata (timestamp, TTL, etc.)
@HiveType(typeId: 0)
class CacheData {
  @HiveField(0)
  final String key;

  @HiveField(1)
  final dynamic data;

  @HiveField(2)
  final DateTime timestamp;

  @HiveField(3)
  final Duration? ttl;

  @HiveField(4)
  final Map<String, dynamic>? metadata;

  CacheData({
    required this.key,
    required this.data,
    required this.timestamp,
    this.ttl,
    this.metadata,
  });

  /// Check if cache is expired
  bool get isExpired {
    if (ttl == null) return false;
    return DateTime.now().difference(timestamp) > ttl!;
  }

  /// Check if cache is valid (not expired)
  bool get isValid => !isExpired;

  /// Get age of cache in seconds
  int get ageInSeconds => DateTime.now().difference(timestamp).inSeconds;

  /// Get remaining TTL in seconds
  int? get remainingTTL {
    if (ttl == null) return null;
    final remaining = ttl!.inSeconds - ageInSeconds;
    return remaining > 0 ? remaining : 0;
  }

  /// Create a copy with modified fields
  CacheData copyWith({
    String? key,
    dynamic data,
    DateTime? timestamp,
    Duration? ttl,
    Map<String, dynamic>? metadata,
  }) {
    return CacheData(
      key: key ?? this.key,
      data: data ?? this.data,
      timestamp: timestamp ?? this.timestamp,
      ttl: ttl ?? this.ttl,
      metadata: metadata ?? this.metadata,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'key': key,
      'data': data,
      'timestamp': timestamp.toIso8601String(),
      'ttl': ttl?.inSeconds,
      'metadata': metadata,
    };
  }

  /// Create from JSON
  factory CacheData.fromJson(Map<String, dynamic> json) {
    return CacheData(
      key: json['key'] as String,
      data: json['data'],
      timestamp: DateTime.parse(json['timestamp'] as String),
      ttl: json['ttl'] != null ? Duration(seconds: json['ttl'] as int) : null,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  @override
  String toString() {
    return 'CacheData(key: $key, timestamp: $timestamp, isValid: $isValid, age: ${ageInSeconds}s)';
  }
}
