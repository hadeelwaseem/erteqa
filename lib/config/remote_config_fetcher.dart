import 'dart:convert';

import 'package:dio/dio.dart';

import 'bootstrap_config.dart';
import 'config_mode.dart';
import 'remote_config_url.dart';

/// Fetches raw config JSON over HTTP. Returns null on any failure.
class RemoteConfigFetcher {
  final Dio _client;

  RemoteConfigFetcher({Dio? client})
    : _client =
          client ??
          Dio(
            BaseOptions(
              headers: const {'Accept': 'application/json'},
              responseType: ResponseType.plain,
            ),
          );

  /// Returns raw JSON body string, or null on timeout, network, HTTP, or parse errors.
  Future<String?> fetch(
    BootstrapConfig bootstrap, {
    required Duration timeout,
  }) async {
    if (bootstrap.configMode == ConfigMode.local) {
      return null;
    }

    String url;
    try {
      url = resolveRemoteConfigUrl(bootstrap);
    } catch (_) {
      return null;
    }

    try {
      final response = await _client
          .get<String>(
            url,
            options: Options(
              sendTimeout: timeout,
              receiveTimeout: timeout,
            ),
          )
          .timeout(timeout);

      final statusCode = response.statusCode ?? 0;
      if (statusCode < 200 || statusCode >= 300) {
        return null;
      }

      final body = response.data;
      if (body == null || body.trim().isEmpty) {
        return null;
      }

      final decoded = jsonDecode(body);
      if (decoded is! Map<String, dynamic>) {
        return null;
      }

      return body;
    } catch (_) {
      return null;
    }
  }
}
