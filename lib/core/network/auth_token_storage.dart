import 'package:flutter_secure_storage/flutter_secure_storage.dart';

abstract class AuthTokenStorage {
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  });

  Future<String?> readAccessToken();

  Future<String?> readRefreshToken();

  Future<void> clearTokens();
}

class FlutterAuthTokenStorage implements AuthTokenStorage {
  static const String accessTokenKey = 'accessToken';
  static const String refreshTokenKey = 'refreshToken';

  const FlutterAuthTokenStorage();

  @override
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    const storage = FlutterSecureStorage();
    await storage.write(key: accessTokenKey, value: accessToken);
    await storage.write(key: refreshTokenKey, value: refreshToken);
  }

  @override
  Future<String?> readAccessToken() async {
    const storage = FlutterSecureStorage();
    final token = await storage.read(key: accessTokenKey);
    if (token != null && token.isNotEmpty) {
      return token;
    }

    return storage.read(key: 'token');
  }

  @override
  Future<String?> readRefreshToken() async {
    const storage = FlutterSecureStorage();
    return storage.read(key: refreshTokenKey);
  }

  @override
  Future<void> clearTokens() async {
    const storage = FlutterSecureStorage();
    await storage.delete(key: accessTokenKey);
    await storage.delete(key: refreshTokenKey);
    await storage.delete(key: 'token');
  }
}