// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:io';

import 'merchant_dispatch.dart';

/// Validates GitHub `repository_dispatch` payload and writes merchant-build.json.
///
/// Usage:
///   dart run tool/prepare_merchant_manifest_from_dispatch.dart \
///     tool/fixtures/repository-dispatch.example.json merchant-build.json
void main(List<String> args) {
  if (args.length < 2) {
    print(
      'Usage: dart run tool/prepare_merchant_manifest_from_dispatch.dart '
      '<dispatch.json> <merchant-build.json>',
    );
    exit(1);
  }

  final inputPath = args[0];
  final outputPath = args[1];
  final inputFile = File(inputPath);
  if (!inputFile.existsSync()) {
    print('Input not found: $inputPath');
    exit(1);
  }

  late final Map<String, dynamic> input;
  try {
    input = jsonDecode(inputFile.readAsStringSync()) as Map<String, dynamic>;
  } catch (e) {
    print('Invalid JSON in $inputPath: $e');
    exit(1);
  }

  final payload = unwrapDispatchPayload(input);
  final errors = validateMerchantDispatchPayload(payload);
  if (errors.isNotEmpty) {
    print('repository_dispatch client_payload validation failed:');
    for (final error in errors) {
      print('  - $error');
    }
    print('');
    print('Expected snake_case keys inside client_payload. Example:');
    print('  tool/fixtures/repository-dispatch.example.json');
    exit(1);
  }

  final manifest = merchantManifestFromDispatch(payload);
  File(outputPath).writeAsStringSync(
    '${const JsonEncoder.withIndent('  ').convert(manifest)}\n',
  );

  print('Wrote $outputPath from $inputPath');
  print('  appName:     ${manifest['appName']}');
  print('  bundleId:    ${manifest['bundleId']}');
  print('  configMode:  ${manifest['configMode']}');
  print('  variantId:   ${manifest['variantId']}');
  print('  buildNumber: ${manifest['buildNumber']}');
}
