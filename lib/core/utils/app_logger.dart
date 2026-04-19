import 'package:flutter/foundation.dart';
import 'dart:convert';

/// Lightweight debug logger used across view models/services.
class AppLogger {
  AppLogger._();

  static void info(String message) {
    if (kDebugMode) {
      debugPrint('[SNAPback][INFO] $message');
    }
  }

  static void warn(String message) {
    if (kDebugMode) {
      debugPrint('[SNAPback][WARN] $message');
    }
  }

  static void error(String message, [Object? error, StackTrace? stackTrace]) {
    if (kDebugMode) {
      debugPrint('[SNAPback][ERROR] $message');
      if (error != null) {
        debugPrint('  error: $error');
      }
      if (stackTrace != null) {
        debugPrint('  stack: $stackTrace');
      }
    }
  }

  static void data(String label, Object? payload) {
    if (!kDebugMode) return;
    try {
      final encoded = const JsonEncoder.withIndent('  ').convert(payload);
      debugPrint('[SNAPback][DATA] $label\n$encoded');
    } catch (_) {
      debugPrint('[SNAPback][DATA] $label: $payload');
    }
  }
}
