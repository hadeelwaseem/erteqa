import 'package:equatable/equatable.dart';

class Product extends Equatable {
  final String? id;
  final String? name;
  final String? description;
  final String? image;
  final dynamic price;
  final String? currency;
  final double? rating;
  final int? reviewCount;
  final bool? inStock;
  final String? categoryId;

  const Product({
    this.id,
    this.name,
    this.description,
    this.image,
    this.price,
    this.currency,
    this.rating,
    this.reviewCount,
    this.inStock,
    this.categoryId,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] as String?,
      name: json['name'] as String?,
      description: json['description'] as String?,
      image: (json['image'] ?? json['imageUrl'] ?? json['thumbnail']) as String?,
      price: json['price'] ?? json['salePrice'] ?? json['regularPrice'],
      currency: json['currency'] as String?,
      rating: (json['rating'] as num?)?.toDouble(),
      reviewCount: (json['reviewCount'] as num?)?.toInt(),
      inStock: json['inStock'] as bool?,
      categoryId: (json['categoryId'] ?? json['category_id']) as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'image': image,
      'price': price,
      'currency': currency,
      'rating': rating,
      'reviewCount': reviewCount,
      'inStock': inStock,
      'categoryId': categoryId,
    };
  }

  Product copyWith({
    String? id,
    String? name,
    String? description,
    String? image,
    dynamic price,
    String? currency,
    double? rating,
    int? reviewCount,
    bool? inStock,
    String? categoryId,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      image: image ?? this.image,
      price: price ?? this.price,
      currency: currency ?? this.currency,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      inStock: inStock ?? this.inStock,
      categoryId: categoryId ?? this.categoryId,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        description,
        image,
        price,
        currency,
        rating,
        reviewCount,
        inStock,
        categoryId,
      ];
}
