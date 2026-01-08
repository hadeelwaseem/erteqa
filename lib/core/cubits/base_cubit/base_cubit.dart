import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// Define the base state
abstract class BaseState extends Equatable {
  const BaseState();

  @override
  List<Object> get props => [];
}

class Initial extends BaseState {}

class Loading extends BaseState {}

class Failure extends BaseState {
  final String errorMessage;

  const Failure({required this.errorMessage});
}

class Success<T> extends BaseState {
  final T data;

  const Success({required this.data});
}

// Define the base cubit
abstract class BaseCubit<T> extends Cubit<BaseState> {
  BaseCubit() : super(Initial());

  void emitLoading() => emit(Loading());

  void emitFailure(String errorMessage) =>
      emit(Failure(errorMessage: errorMessage));

  void emitSuccess(T data) => emit(Success(data: data));
}
