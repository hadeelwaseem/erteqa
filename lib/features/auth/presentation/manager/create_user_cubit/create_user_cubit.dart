import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sooq_merchant/features/auth/data/repos/auth_repo.dart';

part 'create_user_state.dart';

class CreateUserCubit extends Cubit<CreateUserState> {
  final AuthRepo authRepo;

  CreateUserCubit(this.authRepo) : super(CreateUserInitial());

  // Future<void> createUser(
  //   String email,
  // ) async {
  //   emit(CreateUserLoading());

  //   final result = await authRepo.createUser(email: email);
  //   result.fold((failure) {
  //     emit(CreateUserFailure(errMessage: failure.errMessage));
  //   }, (success) {
  //     emit(const CreateUserSuccess(true));
  //   });
  // }
}
