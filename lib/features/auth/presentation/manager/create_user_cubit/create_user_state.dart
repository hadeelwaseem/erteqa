part of 'create_user_cubit.dart';

sealed class CreateUserState extends Equatable {
  const CreateUserState();

  @override
  List<Object> get props => [];
}

final class CreateUserInitial extends CreateUserState {}

final class CreateUserLoading extends CreateUserState {}

final class CreateUserFailure extends CreateUserState {
  final String errMessage;
  const CreateUserFailure({required this.errMessage});
}

final class CreateUserSuccess extends CreateUserState {
  final bool success;
  const CreateUserSuccess(this.success);
}
