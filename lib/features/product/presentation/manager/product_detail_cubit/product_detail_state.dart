part of 'product_detail_cubit.dart';

sealed class ProductDetailState {}

final class ProductDetailInitial extends ProductDetailState {}

final class ProductDetailLoading extends ProductDetailState {
  final String requestKey;

  ProductDetailLoading({required this.requestKey});
}

final class ProductDetailSuccess extends ProductDetailState {
  final String requestKey;
  final ProductDetail detail;

  ProductDetailSuccess({
    required this.requestKey,
    required this.detail,
  });
}

final class ProductDetailFailure extends ProductDetailState {
  final String requestKey;
  final String errMessage;

  ProductDetailFailure({
    required this.requestKey,
    required this.errMessage,
  });
}
