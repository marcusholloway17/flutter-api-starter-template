import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../../config/app_config.dart';
import '../../core/constants/api_constants.dart';
import '../../core/errors/exceptions.dart';
import '../../core/utils/logger.dart';
import 'cache_manager.dart';
import 'cache_strategy.dart';

/// API Service
/// Handles all HTTP requests with caching support
class ApiService {
  static ApiService? _instance;
  static ApiService get instance => _instance ??= ApiService._();

  ApiService._();

  final _client = http.Client();
  final _cacheManager = CacheManager.instance;

  /// Make a GET request
  Future<dynamic> get(
    String endpoint, {
    Map<String, String>? headers,
    Map<String, dynamic>? queryParameters,
    Duration? timeout,
    CacheStrategy strategy = CacheStrategy.networkFirst,
    Duration? cacheTTL,
  }) async {
    return _request(
      method: ApiConstants.get,
      endpoint: endpoint,
      headers: headers,
      queryParameters: queryParameters,
      timeout: timeout,
      strategy: strategy,
      cacheTTL: cacheTTL,
    );
  }

  /// Make a POST request
  Future<dynamic> post(
    String endpoint, {
    Map<String, String>? headers,
    Map<String, dynamic>? body,
    Map<String, dynamic>? queryParameters,
    Duration? timeout,
  }) async {
    return _request(
      method: ApiConstants.post,
      endpoint: endpoint,
      headers: headers,
      body: body,
      queryParameters: queryParameters,
      timeout: timeout,
      strategy: CacheStrategy.networkOnly,
    );
  }

  /// Make a PUT request
  Future<dynamic> put(
    String endpoint, {
    Map<String, String>? headers,
    Map<String, dynamic>? body,
    Map<String, dynamic>? queryParameters,
    Duration? timeout,
  }) async {
    return _request(
      method: ApiConstants.put,
      endpoint: endpoint,
      headers: headers,
      body: body,
      queryParameters: queryParameters,
      timeout: timeout,
      strategy: CacheStrategy.networkOnly,
    );
  }

  /// Make a DELETE request
  Future<dynamic> delete(
    String endpoint, {
    Map<String, String>? headers,
    Map<String, dynamic>? queryParameters,
    Duration? timeout,
  }) async {
    return _request(
      method: ApiConstants.delete,
      endpoint: endpoint,
      headers: headers,
      queryParameters: queryParameters,
      timeout: timeout,
      strategy: CacheStrategy.networkOnly,
    );
  }

  /// Make a PATCH request
  Future<dynamic> patch(
    String endpoint, {
    Map<String, String>? headers,
    Map<String, dynamic>? body,
    Map<String, dynamic>? queryParameters,
    Duration? timeout,
  }) async {
    return _request(
      method: ApiConstants.patch,
      endpoint: endpoint,
      headers: headers,
      body: body,
      queryParameters: queryParameters,
      timeout: timeout,
      strategy: CacheStrategy.networkOnly,
    );
  }

