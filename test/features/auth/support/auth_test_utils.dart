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

  @override
  Future<void> clearTokens() async {
    accessToken = null;
    refreshToken = null;
  }

  @override
  Future<String?> readAccessToken() async => accessToken;

  @override
  Future<String?> readRefreshToken() async => refreshToken;

  @override
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    this.accessToken = accessToken;
    this.refreshToken = refreshToken;
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