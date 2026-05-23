import 'package:flutter/foundation.dart';

/// Lightweight app logger that only logs in debug mode.
class AppLogger {
  AppLogger._();

  static void debug(String message) {
    if (kDebugMode) {
      debugPrint(message);
    }
  }

  /// Non-fatal issues (e.g. layout validator warnings).
  static void warning(String message) {
    if (kDebugMode) {
      debugPrint('[Warning] $message');
    }
  }

  /// Auth-flow logs (request params, API errors). Never logs OTP codes or tokens.
  static void auth(String message) {
    if (kDebugMode) {
      debugPrint('[Auth] $message');
    }
  }

  /// Network / API related logs.
  static void network(String message) {
    if (kDebugMode) {
      debugPrint('[Network] $message');
    }
  }
}
