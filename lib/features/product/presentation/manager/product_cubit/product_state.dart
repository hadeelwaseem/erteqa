part of 'product_cubit.dart';

sealed class ProductState {}

final class ProductInitial extends ProductState {}

final class ProductLoading extends ProductState {
  final String requestKey;
  final bool isLoadMore;

  ProductLoading({required this.requestKey, this.isLoadMore = false});
}

final class ProductSuccess extends ProductState {
  final String requestKey;
  final ProductListResponse productListResponse;
  final bool isLoadMore;

  ProductSuccess({
    required this.requestKey,
    required this.productListResponse,
    this.isLoadMore = false,
  });
}

final class ProductFailure extends ProductState {
  final String requestKey;
  final String errMessage;
  final bool isLoadMore;

  ProductFailure({
    required this.requestKey,
    required this.errMessage,
    this.isLoadMore = false,
  });
}
