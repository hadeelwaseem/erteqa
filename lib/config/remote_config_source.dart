import 'dart:convert';

import 'package:dio/dio.dart';

import 'bootstrap_config.dart';
import 'config_mode.dart';
import 'config_source.dart';
import 'remote_config_fetcher.dart';
import 'remote_config_url.dart';

/// Fetches full runtime UI config over HTTP (no disk cache).
///
/// Prefer [SessionConfigResolver] for startup — this class remains for
/// [AppConfigSource] compatibility and legacy direct use.
class RemoteConfigSource implements AppConfigSource {
  final RemoteConfigFetcher _fetcher;
  final Duration _timeout;

  RemoteConfigSource({
    Dio? client,
    Duration timeout = const Duration(seconds: 30),
  }) : _fetcher = RemoteConfigFetcher(client: client),
       _timeout = timeout;

  @override
  Future<Map<String, dynamic>> loadFullConfig(BootstrapConfig bootstrap) async {
    if (bootstrap.configMode == ConfigMode.local) {
      throw const RemoteConfigException(
        'RemoteConfigSource cannot load local config mode.',
      );
    }

    final url = resolveRemoteConfigUrl(bootstrap);
    final raw = await _fetcher.fetch(bootstrap, timeout: _timeout);
    if (raw == null) {
      throw RemoteConfigException(
        'Failed to fetch config from $url',
      );
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) {
        throw RemoteConfigException(
          'Config response must be a JSON object from $url',
        );
      }
      return decoded;
    } on FormatException catch (e) {
      throw RemoteConfigException('Invalid JSON from $url: $e');
    }
  }
}
