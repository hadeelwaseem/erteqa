import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sooq_merchant/features/auth/data/repos/auth_repo.dart';

part 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  AuthCubit(this.authRepo) : super(AuthInitial());
  final AuthRepo authRepo;

  // Future<void> signInWithUsernameAndToken(
  //   String deviceToken,
  //   String? verificationCode,
  // ) async {
  //   emit(AuthLoading());

  //   final result = await authRepo.signInWithDeviceToken(
  //       deviceToken: deviceToken, verificationCode: verificationCode);
  //   result.fold((failure) {
  //     emit(AuthFailure(errMessage: failure.errMessage));
  //   }, (success) {
  //     emit(AuthSuccess(success['message']));
  //   });
  // }

  // Future<void> signUpWithNameAndToken(
  //   String username,
  //   // String email,
  //   String addressId,
  //   String birthdate,
  //   String yearId,
  //   String imageId,
  //   String gender,
  //   String userId,
  //   String deviceToken,
  // ) async {
  //   emit(AuthLoading());
  //   final result = await authRepo.signUpWithDataAndToken(
  //       userId: userId,
  //       gender: gender,
  //       deviceToken: deviceToken,
  //       username: username,
  //       addressId: addressId,
  //       birthdate: birthdate,
  //       yearId: yearId,
  //       imageId: imageId);
  //   result.fold((failure) {
  //     emit(AuthFailure(errMessage: failure.errMessage));
  //   }, (success) {
  //     emit(AuthSuccess(success['message']));
  //   });
  // }
}
