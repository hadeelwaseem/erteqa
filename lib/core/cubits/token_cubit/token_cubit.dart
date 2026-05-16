import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sooq_merchant/core/network/auth_token_storage.dart';

class TokenCubit extends Cubit<String?> {
  TokenCubit(this._tokenStorage) : super(null);

  final AuthTokenStorage _tokenStorage;

  DateTime? _expiresAt;
  String? _tenantId;

  DateTime? get expiresAt => _expiresAt;

  String? get tenantId => _tenantId;

  bool shouldRefresh({Duration threshold = const Duration(seconds: 60)}) {
    final expiry = _expiresAt;
    if (expiry == null) {
      return false;
    }
    return expiry.toUtc().isBefore(DateTime.now().toUtc().add(threshold));
  }

  Future<void> fetchSavedToken() async {
    final bundle = await _tokenStorage.readTokenBundle();
    _expiresAt = bundle.expiresAt;
    _tenantId = bundle.tenantId;
    emit(bundle.accessToken);
  }

  Future<void> syncFromStorage() async {
    await fetchSavedToken();
  }

  Future<void> storeToken(
    String token, {
    DateTime? expiresAt,
    String? tenantId,
  }) async {
    final refreshToken = await _tokenStorage.readRefreshToken();
    final resolvedTenantId = tenantId ?? _tenantId ?? await _tokenStorage.readTenantId();
    await _tokenStorage.saveTokens(
      accessToken: token,
      refreshToken: refreshToken ?? token,
      expiresAt: expiresAt,
      tenantId: resolvedTenantId,
    );
    _expiresAt = expiresAt;
    _tenantId = resolvedTenantId;
    emit(token);
  }

  Future<void> deleteSavedToken() async {
    await _tokenStorage.clearTokens();
    _expiresAt = null;
    _tenantId = null;
    emit(null);
  }
}
