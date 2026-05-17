part of 'product_search_cubit.dart';

sealed class ProductSearchState {}

final class ProductSearchInitial extends ProductSearchState {}

final class ProductSearchLoading extends ProductSearchState {
  final String requestKey;
  final bool isLoadMore;

  ProductSearchLoading({required this.requestKey, this.isLoadMore = false});
}

final class ProductSearchSuccess extends ProductSearchState {
  final String requestKey;
  final ProductSearchResult searchResult;
  final bool isLoadMore;

  ProductSearchSuccess({
    required this.requestKey,
    required this.searchResult,
    this.isLoadMore = false,
  });
}

final class ProductSearchFailure extends ProductSearchState {
  final String requestKey;
  final String errMessage;
  final bool isLoadMore;

  ProductSearchFailure({
    required this.requestKey,
    required this.errMessage,
    this.isLoadMore = false,
  });
}
