import 'package:flutter/foundation.dart';

/// Lightweight app logger that only logs in debug mode.
class AppLogger {
  AppLogger._();

  static void debug(String message) {
    if (kDebugMode) {
      debugPrint(message);
    }
  }
}
