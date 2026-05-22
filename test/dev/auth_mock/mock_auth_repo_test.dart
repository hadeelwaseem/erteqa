import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sooq_merchant/core/errors/failures.dart';
import 'package:sooq_merchant/core/network/auth_token_storage.dart';
import 'package:sooq_merchant/dev/auth_mock/mock_auth_repo.dart';
import 'package:sooq_merchant/features/auth/data/models/customer_otp_request.dart';
import 'package:sooq_merchant/features/auth/data/models/customer_otp_verify_request.dart';

class _MemoryTokenStorage implements AuthTokenStorage {
  String? access;
  String? refresh;

  @override
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
    DateTime? expiresAt,
    String? tenantId,
  }) async {
    access = accessToken;
    refresh = refreshToken;
  }

  @override
  Future<String?> readAccessToken() async => access;

  @override
  Future<String?> readRefreshToken() async => refresh;

  @override
  Future<DateTime?> readExpiresAt() async => null;

  @override
  Future<String?> readTenantId() async => null;

  @override
  Future<AuthTokenBundle> readTokenBundle() async => AuthTokenBundle(
        accessToken: access,
        refreshToken: refresh,
      );

  @override
  Future<void> clearTokens() async {
    access = null;
    refresh = null;
  }
}

void main() {
  late _MemoryTokenStorage storage;
  late MockAuthRepo repo;

  setUp(() {
    storage = _MemoryTokenStorage();
    repo = MockAuthRepo(storage);
  });

  test('requestOtp returns success message without HTTP', () async {
    final result = await repo.requestOtp(
      request: const CustomerOtpRequest(
        phone: '501234567',
        tenantSlug: 'anasgoldenmer',
      ),
    );
    expect(result, isA<Right<Failure, String>>());
    result.fold((_) => fail('expected Right'), (msg) {
      expect(msg, contains('OTP'));
    });
  });

  test('verifyOtp saves tokens and returns AuthTokenResponse', () async {
    final result = await repo.verifyOtp(
      request: const CustomerOtpVerifyRequest(
        phone: '501234567',
        otpCode: '123456',
        tenantSlug: 'anasgoldenmer',
      ),
    );
    expect(result.isRight(), isTrue);
    expect(storage.access, isNotNull);
    expect(storage.refresh, isNotNull);
  });

  test('verifyOtp rejects invalid OTP format', () async {
    final result = await repo.verifyOtp(
      request: const CustomerOtpVerifyRequest(
        phone: '501234567',
        otpCode: '12',
        tenantSlug: 'anasgoldenmer',
      ),
    );
    expect(result.isLeft(), isTrue);
  });
}
