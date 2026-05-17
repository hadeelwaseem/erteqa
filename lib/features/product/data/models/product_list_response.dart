import 'package:equatable/equatable.dart';
import 'package:sooq_merchant/features/product/data/models/product.dart';
import 'package:sooq_merchant/features/product/data/models/product_meta.dart';

class ProductListResponse extends Equatable {
  final bool success;
  final String? message;
  final List<Product> data;
  final ProductMeta meta;
  final int timestamp;

  const ProductListResponse({
    required this.success,
    this.message,
    required this.data,
    required this.meta,
    required this.timestamp,
  });

  factory ProductListResponse.fromJson(Map<String, dynamic> json) {
    final rawData = json['data'] ?? json['content'];
    final List<Product> products;
    final ProductMeta meta;

    if (rawData is Map<String, dynamic>) {
      products = _productsFromListLike(
        rawData['products'] ?? rawData['content'] ?? rawData['items'],
      );
      meta = ProductMeta.fromJson(
        (rawData['meta'] as Map<String, dynamic>?) ??
            json['meta'] as Map<String, dynamic>? ??
            {},
      );
    } else if (rawData is Map) {
      final nested = Map<String, dynamic>.from(rawData);
      products = _productsFromListLike(
        nested['products'] ?? nested['content'] ?? nested['items'],
      );
      meta = ProductMeta.fromJson(
        (nested['meta'] as Map<String, dynamic>?) ??
            json['meta'] as Map<String, dynamic>? ??
            {},
      );
    } else {
      products = _productsFromListLike(rawData);
      meta = ProductMeta.fromJson(json['meta'] as Map<String, dynamic>? ?? {});
    }

    return ProductListResponse(
      success: json['success'] as bool? ?? false,
      message: json['message'] as String?,
      data: products,
      meta: meta,
      timestamp: json['timestamp'] as int? ?? 0,
    );
  }

  static List<Product> _productsFromListLike(dynamic raw) {
    if (raw is! List) {
      return const [];
    }

    return raw
        .whereType<Map>()
        .map((item) => Product.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'message': message,
      'data': data.map((item) => item.toJson()).toList(),
      'content': data.map((item) => item.toJson()).toList(),
      'meta': meta.toJson(),
      'timestamp': timestamp,
    };
  }

  List<Product> get content => data;

  ProductListResponse copyWith({
    bool? success,
    String? message,
    List<Product>? data,
    ProductMeta? meta,
    int? timestamp,
  }) {
    return ProductListResponse(
      success: success ?? this.success,
      message: message ?? this.message,
      data: data ?? this.data,
      meta: meta ?? this.meta,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  @override
  List<Object?> get props => [success, message, data, meta, timestamp];
}
