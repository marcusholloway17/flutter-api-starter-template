/// Base Exception
/// All custom exceptions extend this class
abstract class AppException implements Exception {
  final String message;
  final String? code;
  final dynamic details;

  AppException(this.message, {this.code, this.details});

  @override
  String toString() => 'AppException: $message${code != null ? ' (Code: $code)' : ''}';
}

/// Network Exception
/// Thrown when a network error occurs
class NetworkException extends AppException {
  NetworkException(super.message, {super.code, super.details});

  @override
  String toString() => 'NetworkException: $message';
}

/// Server Exception
/// Thrown when the server returns an error
class ServerException extends AppException {
  final int? statusCode;

  ServerException(super.message, {this.statusCode, super.code, super.details});

  @override
  String toString() =>
      'ServerException: $message${statusCode != null ? ' (Status: $statusCode)' : ''}';
}

/// Cache Exception
/// Thrown when a cache operation fails
class CacheException extends AppException {
  CacheException(super.message, {super.code, super.details});

  @override
  String toString() => 'CacheException: $message';
}

/// Timeout Exception
/// Thrown when a request times out
class TimeoutException extends AppException {
  TimeoutException(super.message, {super.code, super.details});

  @override
  String toString() => 'TimeoutException: $message';
}

/// Validation Exception
/// Thrown when input validation fails
class ValidationException extends AppException {
  final Map<String, String>? errors;

  ValidationException(super.message, {this.errors, super.code, super.details});

  @override
  String toString() => 'ValidationException: $message';
}

/// Unauthorized Exception
/// Thrown when user is not authorized
class UnauthorizedException extends AppException {
  UnauthorizedException(super.message, {super.code, super.details});

  @override
  String toString() => 'UnauthorizedException: $message';
}

/// Not Found Exception
/// Thrown when a resource is not found
class NotFoundException extends AppException {
  NotFoundException(super.message, {super.code, super.details});

  @override
  String toString() => 'NotFoundException: $message';
}

/// Parsing Exception
/// Thrown when data parsing fails
class ParsingException extends AppException {
  ParsingException(super.message, {super.code, super.details});

  @override
  String toString() => 'ParsingException: $message';
}
