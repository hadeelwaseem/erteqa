import 'package:equatable/equatable.dart';
import 'package:sooq_merchant/features/product/data/models/autocomplete_product_item.dart';

class ProductAutocompleteResult extends Equatable {
  final List<AutocompleteProductItem> products;
  final List<String> suggestions;

  const ProductAutocompleteResult({
    this.products = const [],
    this.suggestions = const [],
  });

  static const ProductAutocompleteResult empty = ProductAutocompleteResult();

  factory ProductAutocompleteResult.fromEnvelopeData(Map<String, dynamic> data) {
    final rawProducts = data['products'] ?? const [];
    final rawSuggestions = data['suggestions'] ?? const [];

    return ProductAutocompleteResult(
      products: (rawProducts as List<dynamic>?)
              ?.map(
                (item) => AutocompleteProductItem.fromJson(
                  item as Map<String, dynamic>,
                ),
              )
              .toList() ??
          [],
      suggestions: (rawSuggestions as List<dynamic>?)
              ?.map((item) => item.toString())
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'products': products.map((item) => item.toJson()).toList(),
      'suggestions': suggestions,
    };
  }

  @override
  List<Object?> get props => [products, suggestions];
}
