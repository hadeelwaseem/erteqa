import 'package:sooq_merchant/features/auth/data/models/auth_token_response.dart';

/// Static payloads mirroring customer OTP verify API `data` envelope fields.
class MockAuthData {
  MockAuthData._();

  static const String mockAccessToken = 'mock_access_token_dev_only';
  static const String mockRefreshToken = 'mock_refresh_token_dev_only';
  static const String mockUserId = '00000000-0000-4000-8000-000000000001';
  static const String mockUsername = 'Mock User';

  static AuthTokenResponse tokenResponse({
    required String phone,
    String? tenantId,
    String? tenantSlug,
  }) {
    final expiresAt = DateTime.now().toUtc().add(const Duration(hours: 24));
    return AuthTokenResponse(
      accessToken: mockAccessToken,
      refreshToken: mockRefreshToken,
      tokenType: 'Bearer',
      expiresIn: 86400,
      issuedAt: DateTime.now().toUtc(),
      expiresAt: expiresAt,
      username: mockUsername,
      userId: mockUserId,
      tenantId: tenantId,
      tenantSlug: tenantSlug,
      roles: const ['CUSTOMER'],
    );
  }
}
