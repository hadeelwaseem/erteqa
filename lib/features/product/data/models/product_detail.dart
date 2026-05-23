import 'package:equatable/equatable.dart';
import 'package:sooq_merchant/core/network/remote_image_url.dart';

class ProductDetail extends Equatable {
  final String? productId;
  final String? titleAr;
  final String? titleEn;
  final String? descriptionAr;
  final String? descriptionEn;
  final String? slug;
  final String? seoTitle;
  final String? seoDescription;
  final bool isAvailable;
  final PricingBlock? pricing;
  final InventoryBlock? inventory;
  final List<ProductImage> images;
  final List<ProductVariant> variants;
  final List<ProductCategoryRef> categories;
  final List<ProductTag> tags;
  final List<ProductAttribute> attributes;

  const ProductDetail({
    this.productId,
    this.titleAr,
    this.titleEn,
    this.descriptionAr,
    this.descriptionEn,
    this.slug,
    this.seoTitle,
    this.seoDescription,
    this.isAvailable = false,
    this.pricing,
    this.inventory,
    this.images = const [],
    this.variants = const [],
    this.categories = const [],
    this.tags = const [],
    this.attributes = const [],
  });

  factory ProductDetail.fromEnvelopeData(Map<String, dynamic> data) {
    return ProductDetail(
      productId: _readString(data['productId'] ?? data['id']),
      titleAr: _readString(data['titleAr']),
      titleEn: _readString(data['titleEn']),
      descriptionAr: _readString(data['descriptionAr']),
      descriptionEn: _readString(data['descriptionEn']),
      slug: _readString(data['slug']),
      seoTitle: _readString(data['seoTitle']),
      seoDescription: _readString(data['seoDescription']),
      isAvailable: data['isAvailable'] as bool? ?? false,
      pricing: data['pricing'] is Map<String, dynamic>
          ? PricingBlock.fromJson(data['pricing'] as Map<String, dynamic>)
          : null,
      inventory: data['inventory'] is Map<String, dynamic>
          ? InventoryBlock.fromJson(data['inventory'] as Map<String, dynamic>)
          : null,
      images: _parseImages(data['images']),
      variants: _parseVariants(data['variants']),
      categories: _parseCategories(data['categories']),
      tags: _parseTags(data['tags']),
      attributes: _parseAttributes(data['attributes']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'productId': productId,
      'titleAr': titleAr,
      'titleEn': titleEn,
      'descriptionAr': descriptionAr,
      'descriptionEn': descriptionEn,
      'slug': slug,
      'seoTitle': seoTitle,
      'seoDescription': seoDescription,
      'isAvailable': isAvailable,
      'pricing': pricing?.toJson(),
      'inventory': inventory?.toJson(),
      'images': images.map((item) => item.toJson()).toList(),
      'variants': variants.map((item) => item.toJson()).toList(),
      'categories': categories.map((item) => item.toJson()).toList(),
      'tags': tags.map((item) => item.toJson()).toList(),
      'attributes': attributes.map((item) => item.toJson()).toList(),
      'primaryImageUrl': primaryImage?.publicUrl,
      'displayPrice': displayPrice,
      'description': description,
      'name': name,
    };
  }

  String get name {
    final arabic = titleAr?.trim();
    if (arabic != null && arabic.isNotEmpty) return arabic;
    final english = titleEn?.trim();
    if (english != null && english.isNotEmpty) return english;
    return '';
  }

  String get displayPrice => pricing?.displayPrice ?? '';

  String get description {
    final arabic = descriptionAr?.trim();
    if (arabic != null && arabic.isNotEmpty) return arabic;
    return descriptionEn?.trim() ?? '';
  }

  ProductImage? get primaryImage {
    for (final image in images) {
      if (image.isPrimary) return image;
    }
    if (images.isEmpty) return null;
    return images.first;
  }

  static List<ProductImage> _parseImages(dynamic raw) {
    if (raw is! List) return const [];
    return raw
        .map((item) => ProductImage.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  static List<ProductVariant> _parseVariants(dynamic raw) {
    if (raw is! List) return const [];
    return raw
        .map((item) => ProductVariant.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  static List<ProductCategoryRef> _parseCategories(dynamic raw) {
    if (raw is! List) return const [];
    return raw
        .map(
          (item) => ProductCategoryRef.fromJson(item as Map<String, dynamic>),
        )
        .toList();
  }

  static List<ProductTag> _parseTags(dynamic raw) {
    if (raw is! List) return const [];
    return raw
        .map((item) => ProductTag.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  static List<ProductAttribute> _parseAttributes(dynamic raw) {
    if (raw is! List) return const [];
    return raw
        .map((item) => ProductAttribute.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  static String? _readString(dynamic value) {
    final text = value?.toString().trim();
    if (text == null || text.isEmpty) return null;
    return text;
  }

  @override
  List<Object?> get props => [
    productId,
    titleAr,
    titleEn,
    descriptionAr,
    descriptionEn,
    slug,
    seoTitle,
    seoDescription,
    isAvailable,
    pricing,
    inventory,
    images,
    variants,
    categories,
    tags,
    attributes,
  ];
}

class PricingBlock extends Equatable {
  final dynamic basePrice;
  final dynamic compareAtPrice;
  final String? currencyCode;
  final String? displayPrice;
  final String? displayCompareAt;
  final int? discountPercentage;
  final bool hasDiscount;

  const PricingBlock({
    this.basePrice,
    this.compareAtPrice,
    this.currencyCode,
    this.displayPrice,
    this.displayCompareAt,
    this.discountPercentage,
    this.hasDiscount = false,
  });

  factory PricingBlock.fromJson(Map<String, dynamic> json) {
    return PricingBlock(
      basePrice: json['basePrice'],
      compareAtPrice: json['compareAtPrice'],
      currencyCode: ProductDetail._readString(json['currencyCode']),
      displayPrice: ProductDetail._readString(json['displayPrice']),
      displayCompareAt: ProductDetail._readString(json['displayCompareAt']),
      discountPercentage: (json['discountPercentage'] as num?)?.toInt(),
      hasDiscount: json['hasDiscount'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'basePrice': basePrice,
    'compareAtPrice': compareAtPrice,
    'currencyCode': currencyCode,
    'displayPrice': displayPrice,
    'displayCompareAt': displayCompareAt,
    'discountPercentage': discountPercentage,
    'hasDiscount': hasDiscount,
  };

  @override
  List<Object?> get props => [
    basePrice,
    compareAtPrice,
    currencyCode,
    displayPrice,
    displayCompareAt,
    discountPercentage,
    hasDiscount,
  ];
}

class InventoryBlock extends Equatable {
  final bool isOutOfStock;
  final bool isLowStock;
  final String? stockStatus;

  const InventoryBlock({
    this.isOutOfStock = false,
    this.isLowStock = false,
    this.stockStatus,
  });

  factory InventoryBlock.fromJson(Map<String, dynamic> json) {
    return InventoryBlock(
      isOutOfStock: json['isOutOfStock'] as bool? ?? false,
      isLowStock: json['isLowStock'] as bool? ?? false,
      stockStatus: ProductDetail._readString(json['stockStatus']),
    );
  }

  Map<String, dynamic> toJson() => {
    'isOutOfStock': isOutOfStock,
    'isLowStock': isLowStock,
    'stockStatus': stockStatus,
  };

  @override
  List<Object?> get props => [isOutOfStock, isLowStock, stockStatus];
}

class ProductImage extends Equatable {
  final String? mediaAssetId;
  final String? filename;
  final String? mimeType;
  final String? publicUrl;
  final Map<String, String> thumbnailUrls;
  final int sortOrder;
  final bool isPrimary;
  final String? attachedAt;

  const ProductImage({
    this.mediaAssetId,
    this.filename,
    this.mimeType,
    this.publicUrl,
    this.thumbnailUrls = const {},
    this.sortOrder = 0,
    this.isPrimary = false,
    this.attachedAt,
  });

  factory ProductImage.fromJson(Map<String, dynamic> json) {
    final rawThumbs = json['thumbnailUrls'];
    final thumbs = <String, String>{};
    if (rawThumbs is Map) {
      rawThumbs.forEach((key, value) {
        if (value != null) {
          thumbs[key.toString()] = value.toString();
        }
      });
    }

    return ProductImage(
      mediaAssetId: ProductDetail._readString(json['mediaAssetId']),
      filename: ProductDetail._readString(json['filename']),
      mimeType: ProductDetail._readString(json['mimeType']),
      publicUrl: _resolveBackendUrl(
        ProductDetail._readString(
          json['publicUrl'] ?? json['url'] ?? json['imageUrl'],
        ),
      ),
      thumbnailUrls: thumbs,
      sortOrder: (json['sortOrder'] as num?)?.toInt() ?? 0,
      isPrimary: json['isPrimary'] as bool? ?? false,
      attachedAt: ProductDetail._readString(json['attachedAt']),
    );
  }

  Map<String, dynamic> toJson() => {
    'mediaAssetId': mediaAssetId,
    'filename': filename,
    'mimeType': mimeType,
    'publicUrl': publicUrl,
    'thumbnailUrls': thumbnailUrls,
    'sortOrder': sortOrder,
    'isPrimary': isPrimary,
    'attachedAt': attachedAt,
  };

  static String? _resolveBackendUrl(String? value) {
    final text = value?.trim();
    if (text == null || text.isEmpty) return null;
    final resolved = resolveRemoteImageUrl(text);
    return resolved.isEmpty ? null : resolved;
  }

  @override
  List<Object?> get props => [
    mediaAssetId,
    filename,
    mimeType,
    publicUrl,
    thumbnailUrls,
    sortOrder,
    isPrimary,
    attachedAt,
  ];
}

class ProductVariant extends Equatable {
  final String? variantId;
  final String? sku;
  final dynamic price;
  final dynamic compareAtPrice;
  final int stockQty;
  final int? weightGrams;
  final String? barcode;
  final List<OptionValue> optionValues;
  final bool available;

  const ProductVariant({
    this.variantId,
    this.sku,
    this.price,
    this.compareAtPrice,
    this.stockQty = 0,
    this.weightGrams,
    this.barcode,
    this.optionValues = const [],
    this.available = false,
  });

  factory ProductVariant.fromJson(Map<String, dynamic> json) {
    final rawOptions = json['optionValues'] ?? const [];
    return ProductVariant(
      variantId: ProductDetail._readString(json['variantId']),
      sku: ProductDetail._readString(json['sku']),
      price: json['price'],
      compareAtPrice: json['compareAtPrice'],
      stockQty: (json['stockQty'] as num?)?.toInt() ?? 0,
      weightGrams: (json['weightGrams'] as num?)?.toInt(),
      barcode: ProductDetail._readString(json['barcode']),
      optionValues:
          (rawOptions as List<dynamic>?)
              ?.map(
                (item) => OptionValue.fromJson(item as Map<String, dynamic>),
              )
              .toList() ??
          [],
      available: json['available'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'variantId': variantId,
    'sku': sku,
    'price': price,
    'compareAtPrice': compareAtPrice,
    'stockQty': stockQty,
    'weightGrams': weightGrams,
    'barcode': barcode,
    'optionValues': optionValues.map((item) => item.toJson()).toList(),
    'available': available,
  };

  @override
  List<Object?> get props => [
    variantId,
    sku,
    price,
    compareAtPrice,
    stockQty,
    weightGrams,
    barcode,
    optionValues,
    available,
  ];
}

class OptionValue extends Equatable {
  final String? optionId;
  final String? optionName;
  final String? optionNameAr;
  final String? value;
  final String? valueAr;
  final int sortOrder;

  const OptionValue({
    this.optionId,
    this.optionName,
    this.optionNameAr,
    this.value,
    this.valueAr,
    this.sortOrder = 0,
  });

  factory OptionValue.fromJson(Map<String, dynamic> json) {
    return OptionValue(
      optionId: ProductDetail._readString(json['optionId']),
      optionName: ProductDetail._readString(json['optionName']),
      optionNameAr: ProductDetail._readString(json['optionNameAr']),
      value: ProductDetail._readString(json['value']),
      valueAr: ProductDetail._readString(json['valueAr']),
      sortOrder: (json['sortOrder'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'optionId': optionId,
    'optionName': optionName,
    'optionNameAr': optionNameAr,
    'value': value,
    'valueAr': valueAr,
    'sortOrder': sortOrder,
  };

  @override
  List<Object?> get props => [
    optionId,
    optionName,
    optionNameAr,
    value,
    valueAr,
    sortOrder,
  ];
}

class ProductCategoryRef extends Equatable {
  final String? categoryId;
  final String? nameAr;
  final String? nameEn;
  final String? slug;
  final int depth;

  const ProductCategoryRef({
    this.categoryId,
    this.nameAr,
    this.nameEn,
    this.slug,
    this.depth = 0,
  });

  factory ProductCategoryRef.fromJson(Map<String, dynamic> json) {
    return ProductCategoryRef(
      categoryId: ProductDetail._readString(json['categoryId']),
      nameAr: ProductDetail._readString(json['nameAr']),
      nameEn: ProductDetail._readString(json['nameEn']),
      slug: ProductDetail._readString(json['slug']),
      depth: (json['depth'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'categoryId': categoryId,
    'nameAr': nameAr,
    'nameEn': nameEn,
    'slug': slug,
    'depth': depth,
  };

  String get name {
    final arabic = nameAr?.trim();
    if (arabic != null && arabic.isNotEmpty) return arabic;
    return nameEn?.trim() ?? '';
  }

  @override
  List<Object?> get props => [categoryId, nameAr, nameEn, slug, depth];
}

class ProductTag extends Equatable {
  final String? tagId;
  final String? nameAr;
  final String? nameEn;
  final String? slug;

  const ProductTag({this.tagId, this.nameAr, this.nameEn, this.slug});

  factory ProductTag.fromJson(Map<String, dynamic> json) {
    return ProductTag(
      tagId: ProductDetail._readString(json['tagId']),
      nameAr: ProductDetail._readString(json['nameAr']),
      nameEn: ProductDetail._readString(json['nameEn']),
      slug: ProductDetail._readString(json['slug']),
    );
  }

  Map<String, dynamic> toJson() => {
    'tagId': tagId,
    'nameAr': nameAr,
    'nameEn': nameEn,
    'slug': slug,
  };

  @override
  List<Object?> get props => [tagId, nameAr, nameEn, slug];
}

class ProductAttribute extends Equatable {
  final String? attributeId;
  final String? nameAr;
  final String? nameEn;
  final String? value;
  final String? valueAr;
  final bool visibleOnStorefront;

  const ProductAttribute({
    this.attributeId,
    this.nameAr,
    this.nameEn,
    this.value,
    this.valueAr,
    this.visibleOnStorefront = true,
  });

  factory ProductAttribute.fromJson(Map<String, dynamic> json) {
    return ProductAttribute(
      attributeId: ProductDetail._readString(json['attributeId']),
      nameAr: ProductDetail._readString(json['nameAr']),
      nameEn: ProductDetail._readString(json['nameEn']),
      value: ProductDetail._readString(json['value']),
      valueAr: ProductDetail._readString(json['valueAr']),
      visibleOnStorefront: json['visibleOnStorefront'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
    'attributeId': attributeId,
    'nameAr': nameAr,
    'nameEn': nameEn,
    'value': value,
    'valueAr': valueAr,
    'visibleOnStorefront': visibleOnStorefront,
  };

  @override
  List<Object?> get props => [
    attributeId,
    nameAr,
    nameEn,
    value,
    valueAr,
    visibleOnStorefront,
  ];
}
