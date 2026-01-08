import 'package:dartz/dartz.dart';
import 'package:sooq_merchant/core/errors/failures.dart';
import 'package:sooq_merchant/features/auth/data/models/index_address_years/index_address_years.dart';

abstract class AuthRepo {
  // Future<Either<Failure, Map<String, dynamic>>> signInWithDeviceToken({
  //   required String deviceToken,
  //   String? verificationCode,
  // });
  // Future<Either<Failure, Map<String, dynamic>>> signUpWithDataAndToken({
  //   required String username,
  //   required String addressId,
  //   required String birthdate,
  //   required String yearId,
  //   required String imageId,
  //   required String deviceToken,
  //   required String gender,
  //   required String userId,
  // });

  // Future<Either<Failure, IndexAddressYears>> fetchAuthData();
  // Future<Either<Failure, bool>> createUser({required String email});
  // Future<Either<Failure, int>> verifyUser(
  //     {required String email, required String verificationCode});
  // Future<Either<Failure, bool>> resendEmail({required String email});
}
