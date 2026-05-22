import 'package:dartz/dartz.dart';
import 'package:sooq_merchant/core/errors/failures.dart';
import 'package:sooq_merchant/core/network/auth_token_storage.dart';
import 'package:sooq_merchant/core/utils/app_logger.dart';
import 'package:sooq_merchant/dev/auth_mock/auth_mock_config.dart';
import 'package:sooq_merchant/dev/auth_mock/mock_auth_data.dart';
import 'package:sooq_merchant/features/auth/data/models/auth_token_response.dart';
import 'package:sooq_merchant/features/auth/data/models/customer_otp_request.dart';
import 'package:sooq_merchant/features/auth/data/models/customer_otp_verify_request.dart';
import 'package:sooq_merchant/features/auth/data/repos/auth_repo.dart';

/// TEMPORARY [AuthRepo] — no HTTP; mirrors [AuthRepoImpl] token persistence.
class MockAuthRepo implements AuthRepo {
  MockAuthRepo(this._tokenStorage);

  final AuthTokenStorage _tokenStorage;

  @override
  Future<Either<Failure, String>> requestOtp({
    required CustomerOtpRequest request,
  }) async {
    final validationError = request.validate();
    if (validationError != null) {
      return Left(AuthFailure(validationError));
    }

    await Future<void>.delayed(AuthMockConfig.requestDelay);
    AppLogger.auth(
      '[MOCK] requestOtp phone=${request.phone} tenantSlug=${request.tenantSlug}',
    );
    return const Right(AuthMockConfig.otpSentMessage);
  }

  @override
  Future<Either<Failure, AuthTokenResponse>> verifyOtp({
    required CustomerOtpVerifyRequest request,
  }) async {
    final validationError = request.validate();
    if (validationError != null) {
      return Left(AuthFailure(validationError));
    }

    final otp = request.otpCode.trim();
    if (!_isOtpAccepted(otp)) {
      return const Left(
        AuthFailure(
          'رمز التحقق غير صحيح',
          code: 'OTP_INVALID',
          statusCode: 400,
        ),
      );
    }

    await Future<void>.delayed(AuthMockConfig.requestDelay);

    final tokenResponse = MockAuthData.tokenResponse(
      phone: request.phone,
      tenantId: request.tenantId,
      tenantSlug: request.tenantSlug,
    );

    final expiresAt = tokenResponse.expiresAt ??
        (tokenResponse.expiresIn != null
            ? DateTime.now()
                .toUtc()
                .add(Duration(seconds: tokenResponse.expiresIn!))
            : null);

    await _tokenStorage.saveTokens(
      accessToken: tokenResponse.accessToken,
      refreshToken: tokenResponse.refreshToken,
      expiresAt: expiresAt,
      tenantId: tokenResponse.tenantId,
    );

    AppLogger.auth(
      '[MOCK] verifyOtp success userId=${tokenResponse.userId} '
      'tenantSlug=${tokenResponse.tenantSlug}',
    );
    return Right(tokenResponse);
  }

  bool _isOtpAccepted(String otp) {
    if (AuthMockConfig.acceptAnySixDigitOtp &&
        CustomerOtpVerifyRequest.otpPattern.hasMatch(otp)) {
      return true;
    }
    return otp == AuthMockConfig.fixedOtp;
  }
}
