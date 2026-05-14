import 'package:equatable/equatable.dart';

import '../../../../core/utils/constants.dart';

class Product extends Equatable {
  final String? id;
  final String? productId;
  final String? slug;
  final String? titleAr;
  final String? titleEn;
  final String? status;
  final String? primaryImageUrl;
  final String? primaryThumbnailUrl;
  final dynamic basePrice;
  final dynamic compareAtPrice;
  final String? currencyCode;
  final String? displayPrice;
  final double? discountPercentage;
  final bool? hasDiscount;
  final int? variantCount;
  final int? totalStock;
  final String? stockStatus;
  final bool? isAvailable;
  final String? createdAt;
  final String? updatedAt;

  const Product({
    this.id,
    this.productId,
    this.slug,
    this.titleAr,
    this.titleEn,
    this.status,
    this.primaryImageUrl,
    this.primaryThumbnailUrl,
    this.basePrice,
    this.compareAtPrice,
    this.currencyCode,
    this.displayPrice,
    this.discountPercentage,
    this.hasDiscount,
    this.variantCount,
    this.totalStock,
    this.stockStatus,
    this.isAvailable,
    this.createdAt,
    this.updatedAt,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    final resolvedId = _readString(json['productId'] ?? json['id']);
    return Product(
      id: resolvedId,
      productId: resolvedId,
      slug: _readString(json['slug']),
      titleAr: _readString(json['titleAr']),
      titleEn: _readString(json['titleEn']),
      status: _readString(json['status']),
      primaryImageUrl: _readString(
        json['primaryImageUrl'] ?? json['imageUrl'] ?? json['image'],
      ),
      primaryThumbnailUrl: _readString(
        json['primaryThumbnailUrl'] ??
            json['thumbnailUrl'] ??
            json['thumbnail'],
      ),
      basePrice: json['basePrice'] ?? json['price'] ?? json['salePrice'],
      compareAtPrice: json['compareAtPrice'] ?? json['regularPrice'],
      currencyCode: _readString(json['currencyCode'] ?? json['currency']),
      displayPrice: _readString(json['displayPrice']),
      discountPercentage: (json['discountPercentage'] as num?)?.toDouble(),
      hasDiscount: json['hasDiscount'] as bool?,
      variantCount: (json['variantCount'] as num?)?.toInt(),
      totalStock: (json['totalStock'] as num?)?.toInt(),
      stockStatus: _readString(json['stockStatus']),
      isAvailable: json['isAvailable'] as bool? ?? json['inStock'] as bool?,
      createdAt: _readString(json['createdAt']),
      updatedAt: _readString(json['updatedAt']),
    );
  }

  String get name {
    final arabic = titleAr?.trim();
    if (arabic != null && arabic.isNotEmpty) return arabic;
    final english = titleEn?.trim();
    if (english != null && english.isNotEmpty) return english;
    return '';
  }

  String get image => resolvedImageUrl;

  String get price => displayPrice ?? _formatBasePrice(basePrice, currencyCode);

  String get currency => currencyCode ?? '';

  String get resolvedImageUrl {
    return _resolveBackendUrl(primaryThumbnailUrl) ??
        _resolveBackendUrl(primaryImageUrl) ??
        '';
  }

  String get resolvedPrimaryImageUrl =>
      _resolveBackendUrl(primaryImageUrl) ?? '';

  String get resolvedPrimaryThumbnailUrl =>
      _resolveBackendUrl(primaryThumbnailUrl) ?? '';

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'productId': productId,
      'slug': slug,
      'titleAr': titleAr,
      'titleEn': titleEn,
      'status': status,
      'primaryImageUrl': resolvedPrimaryImageUrl,
      'primaryThumbnailUrl': resolvedPrimaryThumbnailUrl,
      'basePrice': basePrice,
      'compareAtPrice': compareAtPrice,
      'currencyCode': currencyCode,
      'displayPrice': displayPrice ?? _formatBasePrice(basePrice, currencyCode),
      'discountPercentage': discountPercentage,
      'hasDiscount': hasDiscount,
      'variantCount': variantCount,
      'totalStock': totalStock,
      'stockStatus': stockStatus,
      'isAvailable': isAvailable,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'name': name,
      'image': image,
      'price': price,
      'currency': currency,
    };
  }

  Product copyWith({
    String? id,
    String? productId,
    String? slug,
    String? titleAr,
    String? titleEn,
    String? status,
    String? primaryImageUrl,
    String? primaryThumbnailUrl,
    dynamic basePrice,
    dynamic compareAtPrice,
    String? currencyCode,
    String? displayPrice,
    double? discountPercentage,
    bool? hasDiscount,
    int? variantCount,
    int? totalStock,
    String? stockStatus,
    bool? isAvailable,
    String? createdAt,
    String? updatedAt,
  }) {
    return Product(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      slug: slug ?? this.slug,
      titleAr: titleAr ?? this.titleAr,
      titleEn: titleEn ?? this.titleEn,
      status: status ?? this.status,
      primaryImageUrl: primaryImageUrl ?? this.primaryImageUrl,
      primaryThumbnailUrl: primaryThumbnailUrl ?? this.primaryThumbnailUrl,
      basePrice: basePrice ?? this.basePrice,
      compareAtPrice: compareAtPrice ?? this.compareAtPrice,
      currencyCode: currencyCode ?? this.currencyCode,
      displayPrice: displayPrice ?? this.displayPrice,
      discountPercentage: discountPercentage ?? this.discountPercentage,
      hasDiscount: hasDiscount ?? this.hasDiscount,
      variantCount: variantCount ?? this.variantCount,
      totalStock: totalStock ?? this.totalStock,
      stockStatus: stockStatus ?? this.stockStatus,
      isAvailable: isAvailable ?? this.isAvailable,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    productId,
    slug,
    titleAr,
    titleEn,
    status,
    primaryImageUrl,
    primaryThumbnailUrl,
    basePrice,
    compareAtPrice,
    currencyCode,
    displayPrice,
    discountPercentage,
    hasDiscount,
    variantCount,
    totalStock,
    stockStatus,
    isAvailable,
    createdAt,
    updatedAt,
  ];

  static String? _readString(dynamic value) {
    final text = value?.toString().trim();
    if (text == null || text.isEmpty) return null;
    return text;
  }

  static String? _resolveBackendUrl(String? value) {
    final text = value?.trim();
    if (text == null || text.isEmpty) return null;
    if (text.startsWith('http://') || text.startsWith('https://')) {
      return text;
    }
    if (text.startsWith('/')) {
      return '$kBaseUrlAsset$text';
    }
    return text;
  }

  static String _formatBasePrice(dynamic value, String? currencyCode) {
    if (value == null) return '';
    final price = value is num ? value.toStringAsFixed(2) : value.toString();
    final currency = currencyCode?.trim();
    if (currency == null || currency.isEmpty) return price;
    return '$price $currency';
  }
}