  /// Internal request method with caching support
  Future<dynamic> _request({
    required String method,
    required String endpoint,
    Map<String, String>? headers,
    Map<String, dynamic>? body,
    Map<String, dynamic>? queryParameters,
    Duration? timeout,
    CacheStrategy strategy = CacheStrategy.networkFirst,
    Duration? cacheTTL,
  }) async {
    final uri = _buildUri(endpoint, queryParameters);
    final cacheKey = _buildCacheKey(method, uri.toString());

    AppLogger.info('$method $uri', tag: 'ApiService');
    AppLogger.debug('Strategy: ${strategy.name}', tag: 'ApiService');

    try {
      // Handle cache strategies
      switch (strategy) {
        case CacheStrategy.cacheOnly:
          return await _getCachedData(cacheKey);

        case CacheStrategy.cacheFirst:
          final cachedData = await _cacheManager.get(cacheKey);
          if (cachedData != null) {
            AppLogger.info('Returning cached data', tag: 'ApiService');
            return cachedData;
          }
          return await _fetchAndCache(
            method: method,
            uri: uri,
            headers: headers,
            body: body,
            timeout: timeout,
            cacheKey: cacheKey,
            cacheTTL: cacheTTL,
          );

        case CacheStrategy.networkFirst:
          try {
            return await _fetchAndCache(
              method: method,
              uri: uri,
              headers: headers,
              body: body,
              timeout: timeout,
              cacheKey: cacheKey,
              cacheTTL: cacheTTL,
            );
          } catch (e) {
            AppLogger.warning('Network failed, trying cache', tag: 'ApiService');
            final cachedData = await _cacheManager.get(cacheKey, ignoreExpiry: true);
            if (cachedData != null) {
              AppLogger.info('Returning stale cached data', tag: 'ApiService');
              return cachedData;
            }
            rethrow;
          }

        case CacheStrategy.staleWhileRevalidate:
          final cachedData = await _cacheManager.get(cacheKey, ignoreExpiry: true);
          if (cachedData != null) {
            // Return cached data immediately
            AppLogger.info('Returning stale cache, updating in background', tag: 'ApiService');
            
            // Update cache in background
            _fetchAndCache(
              method: method,
              uri: uri,
              headers: headers,
              body: body,
              timeout: timeout,
              cacheKey: cacheKey,
              cacheTTL: cacheTTL,
            ).catchError((e) {
              AppLogger.warning('Background update failed', tag: 'ApiService', data: e);
            });
            
            return cachedData;
          }
          // No cache available, fetch normally
          return await _fetchAndCache(
            method: method,
            uri: uri,
            headers: headers,
            body: body,
            timeout: timeout,
            cacheKey: cacheKey,
            cacheTTL: cacheTTL,
          );

        case CacheStrategy.networkOnly:
          return await _executeRequest(
            method: method,
            uri: uri,
            headers: headers,
            body: body,
            timeout: timeout,
          );
      }
    } catch (e, stack) {
      AppLogger.error('Request failed', tag: 'ApiService', error: e, stackTrace: stack);
      rethrow;
    }
  }

  /// Fetch data and cache it
  Future<dynamic> _fetchAndCache({
    required String method,
    required Uri uri,
    Map<String, String>? headers,
    Map<String, dynamic>? body,
    Duration? timeout,
    required String cacheKey,
    Duration? cacheTTL,
  }) async {
    final data = await _executeRequest(
      method: method,
      uri: uri,
      headers: headers,
      body: body,
      timeout: timeout,
    );

    // Cache the response
    await _cacheManager.save(cacheKey, data, ttl: cacheTTL);

    return data;
  }

  /// Execute HTTP request with retry logic
  Future<dynamic> _executeRequest({
    required String method,
    required Uri uri,
    Map<String, String>? headers,
    Map<String, dynamic>? body,
    Duration? timeout,
    int retryCount = 0,
  }) async {
    try {
      final requestHeaders = _buildHeaders(headers);
      final requestTimeout = timeout ?? ApiConstants.defaultTimeout;

      http.Response response;

      switch (method) {
        case ApiConstants.get:
          response = await _client
              .get(uri, headers: requestHeaders)
              .timeout(requestTimeout);
          break;
        case ApiConstants.post:
          response = await _client
              .post(uri, headers: requestHeaders, body: jsonEncode(body))
              .timeout(requestTimeout);
          break;
        case ApiConstants.put:
          response = await _client
              .put(uri, headers: requestHeaders, body: jsonEncode(body))
              .timeout(requestTimeout);
          break;
        case ApiConstants.delete:
          response = await _client
              .delete(uri, headers: requestHeaders)
              .timeout(requestTimeout);
          break;
        case ApiConstants.patch:
          response = await _client
              .patch(uri, headers: requestHeaders, body: jsonEncode(body))
              .timeout(requestTimeout);
          break;
        default:
          throw NetworkException('Unsupported HTTP method: $method');
      }

      return _handleResponse(response);
    } on SocketException catch (e) {
      AppLogger.error('Network error', tag: 'ApiService', error: e);
      throw NetworkException('No internet connection');
    } on TimeoutException catch (e) {
      // Retry logic
      if (retryCount < ApiConstants.maxRetries) {
        AppLogger.warning('Request timeout, retrying... (${retryCount + 1}/${ApiConstants.maxRetries})', tag: 'ApiService');
        await Future.delayed(ApiConstants.retryDelay);
        return _executeRequest(
          method: method,
          uri: uri,
          headers: headers,
          body: body,
          timeout: timeout,
          retryCount: retryCount + 1,
        );
      }
      AppLogger.error('Request timeout after retries', tag: 'ApiService', error: e);
      throw TimeoutException('Request timeout');
    } on http.ClientException catch (e) {
      AppLogger.error('Client error', tag: 'ApiService', error: e);
      throw NetworkException('Client error: ${e.message}');
    } catch (e) {
      AppLogger.error('Unknown error', tag: 'ApiService', error: e);
      throw NetworkException('Unknown error: $e');
    }
  }

