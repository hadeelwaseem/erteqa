import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sooq_merchant/core/errors/failures.dart';
import 'package:sooq_merchant/core/network/network_config.dart';
import 'package:sooq_merchant/features/auth/data/models/auth_token_response.dart';
import 'package:sooq_merchant/features/auth/data/models/customer_otp_request.dart';
import 'package:sooq_merchant/features/auth/data/models/customer_otp_verify_request.dart';
import 'package:sooq_merchant/features/auth/data/repos/auth_repo_impl.dart';

import '../../support/auth_test_utils.dart';

Dio _testDio(FakeHttpClientAdapter adapter) {
  return Dio(BaseOptions(baseUrl: NetworkConfig.defaultBaseUrl))
    ..httpClientAdapter = adapter;
}

void main() {
  group('AuthRepoImpl', () {
    test('requestOtp returns success message on envelope success', () async {
      final adapter = FakeHttpClientAdapter((options) async {
        expect(options.method, 'POST');
        expect(options.path, '/api/v1/customer/auth/otp/request');
        expect(options.data, isA<Map<String, dynamic>>());
        return jsonResponse({
          'success': true,
          'message': 'OTP sent',
          'data': 'OTP sent via WhatsApp',
        });
      });
      final repo = AuthRepoImpl(_testDio(adapter), InMemoryAuthTokenStorage(), sleep: (_) async {});

      final result = await repo.requestOtp(
        request: const CustomerOtpRequest(
          phone: '+963911000111',
          tenantSlug: 'store-a',
          fullName: 'Test User',
        ),
      );

      result.fold(
        (failure) => fail('Expected success, got ${failure.errMessage}'),
        (message) => expect(message, 'OTP sent via WhatsApp'),
      );
    });

    test('requestOtp maps OTP invalid errors to AuthFailure', () async {
      final adapter = FakeHttpClientAdapter((options) async {
        return jsonResponse(
          {
            'success': false,
            'code': 'OTP_INVALID',
            'message': 'OTP invalid',
          },
          statusCode: 400,
        );
      });
      final repo = AuthRepoImpl(_testDio(adapter), InMemoryAuthTokenStorage(), sleep: (_) async {});

      final result = await repo.requestOtp(
        request: const CustomerOtpRequest(
          phone: '+963911000111',
          tenantSlug: 'store-a',
        ),
      );

      result.fold(
        (failure) {
          expect(failure, isA<AuthFailure>());
          final authFailure = failure as AuthFailure;
          expect(authFailure.code, 'OTP_INVALID');
          expect(authFailure.errMessage, 'OTP invalid');
        },
        (_) => fail('Expected failure, got success'),
      );
    });

    test('requestOtp maps expired and rate-limited responses', () async {
      final adapter = FakeHttpClientAdapter((options) async {
        return jsonResponse(
          {
            'success': false,
            'code': 'OTP_EXPIRED',
            'message': 'OTP expired',
          },
          statusCode: 429,
          headers: const {
            'retry-after': ['45'],
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        );
      });
      final repo = AuthRepoImpl(_testDio(adapter), InMemoryAuthTokenStorage(), sleep: (_) async {});

      final result = await repo.requestOtp(
        request: const CustomerOtpRequest(
          phone: '+963911000111',
          tenantId: 'tenant-1',
        ),
      );

      result.fold(
        (failure) {
          expect(failure, isA<AuthFailure>());
          final authFailure = failure as AuthFailure;
          expect(authFailure.isRateLimited, true);
          expect(authFailure.retryAfterSeconds, 45);
          expect(authFailure.code, 'OTP_EXPIRED');
        },
        (_) => fail('Expected failure, got success'),
      );
    });

    test('verifyOtp stores tokens and expiry on success', () async {
      final storage = InMemoryAuthTokenStorage();
      final adapter = FakeHttpClientAdapter((options) async {
        expect(options.method, 'POST');
        expect(options.path, '/api/v1/customer/auth/otp/verify');
        return jsonResponse({
          'success': true,
          'data': {
            'accessToken': 'access-123',
            'refreshToken': 'refresh-456',
            'tokenType': 'Bearer',
            'expiresIn': 3600,
            'expiresAt': '2026-05-03T13:00:00.000Z',
            'tenantId': 'tenant-uuid-1',
            'username': '+963911000111',
            'roles': ['CUSTOMER'],
          },
        });
      });
      final repo = AuthRepoImpl(_testDio(adapter), storage, sleep: (_) async {});

      final result = await repo.verifyOtp(
        request: const CustomerOtpVerifyRequest(
          phone: '+963911000111',
          otpCode: '123456',
          tenantSlug: 'store-a',
        ),
      );

      result.fold(
        (failure) => fail('Expected success, got ${failure.errMessage}'),
        (tokenResponse) {
          expect(tokenResponse, isA<AuthTokenResponse>());
          expect(tokenResponse.accessToken, 'access-123');
          expect(tokenResponse.tenantId, 'tenant-uuid-1');
          expect(storage.accessToken, 'access-123');
          expect(storage.refreshToken, 'refresh-456');
          expect(storage.expiresAt, isNotNull);
          expect(storage.tenantId, 'tenant-uuid-1');
        },
      );
    });

    test('requestOtp retries network failures with backoff', () async {
      final sleepDurations = <Duration>[];
      var attempt = 0;
      final adapter = FakeHttpClientAdapter((options) async {
        attempt += 1;
        if (attempt < 3) {
          throw DioException(
            requestOptions: options,
            type: DioExceptionType.connectionError,
            error: 'network down',
            message: 'network down',
          );
        }

        return jsonResponse({
          'success': true,
          'data': 'OTP sent via WhatsApp',
        });
      });
      final repo = AuthRepoImpl(
        _testDio(adapter),
        InMemoryAuthTokenStorage(),
        sleep: (duration) async {
          sleepDurations.add(duration);
        },
      );

      final result = await repo.requestOtp(
        request: const CustomerOtpRequest(
          phone: '+963911000111',
          tenantSlug: 'store-a',
        ),
      );

      result.fold(
        (failure) => fail('Expected success, got ${failure.errMessage}'),
        (message) => expect(message, 'OTP sent via WhatsApp'),
      );
      expect(attempt, 3);
      expect(sleepDurations, [
        const Duration(milliseconds: 500),
        const Duration(seconds: 1),
      ]);
    });
  });
}
