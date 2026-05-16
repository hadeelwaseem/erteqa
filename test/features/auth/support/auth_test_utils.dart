import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:sooq_merchant/core/network/auth_token_storage.dart';

typedef TestResponseHandler = Future<ResponseBody> Function(RequestOptions options);

class FakeHttpClientAdapter implements HttpClientAdapter {
  FakeHttpClientAdapter(this.handler);

  final TestResponseHandler handler;
  final List<RequestOptions> requests = <RequestOptions>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    return handler(options);
  }

  @override
  void close({bool force = false}) {}
}

class InMemoryAuthTokenStorage implements AuthTokenStorage {
  String? accessToken;
  String? refreshToken;
  DateTime? expiresAt;
  String? tenantId;

  @override
  Future<void> clearTokens() async {
    accessToken = null;
    refreshToken = null;
    expiresAt = null;
    tenantId = null;
  }

  @override
  Future<String?> readAccessToken() async => accessToken;

  @override
  Future<String?> readRefreshToken() async => refreshToken;

  @override
  Future<DateTime?> readExpiresAt() async => expiresAt;

  @override
  Future<String?> readTenantId() async => tenantId;

  @override
  Future<AuthTokenBundle> readTokenBundle() async {
    return AuthTokenBundle(
      accessToken: accessToken,
      refreshToken: refreshToken,
      expiresAt: expiresAt,
      tenantId: tenantId,
    );
  }

  @override
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
    DateTime? expiresAt,
    String? tenantId,
  }) async {
    this.accessToken = accessToken;
    this.refreshToken = refreshToken;
    this.expiresAt = expiresAt;
    if (tenantId != null && tenantId.isNotEmpty) {
      this.tenantId = tenantId;
    }
  }
}

ResponseBody jsonResponse(
  Object body, {
  int statusCode = 200,
  Map<String, List<String>>? headers,
}) {
  return ResponseBody.fromString(
    jsonEncode(body),
    statusCode,
    headers: headers ?? const {Headers.contentTypeHeader: [Headers.jsonContentType]},
  );
}
