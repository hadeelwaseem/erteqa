part of 'product_cubit.dart';

sealed class ProductState {}

final class ProductInitial extends ProductState {}

final class ProductLoading extends ProductState {
  final String requestKey;

  ProductLoading({required this.requestKey});
}

final class ProductSuccess extends ProductState {
  final String requestKey;
  final ProductListResponse productListResponse;

  ProductSuccess({
    required this.requestKey,
    required this.productListResponse,
  });
}

final class ProductFailure extends ProductState {
  final String requestKey;
  final String errMessage;

  ProductFailure({required this.requestKey, required this.errMessage});
}
