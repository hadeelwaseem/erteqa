// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:io';

/// Applies per-merchant build identity from a manifest JSON file.
///
/// Usage:
///   dart run tool/apply_merchant_build.dart tool/fixtures/merchant-build.example.json
///
/// Patches Android/iOS native identity and writes `assets/config/bootstrap.json`.
void main(List<String> args) {
  if (args.isEmpty) {
    print('Usage: dart run tool/apply_merchant_build.dart <manifest.json>');
    exit(1);
  }

  final manifestPath = args.first;
  final manifestFile = File(manifestPath);
  if (!manifestFile.existsSync()) {
    print('Manifest not found: $manifestPath');
    exit(1);
  }

  late final Map<String, dynamic> manifest;
  try {
    manifest = jsonDecode(manifestFile.readAsStringSync()) as Map<String, dynamic>;
  } catch (e) {
    print('Invalid JSON in manifest: $e');
    exit(1);
  }

  final errors = _validateManifest(manifest);
  if (errors.isNotEmpty) {
    print('Manifest validation failed:');
    for (final error in errors) {
      print('  - $error');
    }
    exit(1);
  }

  final appName = _requiredString(manifest, 'appName');
  final bundleId = _requiredString(manifest, 'bundleId');
  final apiBaseUrl = _requiredString(manifest, 'apiBaseUrl');
  final tenantId = _requiredString(manifest, 'tenantId');
  final tenantSlug = _requiredString(manifest, 'tenantSlug');
  final configMode = _requiredString(manifest, 'configMode');
  final variantId = _requiredString(manifest, 'variantId');
  final configUrl = _optionalString(manifest['configUrl']);
  final iconUrl = _optionalString(manifest['iconUrl']);

  if (configMode == 'remoteStorage' &&
      (configUrl == null || configUrl.isEmpty)) {
    print('configUrl is required when configMode is remoteStorage');
    exit(1);
  }

  _patchAndroidGradle(bundleId);
  _patchAndroidManifest(appName);
  _patchIosInfoPlist(appName);
  _patchIosBundleIdentifier(bundleId);
  _writeBootstrap(
    appName: appName,
    bundleId: bundleId,
    apiBaseUrl: apiBaseUrl,
    tenantId: tenantId,
    tenantSlug: tenantSlug,
    configMode: configMode,
    variantId: variantId,
    configUrl: configUrl,
    iconUrl: iconUrl,
  );

  print('Applied merchant build from $manifestPath');
  print('  appName:    $appName');
  print('  bundleId:   $bundleId');
  print('  configMode: $configMode');
  print('  variantId:  $variantId');
  print('  bootstrap:  assets/config/bootstrap.json');
}

List<String> _validateManifest(Map<String, dynamic> manifest) {
  final errors = <String>[];
  for (final key in [
    'appName',
    'bundleId',
    'apiBaseUrl',
    'tenantId',
    'tenantSlug',
    'configMode',
    'variantId',
  ]) {
    final value = manifest[key];
    if (value == null || value.toString().trim().isEmpty) {
      errors.add('Missing required field: $key');
    }
  }
  return errors;
}

String _requiredString(Map<String, dynamic> json, String key) {
  return json[key]!.toString().trim();
}

String? _optionalString(Object? value) {
  if (value == null) return null;
  final trimmed = value.toString().trim();
  return trimmed.isEmpty ? null : trimmed;
}

void _patchAndroidGradle(String bundleId) {
  const path = 'android/app/build.gradle.kts';
  final file = File(path);
  var content = file.readAsStringSync();
  content = content.replaceAll(
    RegExp(r'namespace\s*=\s*"[^"]*"'),
    'namespace = "$bundleId"',
  );
  content = content.replaceAll(
    RegExp(r'applicationId\s*=\s*"[^"]*"'),
    'applicationId = "$bundleId"',
  );
  file.writeAsStringSync(content);
  print('Patched $path');
}

void _patchAndroidManifest(String appName) {
  const path = 'android/app/src/main/AndroidManifest.xml';
  final file = File(path);
  var content = file.readAsStringSync();
  content = content.replaceAll(
    RegExp(r'android:label="[^"]*"'),
    'android:label="${_escapeXml(appName)}"',
  );
  file.writeAsStringSync(content);
  print('Patched $path');
}

void _patchIosInfoPlist(String appName) {
  const path = 'ios/Runner/Info.plist';
  final file = File(path);
  var content = file.readAsStringSync();
  content = _replacePlistString(content, 'CFBundleDisplayName', appName);
  content = _replacePlistString(content, 'CFBundleName', appName);
  file.writeAsStringSync(content);
  print('Patched $path');
}

String _replacePlistString(String content, String key, String value) {
  final pattern = RegExp(
    '(<key>$key</key>\\s*<string>)[^<]*(</string>)',
    multiLine: true,
  );
  return content.replaceAllMapped(pattern, (match) {
    return '${match.group(1)}${_escapeXml(value)}${match.group(2)}';
  });
}

void _patchIosBundleIdentifier(String bundleId) {
  const path = 'ios/Runner.xcodeproj/project.pbxproj';
  final file = File(path);
  var content = file.readAsStringSync();
  content = content.replaceAllMapped(
    RegExp(r'PRODUCT_BUNDLE_IDENTIFIER = ([^;]+);'),
    (match) {
      final current = match.group(1)!.trim();
      if (current.contains('RunnerTests')) {
        return match.group(0)!;
      }
      return 'PRODUCT_BUNDLE_IDENTIFIER = $bundleId;';
    },
  );
  file.writeAsStringSync(content);
  print('Patched $path (Runner app targets only)');
}

void _writeBootstrap({
  required String appName,
  required String bundleId,
  required String apiBaseUrl,
  required String tenantId,
  required String tenantSlug,
  required String configMode,
  required String variantId,
  String? configUrl,
  String? iconUrl,
}) {
  const path = 'assets/config/bootstrap.json';
  final bootstrap = <String, dynamic>{
    'schemaVersion': '1.0',
    'configMode': configMode,
    'variantId': variantId,
    'appName': appName,
    'bundleId': bundleId,
    'apiBaseUrl': apiBaseUrl,
    'tenantId': tenantId,
    'tenantSlug': tenantSlug,
    'configUrl': configUrl,
    'iconUrl': iconUrl,
  };
  final file = File(path);
  file.parent.createSync(recursive: true);
  file.writeAsStringSync('${const JsonEncoder.withIndent('  ').convert(bootstrap)}\n');
  print('Wrote $path');
}

String _escapeXml(String value) {
  return value
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;')
      .replaceAll('"', '&quot;');
}
