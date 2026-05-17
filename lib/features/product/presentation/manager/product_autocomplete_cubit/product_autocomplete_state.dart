part of 'product_autocomplete_cubit.dart';

sealed class ProductAutocompleteState {}

final class ProductAutocompleteInitial extends ProductAutocompleteState {}

final class ProductAutocompleteLoading extends ProductAutocompleteState {
  final String requestKey;

  ProductAutocompleteLoading({required this.requestKey});
}

final class ProductAutocompleteSuccess extends ProductAutocompleteState {
  final String requestKey;
  final ProductAutocompleteResult autocompleteResult;

  ProductAutocompleteSuccess({
    required this.requestKey,
    required this.autocompleteResult,
  });
}

final class ProductAutocompleteFailure extends ProductAutocompleteState {
  final String requestKey;
  final String errMessage;

  ProductAutocompleteFailure({
    required this.requestKey,
    required this.errMessage,
  });
}
