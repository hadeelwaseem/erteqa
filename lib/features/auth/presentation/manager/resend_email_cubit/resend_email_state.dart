part of 'resend_email_cubit.dart';

sealed class ResendEmailState extends Equatable {
  const ResendEmailState();

  @override
  List<Object> get props => [];
}

final class ResendEmailInitial extends ResendEmailState {}

final class ResendEmailLoading extends ResendEmailState {}

final class ResendEmailFailure extends ResendEmailState {
  final String errMessage;
  const ResendEmailFailure({required this.errMessage});
}

final class ResendEmailSuccess extends ResendEmailState {
  final bool success;
  const ResendEmailSuccess(this.success);
}
