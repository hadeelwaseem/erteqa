import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthTokenBundle {
  const AuthTokenBundle({
    this.accessToken,
    this.refreshToken,
    this.expiresAt,
    this.tenantId,
  });

  final String? accessToken;
  final String? refreshToken;
  final DateTime? expiresAt;
  final String? tenantId;
}

abstract class AuthTokenStorage {
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
    DateTime? expiresAt,
    String? tenantId,
  });

  Future<String?> readAccessToken();

  Future<String?> readRefreshToken();

  Future<DateTime?> readExpiresAt();

  Future<String?> readTenantId();

  Future<AuthTokenBundle> readTokenBundle();

  Future<void> clearTokens();
}

class FlutterAuthTokenStorage implements AuthTokenStorage {
  static const String accessTokenKey = 'accessToken';
  static const String refreshTokenKey = 'refreshToken';
  static const String expiresAtKey = 'expiresAt';
  static const String tenantIdKey = 'tenantId';
  static const String _legacyTokenKey = 'token';

  final FlutterSecureStorage _storage;

  const FlutterAuthTokenStorage({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  @override
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
    DateTime? expiresAt,
    String? tenantId,
  }) async {
    await _storage.write(key: accessTokenKey, value: accessToken);
    await _storage.write(key: refreshTokenKey, value: refreshToken);
    if (expiresAt != null) {
      await _storage.write(
        key: expiresAtKey,
        value: expiresAt.toUtc().toIso8601String(),
      );
    } else {
      await _storage.delete(key: expiresAtKey);
    }
    if (tenantId != null && tenantId.isNotEmpty) {
      await _storage.write(key: tenantIdKey, value: tenantId);
    }
  }

  @override
  Future<String?> readTenantId() async {
    return _storage.read(key: tenantIdKey);
  }

  @override
  Future<String?> readAccessToken() async {
    return _storage.read(key: accessTokenKey);
  }

  @override
  Future<String?> readRefreshToken() async {
    return _storage.read(key: refreshTokenKey);
  }

  @override
  Future<DateTime?> readExpiresAt() async {
    final value = await _storage.read(key: expiresAtKey);
    if (value == null || value.isEmpty) {
      return null;
    }
    return DateTime.tryParse(value);
  }

  @override
  Future<AuthTokenBundle> readTokenBundle() async {
    final values = await _storage.readAll();
    final expiresRaw = values[expiresAtKey];
    return AuthTokenBundle(
      accessToken: values[accessTokenKey],
      refreshToken: values[refreshTokenKey],
      expiresAt: expiresRaw == null ? null : DateTime.tryParse(expiresRaw),
      tenantId: values[tenantIdKey],
    );
  }

  @override
  Future<void> clearTokens() async {
    await _storage.delete(key: accessTokenKey);
    await _storage.delete(key: refreshTokenKey);
    await _storage.delete(key: expiresAtKey);
    await _storage.delete(key: tenantIdKey);
    await _storage.delete(key: _legacyTokenKey);
  }
}
