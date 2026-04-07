part of 'variant_cubit.dart';

sealed class VariantState {}

final class VariantInitial extends VariantState {}

final class VariantLoading extends VariantState {}

final class VariantSuccess extends VariantState {
  final ScreenConfig config;
  VariantSuccess(this.config);
}

final class VariantFailure extends VariantState {
  final String message;
  VariantFailure(this.message);
}
