import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:sooq_merchant/features/auth/data/repos/auth_repo.dart';

part 'verify_user_state.dart';

class VerifyUserCubit extends Cubit<VerifyUserState> {
  final AuthRepo authRepo;

  VerifyUserCubit(this.authRepo) : super(VerifyUserInitial());

  // Future<void> verfiyUser(
  //   String email,
  //   String verificationCode,
  // ) async {
  //   emit(VerifyUserLoading());

  //   final result = await authRepo.verifyUser(
  //       verificationCode: verificationCode, email: email);
  //   result.fold((failure) {
  //     emit(VerifyUserFailure(errMessage: failure.errMessage));
  //   }, (success) {
  //     emit(VerifyUserSuccess(success));
  //   });
  // }
}
