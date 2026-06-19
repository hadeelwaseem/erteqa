import 'dart:convert';

import 'bootstrap_config.dart';
import 'mobile_app_config.dart';

/// Result of validating a config JSON string or map before accepting it.
class ConfigValidationResult {
  final bool valid;
  final Map<String, dynamic>? renderJson;
  final String? errorMessage;

  const ConfigValidationResult({
    required this.valid,
    this.renderJson,
    this.errorMessage,
  });

  const ConfigValidationResult.invalid(String message)
    : valid = false,
      renderJson = null,
      errorMessage = message;

  const ConfigValidationResult.success(Map<String, dynamic> json)
    : valid = true,
      renderJson = json,
      errorMessage = null;
}

/// Fast structural validation for config sources (cache, remote, asset).
///
/// Does not parse individual page components — that happens on demand via
/// [VariantConfigParser] when screens load.
class ConfigValidator {
  ConfigValidator._();

  static ConfigValidationResult validateString(
    BootstrapConfig bootstrap,
    String rawJson,
  ) {
    try {
      final decoded = jsonDecode(rawJson);
      if (decoded is! Map<String, dynamic>) {
        return const ConfigValidationResult.invalid(
          'Config root must be a JSON object.',
        );
      }
      return validateMap(bootstrap, decoded);
    } catch (e) {
      return ConfigValidationResult.invalid('JSON decode failed: $e');
    }
  }

  static ConfigValidationResult validateMap(
    BootstrapConfig bootstrap,
    Map<String, dynamic> json,
  ) {
    if (!_hasMinimalShape(json)) {
      return const ConfigValidationResult.invalid(
        'Config must have pages[] or legacy root object.',
      );
    }

    try {
      MobileAppConfig.fromBootstrapAndRender(
        bootstrap: bootstrap,
        renderJson: json,
      );
    } catch (e) {
      return ConfigValidationResult.invalid(
        'fromBootstrapAndRender failed: $e',
      );
    }

    return ConfigValidationResult.success(json);
  }

  static bool _hasMinimalShape(Map<String, dynamic> json) {
    if (json['pages'] is List) {
      return true;
    }
    if (json['root'] is Map) {
      return true;
    }
    return false;
  }
}
