import 'package:dartz/dartz.dart';
import 'package:sooq_merchant/core/errors/failures.dart';
import 'package:sooq_merchant/features/auth/data/models/auth_token_response.dart';
import 'package:sooq_merchant/features/auth/data/models/customer_otp_request.dart';
import 'package:sooq_merchant/features/auth/data/models/customer_otp_verify_request.dart';

abstract class AuthRepo {
  Future<Either<Failure, String>> requestOtp({
    required CustomerOtpRequest request,
  });

  Future<Either<Failure, AuthTokenResponse>> verifyOtp({
    required CustomerOtpVerifyRequest request,
  });
}