  /// Handle HTTP response
  dynamic _handleResponse(http.Response response) {
    AppLogger.debug('Response status: ${response.statusCode}', tag: 'ApiService');

    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) {
        return null;
      }
      try {
        return jsonDecode(response.body);
      } catch (e) {
        AppLogger.error('Failed to parse response', tag: 'ApiService', error: e);
        throw ParsingException('Failed to parse response: $e');
      }
    } else {
      _handleErrorResponse(response);
    }
  }

  /// Handle error responses
  void _handleErrorResponse(http.Response response) {
    final statusCode = response.statusCode;
    String message = 'Request failed with status: $statusCode';

    try {
      final errorBody = jsonDecode(response.body);
      message = errorBody['message'] ?? message;
    } catch (_) {
      // Use default message if parsing fails
    }

    switch (statusCode) {
      case ApiConstants.statusUnauthorized:
        throw UnauthorizedException(message, statusCode: statusCode);
      case ApiConstants.statusForbidden:
        throw UnauthorizedException('Access forbidden', statusCode: statusCode);
      case ApiConstants.statusNotFound:
        throw NotFoundException(message, statusCode: statusCode);
      case ApiConstants.statusTimeout:
        throw TimeoutException(message);
      case ApiConstants.statusTooManyRequests:
        throw ServerException('Too many requests', statusCode: statusCode);
      case ApiConstants.statusInternalServerError:
      case ApiConstants.statusServiceUnavailable:
        throw ServerException(message, statusCode: statusCode);
      default:
        throw ServerException(message, statusCode: statusCode);
    }
  }

  /// Build URI with query parameters
  Uri _buildUri(String endpoint, Map<String, dynamic>? queryParameters) {
    final baseUrl = AppConfig.apiBaseUrl;
    final fullUrl = baseUrl + endpoint;

    if (queryParameters != null && queryParameters.isNotEmpty) {
      final queryString = queryParameters.entries
          .map((e) => '${e.key}=${Uri.encodeComponent(e.value.toString())}')
          .join('&');
      return Uri.parse('$fullUrl?$queryString');
    }

    return Uri.parse(fullUrl);
  }

  /// Build request headers
  Map<String, String> _buildHeaders(Map<String, String>? customHeaders) {
    final headers = <String, String>{
      ApiConstants.contentType: ApiConstants.applicationJson,
      ApiConstants.accept: ApiConstants.applicationJson,
    };

    if (customHeaders != null) {
      headers.addAll(customHeaders);
    }

    return headers;
  }

  /// Build cache key
  String _buildCacheKey(String method, String url) {
    return '${method}_$url';
  }

  /// Get cached data
  Future<dynamic> _getCachedData(String cacheKey) async {
    final cachedData = await _cacheManager.get(cacheKey);
    if (cachedData == null) {
      throw CacheException('No cached data available');
    }
    AppLogger.info('Returning cached data', tag: 'ApiService');
    return cachedData;
  }

  /// Close HTTP client
  void close() {
    _client.close();
  }
}
