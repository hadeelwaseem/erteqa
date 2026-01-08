// import 'package:dartz/dartz.dart';
// import 'package:dio/dio.dart';
// import 'package:encrypt/encrypt.dart';
// import 'package:hive/hive.dart';
// import 'package:lms_student/constants.dart';
// import 'package:lms_student/core/cubits/shared_preferences_cubit/shared_preferences_cubit.dart';
// import 'package:lms_student/core/errors/failures.dart';
// import 'package:lms_student/core/cubits/token_cubit/token_cubit.dart';
// import 'package:lms_student/core/utils/api_service.dart';
// import 'package:lms_student/core/utils/functions/init_firebase.dart';
// import 'package:lms_student/core/utils/service_locator.dart';
// import 'package:lms_student/features/auth/data/models/index_address_years/index_address_years.dart';
// import 'package:lms_student/features/auth/data/models/user_model/user.dart';
// import 'package:lms_student/features/auth/data/models/user_model/user_model.dart';
// import 'package:lms_student/features/auth/data/repos/auth_repo.dart';
// import 'package:encrypt/encrypt.dart' as encrypt;

import 'package:sooq_merchant/core/utils/api_service.dart';
import 'package:sooq_merchant/features/auth/data/repos/auth_repo.dart';

class AuthRepoImpl implements AuthRepo {
  final ApiService _apiService;
  // final TokenCubit tokenCubit = getIt<TokenCubit>();
  // final SharedPreferencesCubit sharedPreferencesCubit =
  //     getIt<SharedPreferencesCubit>();
  AuthRepoImpl(this._apiService);

  //   @override
  //   Future<Either<Failure, IndexAddressYears>> fetchAuthData() async {
  //     try {
  //       final response = await _apiService.get(
  //           queryParameters: null,
  //           url: '$kBaseUrl/auth/indexAddressYears',
  //           token: null,
  //           body: null);
  //       IndexAddressYears indexAddressYears =
  //           IndexAddressYears.fromJson(response);

  //       return right(indexAddressYears);
  //     } on Exception catch (e) {
  //       if (e is DioException) {
  //         return Left(ServerFailure.fromDioException(e));
  //       }
  //       return Left(ServerFailure(e.toString()));
  //     }
  //   }

  //   @override
  //   Future<Either<Failure, Map<String, dynamic>>> signInWithDeviceToken({
  //     required String deviceToken,
  //     String? verificationCode,
  //   }) async {
  //     try {
  //       final key = encrypt.Key.fromUtf8(
  //           'majd123djam321maleh321helam456mm'); // 32 bytes key for AES encryption
  //       final iv = encrypt.IV
  //           .fromUtf8('nottonwelbil0990'); // 16 bytes IV for AES encryption

  //       final encrypter = Encrypter(AES(key, mode: AESMode.cbc));

  // // Encrypting
  //       final encryptedDeviceId = encrypter.encrypt(deviceToken, iv: iv);
  //       Map<String, dynamic> body;
  //       if (verificationCode!.trim().isNotEmpty &&
  //           verificationCode.trim().length == 7) {
  //         body = {
  //           'device_id': encryptedDeviceId.base64, // encryptedDeviceId.base64,
  //           'verificationCode': verificationCode,
  //         };
  //       } else {
  //         body = {
  //           'device_id': encryptedDeviceId.base64, // encryptedDeviceId.base64,
  //         };
  //       }
  //       final response = await _apiService.post(
  //         url: '$kBaseUrl/auth/login',
  //         body: body,
  //         token: null,
  //       );
  //       var box = Hive.box<User>(kUser);
  //       Future.wait([
  //         box.add(UserModel.fromJson(response).user!),
  //         tokenCubit.storeToken(response['access_token']),
  //       ]);

  //       return right(response);
  //     } on Exception catch (e) {
  //       if (e is DioException) {
  //         return Left(ServerFailure.fromDioException(e));
  //       }
  //       return Left(ServerFailure(e.toString()));
  //     }
  //   }

