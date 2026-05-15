import 'package:dio/dio.dart';
import 'package:sooq_merchant/core/network/auth_token_storage.dart';
import 'package:sooq_merchant/core/utils/constants.dart';

class AuthInterceptor extends Interceptor {
  AuthInterceptor({
    required AuthTokenStorage tokenStorage,
    Future<void> Function()? onAuthLost,
    Dio? refreshClient,
  })  : _tokenStorage = tokenStorage,
        _onAuthLost = onAuthLost,
        _refreshDio =
            refreshClient ??
            Dio(
              BaseOptions(
                headers: const {'Accept': 'application/json'},
                connectTimeout: const Duration(seconds: 20),
                receiveTimeout: const Duration(seconds: 20),
                sendTimeout: const Duration(seconds: 20),
              ),
            );

  static const String _refreshPath = '/api/v1/customer/auth/refresh';
  static const String _retryFlag = 'auth_refresh_retry';

  final AuthTokenStorage _tokenStorage;
  final Future<void> Function()? _onAuthLost;
  final Dio _refreshDio;

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
    if (!isUnauthorized || alreadyRetried) {
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
      final refreshResponse = await _refreshDio.post(
        '$kBaseUrl$_refreshPath',
        data: {'refreshToken': refreshToken},
        options: Options(
          headers: const {'Accept': 'application/json'},
          validateStatus: (status) => status != null && status >= 200 && status < 500,
        ),
      );

      final refreshedTokens = _readTokens(refreshResponse.data);
      if (refreshedTokens == null) {
        await _handleAuthLost();
        handler.next(err);
        return;
      }

      await _tokenStorage.saveTokens(
        accessToken: refreshedTokens.accessToken,
        refreshToken: refreshedTokens.refreshToken,
      );

      final retryOptions = err.requestOptions;
      retryOptions.extra[_retryFlag] = true;
      retryOptions.headers['Authorization'] = 'Bearer ${refreshedTokens.accessToken}';

      final response = await _refreshDio.fetch(retryOptions);
      handler.resolve(response);
    } on DioException {
      await _handleAuthLost();
      handler.next(err);
    } catch (_) {
      await _handleAuthLost();
      handler.next(err);
    }
  }

  Future<void> _handleAuthLost() async {
    await _tokenStorage.clearTokens();
    if (_onAuthLost != null) {
      await _onAuthLost!();
    }
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

    return _TokenBundle(accessToken: accessToken, refreshToken: refreshToken);
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
}

class _TokenBundle {
  _TokenBundle({required this.accessToken, required this.refreshToken});

  final String accessToken;
  final String refreshToken;
}