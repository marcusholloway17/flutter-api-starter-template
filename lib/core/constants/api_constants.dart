/// API Constants
/// Contains all API-related constants and endpoints
class ApiConstants {
  ApiConstants._();

  // HTTP Methods
  static const String get = 'GET';
  static const String post = 'POST';
  static const String put = 'PUT';
  static const String delete = 'DELETE';
  static const String patch = 'PATCH';

  // Headers
  static const String contentType = 'Content-Type';
  static const String accept = 'Accept';
  static const String authorization = 'Authorization';
  static const String applicationJson = 'application/json';

  // Timeout durations
  static const Duration defaultTimeout = Duration(seconds: 30);
  static const Duration uploadTimeout = Duration(seconds: 60);
  static const Duration downloadTimeout = Duration(minutes: 5);

  // Retry configuration
  static const int maxRetries = 3;
  static const Duration retryDelay = Duration(seconds: 1);

  // Cache TTL (Time To Live)
  static const Duration shortCacheTTL = Duration(minutes: 5);
  static const Duration mediumCacheTTL = Duration(minutes: 30);
  static const Duration longCacheTTL = Duration(hours: 24);

  // JSONPlaceholder API Endpoints
  static const String users = '/users';
  static const String posts = '/posts';
  static const String comments = '/comments';
  static const String albums = '/albums';
  static const String photos = '/photos';
  static const String todos = '/todos';

  // Status Codes
  static const int statusOk = 200;
  static const int statusCreated = 201;
  static const int statusAccepted = 202;
  static const int statusNoContent = 204;
  static const int statusBadRequest = 400;
  static const int statusUnauthorized = 401;
  static const int statusForbidden = 403;
  static const int statusNotFound = 404;
  static const int statusTimeout = 408;
  static const int statusTooManyRequests = 429;
  static const int statusInternalServerError = 500;
  static const int statusServiceUnavailable = 503;
}