  //     @override
  //     Future<Either<Failure, Map<String, dynamic>>> signUpWithDataAndToken(
  //         {required String username,
  //         required String addressId,
  //         required String birthdate,
  //         required String yearId,
  //         required String imageId,
  //         required String gender,
  //         required String userId,
  //         required String deviceToken}) async {
  //       try {
  //         final key = encrypt.Key.fromUtf8(
  //             'majd123djam321maleh321helam456mm'); // 32 bytes key for AES encryption
  //         final iv = encrypt.IV
  //             .fromUtf8('nottonwelbil0990'); // 16 bytes IV for AES encryption

  //         final encrypter = Encrypter(AES(key, mode: AESMode.cbc));
  //   // Encrypting
  //         final encryptedDeviceId = encrypter.encrypt(deviceToken, iv: iv);
  //         print(encryptedDeviceId.base64);
  //           String? firebaseToken = await initFirebase();
  //           print(firebaseToken );
  //         final response = await _apiService.post(
  //           url: '$kBaseUrl/auth/register',
  //           body: {
  //             'name': username,
  //             'address_id': addressId,
  //             'birth_date': birthdate,
  //             'year_id': yearId,
  //             'image_id': imageId,
  //             'gender': gender,
  //             'user_id': userId,
  //             'device_id': encryptedDeviceId.base64,
  //             'fcm':firebaseToken
  //           },
  //           token: null,
  //         );
  //         var box = Hive.box<User>(kUser);
  //         Future.wait([
  //           box.add(UserModel.fromJson(response).user!),
  //           tokenCubit.storeToken(response['access_token']),

  //           sharedPreferencesCubit.deleteId(),

  //           // sharedPreferencesCubit.setUsername(response['user']['name']),
  //           // sharedPreferencesCubit.setFatherName(response['user']['father_name']),
  //           // sharedPreferencesCubit.setpoints(response['user']['total_points']),
  //           // sharedPreferencesCubit.setId((response['user']['id']).toString()),
  //         ]);

  //         return right(response);
  //       } on Exception catch (e) {
  //         if (e is DioException) {
  //           return Left(ServerFailure.fromDioException(e));
  //         }
  //         return Left(ServerFailure(e.toString()));
  //       }
  //     }

  //   @override
  //   Future<Either<Failure, bool>> createUser({required String email}) async {
  //     try {
  //       //final response =
  //       await _apiService.post(
  //         url: '$kBaseUrl/auth/createUser',
  //         body: {
  //           'email': email,
  //         },
  //         token: null,
  //       );
  //       return right(true);
  //     } on Exception catch (e) {
  //       if (e is DioException) {
  //         //print(e);
  //         return Left(ServerFailure.fromDioException(e));
  //       }
  //       return Left(ServerFailure(e.toString()));
  //     }
  //   }

  //   @override
  //   Future<Either<Failure, int>> verifyUser(
  //       {required String email, required String verificationCode}) async {
  //     try {
  //       final response = await _apiService.post(
  //         url: '$kBaseUrl/auth/verifyUser',
  //         body: {
  //           'verificationCode': verificationCode,
  //           'email': email,
  //         },
  //         token: null,
  //       );
  //       Future.wait([
  //         sharedPreferencesCubit.setId((response['user_id']).toString()),
  //       ]);
  //       return right(response['user_id']);
  //     } on Exception catch (e) {
  //       if (e is DioException) {
  //         return Left(ServerFailure.fromDioException(e));
  //       }
  //       return Left(ServerFailure(e.toString()));
  //     }
  //   }

  //   @override
  //   Future<Either<Failure, bool>> resendEmail({required String email}) async {
  //     try {
  //       //final response =
  //       await _apiService.post(
  //         url: '$kBaseUrl/auth/resend_email',
  //         body: {'email': email},
  //         token: null,
  //       );
  //       return right(true);
  //     } on Exception catch (e) {
  //       if (e is DioException) {
  //         return Left(ServerFailure.fromDioException(e));
  //       }
  //       return Left(ServerFailure(e.toString()));
  //     }
  //   }
}
