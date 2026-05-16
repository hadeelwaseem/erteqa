import 'dart:async';

import 'package:dio/dio.dart';
import 'package:sooq_merchant/core/network/auth_token_storage.dart';

class AuthInterceptor extends Interceptor {
  AuthInterceptor({
    required Dio mainDio,
    required AuthTokenStorage tokenStorage,
    Future<void> Function()? onAuthLost,
  })  : _mainDio = mainDio,
        _tokenStorage = tokenStorage,
        _onAuthLost = onAuthLost;

  static const String _refreshPath = '/api/v1/customer/auth/refresh';
  static const String _retryFlag = 'auth_refresh_retry';

  final Dio _mainDio;
  final AuthTokenStorage _tokenStorage;
  final Future<void> Function()? _onAuthLost;

  Completer<void>? _refreshCompleter;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    final accessToken = await _tokenStorage.readAccessToken();
    if (accessToken != null && accessToken.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $accessToken';
    }

    options.headers.putIfAbsent('Accept', () => 'application/json');
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final isUnauthorized = err.response?.statusCode == 401;
    final alreadyRetried = err.requestOptions.extra[_retryFlag] == true;
    if (!isUnauthorized || alreadyRetried || !_isRepeatableRequest(err.requestOptions)) {
      handler.next(err);
      return;
    }

    final refreshToken = await _tokenStorage.readRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) {
      await _handleAuthLost();
      handler.next(err);
      return;
    }

    try {
      final refreshedTokens = await _refreshTokens(refreshToken);
      if (refreshedTokens == null) {
        await _handleAuthLost();
        handler.next(err);
        return;
      }

      final existingTenantId = await _tokenStorage.readTenantId();
      await _tokenStorage.saveTokens(
        accessToken: refreshedTokens.accessToken,
        refreshToken: refreshedTokens.refreshToken,
        expiresAt: refreshedTokens.expiresAt,
        tenantId: refreshedTokens.tenantId ?? existingTenantId,
      );

      final retryOptions = err.requestOptions;
      retryOptions.extra[_retryFlag] = true;
      retryOptions.headers['Authorization'] = 'Bearer ${refreshedTokens.accessToken}';

      final response = await _mainDio.fetch(retryOptions);
      handler.resolve(response);
    } on DioException {
      await _handleAuthLost();
      handler.next(err);
    } catch (_) {
      await _handleAuthLost();
      handler.next(err);
    }
  }

  Future<_TokenBundle?> _refreshTokens(String refreshToken) async {
    if (_refreshCompleter != null) {
      await _refreshCompleter!.future;
      final bundle = await _tokenStorage.readTokenBundle();
      if (bundle.accessToken == null || bundle.refreshToken == null) {
        return null;
      }
      return _TokenBundle(
        accessToken: bundle.accessToken!,
        refreshToken: bundle.refreshToken!,
        expiresAt: bundle.expiresAt,
      );
    }

    _refreshCompleter = Completer<void>();
    try {
      final refreshResponse = await _mainDio.post(
        _refreshPath,
        data: {'refreshToken': refreshToken},
        options: Options(
          headers: const {'Accept': 'application/json'},
          validateStatus: (status) => status != null && status >= 200 && status < 500,
        ),
      );

      final refreshedTokens = _readTokens(refreshResponse.data);
      if (refreshedTokens == null) {
        _refreshCompleter!.complete();
        return null;
      }

      final existingTenantId = await _tokenStorage.readTenantId();
      await _tokenStorage.saveTokens(
        accessToken: refreshedTokens.accessToken,
        refreshToken: refreshedTokens.refreshToken,
        expiresAt: refreshedTokens.expiresAt,
        tenantId: refreshedTokens.tenantId ?? existingTenantId,
      );

      _refreshCompleter!.complete();
      return refreshedTokens;
    } catch (_) {
      if (!(_refreshCompleter?.isCompleted ?? true)) {
        _refreshCompleter!.complete();
      }
      return null;
    } finally {
      _refreshCompleter = null;
    }
  }

  Future<void> _handleAuthLost() async {
    await _tokenStorage.clearTokens();
    await _onAuthLost?.call();
  }

  bool _isRepeatableRequest(RequestOptions options) {
    final data = options.data;
    if (data is FormData) {
      return false;
    }
    if (data is Stream) {
      return false;
    }
    if (data is MultipartFile) {
      return false;
    }
    return true;
  }

  _TokenBundle? _readTokens(dynamic data) {
    if (data is! Map<String, dynamic>) {
      return null;
    }

    final payload = data['data'];
    final tokenMap = payload is Map<String, dynamic> ? payload : data;

    final accessToken = _readString(tokenMap, const ['accessToken', 'access_token']);
    final refreshToken = _readString(tokenMap, const ['refreshToken', 'refresh_token']);
    if (accessToken == null || refreshToken == null) {
      return null;
    }

    final expiresAt = _readDateTime(tokenMap, const ['expiresAt', 'expires_at']);
    final expiresIn = _readInt(tokenMap, const ['expiresIn', 'expires_in']);
    final resolvedExpiry = expiresAt ??
        (expiresIn != null ? DateTime.now().toUtc().add(Duration(seconds: expiresIn)) : null);

    final tenantId = _readString(tokenMap, const ['tenantId', 'tenant_id']);

    return _TokenBundle(
      accessToken: accessToken,
      refreshToken: refreshToken,
      expiresAt: resolvedExpiry,
      tenantId: tenantId,
    );
  }

  String? _readString(Map<String, dynamic> data, List<String> keys) {
    for (final key in keys) {
      final value = data[key];
      if (value is String && value.isNotEmpty) {
        return value;
      }
    }
    return null;
  }

  int? _readInt(Map<String, dynamic> data, List<String> keys) {
    for (final key in keys) {
      final value = data[key];
      if (value is int) {
        return value;
      }
      if (value is String) {
        final parsed = int.tryParse(value);
        if (parsed != null) {
          return parsed;
        }
      }
    }
    return null;
  }

  DateTime? _readDateTime(Map<String, dynamic> data, List<String> keys) {
    final value = _readString(data, keys);
    if (value == null) {
      return null;
    }
    return DateTime.tryParse(value);
  }
}

class _TokenBundle {
  _TokenBundle({
    required this.accessToken,
    required this.refreshToken,
    this.expiresAt,
    this.tenantId,
  });

  final String accessToken;
  final String refreshToken;
  final DateTime? expiresAt;
  final String? tenantId;
}
