// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:io';

/// Splits production config into upload-ready mobile-config.json (UI only).
///
/// Output: `schemaVersion`, `theme`, `navigation`, `pages` — no `app` block.
/// When the input still has `app`, those fields are printed as bootstrap hints only.
///
/// Usage:
///   dart run tool/split_config.dart
void main() {
  const inputPath = 'assets/config/mobile_production_v2.json';
  const outputPath = 'assets/config/mobile-config.json';

  final inputFile = File(inputPath);
  if (!inputFile.existsSync()) {
    print('Input not found: $inputPath');
    exit(1);
  }

  final data = jsonDecode(inputFile.readAsStringSync()) as Map<String, dynamic>;
  final app = data['app'] as Map<String, dynamic>? ?? {};

  final output = <String, dynamic>{
    'schemaVersion': data['schemaVersion'] ?? '1.0',
    if (data.containsKey('theme')) 'theme': data['theme'],
    if (data.containsKey('navigation')) 'navigation': data['navigation'],
    if (data.containsKey('pages')) 'pages': data['pages'],
  };

  final outputFile = File(outputPath);
  outputFile.parent.createSync(recursive: true);
  outputFile.writeAsStringSync(
    '${const JsonEncoder.withIndent('  ').convert(output)}\n',
  );

  print('Wrote $outputPath');
  // Validated by test/config/split_config_output_test.dart
  print('');
  print('Suggested merchant-build.json / bootstrap fields:');
  final suggested = <String, dynamic>{
    'configMode': 'remoteStorage',
    'variantId': 'mobile_production_v2',
    'configUrl': 'https://YOUR_SUPABASE_PUBLIC_URL/mobile-config.json',
    'iconUrl': null,
  };
  if (app.isNotEmpty) {
    suggested.addAll({
      'appName': app['name'],
      'bundleId': app['bundleId'],
      'apiBaseUrl': app['apiBaseUrl'],
      'tenantId': app['tenantId'],
      'tenantSlug': app['tenantSlug'],
    });
  } else {
    suggested.addAll({
      'appName': 'YOUR_APP_NAME',
      'bundleId': 'com.example.app',
      'apiBaseUrl': 'https://api.example.com',
      'tenantId': null,
      'tenantSlug': null,
    });
  }
  print(const JsonEncoder.withIndent('  ').convert(suggested));
}
