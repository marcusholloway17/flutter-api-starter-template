import 'dart:developer' as developer;

/// Log Level Enum
enum LogLevel {
  debug,
  info,
  warning,
  error,
}

/// Application Logger
/// Provides structured logging with different levels
class AppLogger {
  AppLogger._();

  static bool _enableLogging = true;

  /// Enable or disable logging
  static void setLoggingEnabled(bool enabled) {
    _enableLogging = enabled;
  }

  /// Log a debug message
  static void debug(String message, {String? tag, dynamic data}) {
    _log(LogLevel.debug, message, tag: tag, data: data);
  }

  /// Log an info message
  static void info(String message, {String? tag, dynamic data}) {
    _log(LogLevel.info, message, tag: tag, data: data);
  }

  /// Log a warning message
  static void warning(String message, {String? tag, dynamic data}) {
    _log(LogLevel.warning, message, tag: tag, data: data);
  }

  /// Log an error message
  static void error(String message, {String? tag, dynamic error, StackTrace? stackTrace}) {
    _log(LogLevel.error, message, tag: tag, data: error, stackTrace: stackTrace);
  }

  /// Internal log method
  static void _log(
    LogLevel level,
    String message, {
    String? tag,
    dynamic data,
    StackTrace? stackTrace,
  }) {
    if (!_enableLogging) return;

    final timestamp = DateTime.now().toIso8601String();
    final levelStr = _getLevelString(level);
    final tagStr = tag != null ? '[$tag]' : '';
    final logMessage = '$timestamp $levelStr $tagStr $message';

    // Use developer.log for better integration with Flutter DevTools
    developer.log(
      logMessage,
      name: tag ?? 'AppLogger',
      time: DateTime.now(),
      level: _getLogLevelValue(level),
      error: data,
      stackTrace: stackTrace,
    );

    // Also print for console visibility
    if (data != null) {
      print('$logMessage\nData: $data');
    } else {
      print(logMessage);
    }

    if (stackTrace != null) {
      print('StackTrace: $stackTrace');
    }
  }

  /// Get string representation of log level
  static String _getLevelString(LogLevel level) {
    switch (level) {
      case LogLevel.debug:
        return '🐛 DEBUG';
      case LogLevel.info:
        return 'ℹ️  INFO';
      case LogLevel.warning:
        return '⚠️  WARNING';
      case LogLevel.error:
        return '❌ ERROR';
    }
  }

  /// Get numeric value for log level (for developer.log)
  static int _getLogLevelValue(LogLevel level) {
    switch (level) {
      case LogLevel.debug:
        return 500;
      case LogLevel.info:
        return 800;
      case LogLevel.warning:
        return 900;
      case LogLevel.error:
        return 1000;
    }
  }
}
