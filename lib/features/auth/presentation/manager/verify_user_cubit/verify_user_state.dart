part of 'verify_user_cubit.dart';

sealed class VerifyUserState extends Equatable {
  const VerifyUserState();

  @override
  List<Object> get props => [];
}

final class VerifyUserInitial extends VerifyUserState {}

final class VerifyUserLoading extends VerifyUserState {}

final class VerifyUserFailure extends VerifyUserState {
  final String errMessage;
  const VerifyUserFailure({required this.errMessage});
}

final class VerifyUserSuccess extends VerifyUserState {
  final int success;
  const VerifyUserSuccess(this.success);
}
