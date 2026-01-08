import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:sooq_merchant/features/auth/data/repos/auth_repo.dart';

part 'resend_email_state.dart';

class ResendEmailCubit extends Cubit<ResendEmailState> {
  final AuthRepo authRepo;

  ResendEmailCubit(this.authRepo) : super(ResendEmailInitial());

  // Future<void> resendEmail(
  //   String email,
  // ) async {
  //   emit(ResendEmailLoading());

  //   final result = await authRepo.resendEmail(email: email);
  //   result.fold((failure) {
  //     emit(ResendEmailFailure(errMessage: failure.errMessage));
  //   }, (success) {
  //     emit(const ResendEmailSuccess(true));
  //   });
  // }
}
