import 'package:equatable/equatable.dart';
import 'package:sooq_merchant/features/product/data/models/product.dart';
import 'package:sooq_merchant/features/product/data/models/product_meta.dart';

class ProductSearchResult extends Equatable {
  final String? query;
  final List<Product> products;
  final ProductMeta meta;
  final List<String> suggestions;
  final List<Product> popularProducts;
  final int totalResults;

  const ProductSearchResult({
    this.query,
    required this.products,
    required this.meta,
    this.suggestions = const [],
    this.popularProducts = const [],
    this.totalResults = 0,
  });

  factory ProductSearchResult.fromEnvelopeData(Map<String, dynamic> data) {
    final rawProducts = data['products'] ?? const [];
    final rawPopular = data['popularProducts'] ?? const [];
    final rawSuggestions = data['suggestions'] ?? const [];

    final meta = ProductMeta.fromJson(data['meta'] as Map<String, dynamic>? ?? {});

    return ProductSearchResult(
      query: data['query'] as String?,
      products: (rawProducts as List<dynamic>?)
              ?.map((item) => Product.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [],
      meta: meta,
      suggestions: (rawSuggestions as List<dynamic>?)
              ?.map((item) => item.toString())
              .toList() ??
          [],
      popularProducts: (rawPopular as List<dynamic>?)
              ?.map((item) => Product.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [],
      totalResults:
          (data['totalResults'] as num?)?.toInt() ?? meta.total,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'query': query,
      'products': products.map((item) => item.toJson()).toList(),
      'meta': meta.toJson(),
      'suggestions': suggestions,
      'popularProducts': popularProducts.map((item) => item.toJson()).toList(),
      'totalResults': totalResults,
    };
  }

  ProductSearchResult copyWith({
    String? query,
    List<Product>? products,
    ProductMeta? meta,
    List<String>? suggestions,
    List<Product>? popularProducts,
    int? totalResults,
  }) {
    return ProductSearchResult(
      query: query ?? this.query,
      products: products ?? this.products,
      meta: meta ?? this.meta,
      suggestions: suggestions ?? this.suggestions,
      popularProducts: popularProducts ?? this.popularProducts,
      totalResults: totalResults ?? this.totalResults,
    );
  }

  @override
  List<Object?> get props => [
        query,
        products,
        meta,
        suggestions,
        popularProducts,
        totalResults,
      ];
}
