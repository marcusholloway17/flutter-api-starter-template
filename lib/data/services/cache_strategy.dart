/// Cache Strategy Enum
/// Defines different caching strategies
enum CacheStrategy {
  /// Always fetch from network, ignore cache
  networkOnly,

  /// Try cache first, fallback to network if not found
  cacheFirst,

  /// Try network first, fallback to cache if network fails
  networkFirst,

  /// Only use cache, never fetch from network
  cacheOnly,

  /// Return stale cache immediately, then fetch fresh data in background
  staleWhileRevalidate,
}

/// Cache Strategy Extension
extension CacheStrategyExtension on CacheStrategy {
  /// Get strategy name
  String get name {
    switch (this) {
      case CacheStrategy.networkOnly:
        return 'Network Only';
      case CacheStrategy.cacheFirst:
        return 'Cache First';
      case CacheStrategy.networkFirst:
        return 'Network First';
      case CacheStrategy.cacheOnly:
        return 'Cache Only';
      case CacheStrategy.staleWhileRevalidate:
        return 'Stale While Revalidate';
    }
  }

  /// Get strategy description
  String get description {
    switch (this) {
      case CacheStrategy.networkOnly:
        return 'Always fetch fresh data from network';
      case CacheStrategy.cacheFirst:
        return 'Use cached data if available, otherwise fetch from network';
      case CacheStrategy.networkFirst:
        return 'Try network first, use cache as fallback';
      case CacheStrategy.cacheOnly:
        return 'Only use cached data, never fetch from network';
      case CacheStrategy.staleWhileRevalidate:
        return 'Return cached data immediately, update in background';
    }
  }

  /// Check if strategy allows network requests
  bool get allowsNetwork {
    return this != CacheStrategy.cacheOnly;
  }

  /// Check if strategy uses cache
  bool get usesCache {
    return this != CacheStrategy.networkOnly;
  }
}
