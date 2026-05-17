part of 'category_cubit.dart';

sealed class CategoryState {}

final class CategoryInitial extends CategoryState {}

final class CategoryLoading extends CategoryState {
  final String requestKey;

  CategoryLoading({required this.requestKey});
}

final class CategoryTreeSuccess extends CategoryState {
  final String requestKey;
  final List<Category> categories;

  CategoryTreeSuccess({
    required this.requestKey,
    required this.categories,
  });
}

final class CategorySuccess extends CategoryState {
  final String requestKey;
  final Category category;

  CategorySuccess({
    required this.requestKey,
    required this.category,
  });
}

final class CategoryFailure extends CategoryState {
  final String requestKey;
  final String errMessage;

  CategoryFailure({
    required this.requestKey,
    required this.errMessage,
  });
}
