import 'package:flutter/foundation.dart';

enum LogLevel { debug, info, warning, error }

class AppLogger {
  static void d(String message, [dynamic error, StackTrace? stackTrace]) {
    _log(LogLevel.debug, message, error, stackTrace);
  }

  static void i(String message, [dynamic error, StackTrace? stackTrace]) {
    _log(LogLevel.info, message, error, stackTrace);
  }

  static void w(String message, [dynamic error, StackTrace? stackTrace]) {
    _log(LogLevel.warning, message, error, stackTrace);
  }

  static void e(String message, [dynamic error, StackTrace? stackTrace]) {
    _log(LogLevel.error, message, error, stackTrace);
  }

  static void _log(LogLevel level, String message, dynamic error, StackTrace? stackTrace) {
    if (!kDebugMode) return; // Never log debug info in production release

    final sanitizedMessage = _sanitize(message);
    final prefix = switch (level) {
      LogLevel.debug => '🔍 [DEBUG]',
      LogLevel.info => 'ℹ️ [INFO]',
      LogLevel.warning => '⚠️ [WARN]',
      LogLevel.error => '🚨 [ERROR]',
    };

    debugPrint('$prefix $sanitizedMessage');
    if (error != null) {
      debugPrint('   Details: ${_sanitize(error.toString())}');
    }
  }

  /// Strip sensitive data (e.g. passwords, card numbers, tokens)
  static String _sanitize(String input) {
    return input
        .replaceAll(RegExp(r'password[:=]\s*\S+', caseSensitive: false), 'password=***')
        .replaceAll(RegExp(r'token[:=]\s*\S+', caseSensitive: false), 'token=***')
        .replaceAll(RegExp(r'secret[:=]\s*\S+', caseSensitive: false), 'secret=***')
        .replaceAll(RegExp(r'\b\d{16}\b'), '****-****-****-****');
  }
}
