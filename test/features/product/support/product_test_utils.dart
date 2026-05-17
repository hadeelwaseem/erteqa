import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';

typedef TestResponseHandler = Future<ResponseBody> Function(RequestOptions options);

class FakeHttpClientAdapter implements HttpClientAdapter {
  FakeHttpClientAdapter(this.handler);

  final TestResponseHandler handler;
  final List<RequestOptions> requests = <RequestOptions>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    return handler(options);
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody jsonResponse(
  Object body, {
  int statusCode = 200,
  Map<String, List<String>>? headers,
}) {
  return ResponseBody.fromString(
    jsonEncode(body),
    statusCode,
    headers: headers ?? const {Headers.contentTypeHeader: [Headers.jsonContentType]},
  );
}

Map<String, dynamic> sampleProductItem({
  String productId = '550e8400-e29b-41d4-a716-446655440000',
  String titleEn = 'Example Product',
}) {
  return {
    'productId': productId,
    'titleAr': 'مثال عن المنتج',
    'titleEn': titleEn,
    'slug': 'example-product',
    'status': 'ACTIVE',
    'primaryImageUrl': null,
    'primaryThumbnailUrl': null,
    'basePrice': 1500.50,
    'compareAtPrice': 2000.00,
    'currencyCode': 'SYP',
    'displayPrice': '1,500.50 SYP',
    'discountPercentage': 25,
    'hasDiscount': true,
    'variantCount': 3,
    'totalStock': 45,
    'stockStatus': 'IN_STOCK',
    'isAvailable': true,
    'createdAt': '2026-05-15T10:30:00',
    'updatedAt': '2026-05-16T14:30:00',
  };
}

Map<String, dynamic> browseProductsEnvelope({
  List<Map<String, dynamic>>? items,
  bool hasNext = true,
  int page = 0,
  int size = 20,
}) {
  return {
    'success': true,
    'message': null,
    'data': items ?? [sampleProductItem()],
    'meta': {
      'page': page,
      'size': size,
      'total': 150,
      'totalPages': 8,
      'hasNext': hasNext,
      'hasPrev': page > 0,
    },
    'timestamp': 1715824800000,
  };
}

Map<String, dynamic> categoryProductsEnvelope({
  List<Map<String, dynamic>>? items,
  bool hasNext = false,
}) {
  return browseProductsEnvelope(items: items, hasNext: hasNext);
}

Map<String, dynamic> sampleAutocompleteItem({
  String productId = '550e8400-e29b-41d4-a716-446655440001',
  String titleEn = 'Smart Phone',
}) {
  return {
    'productId': productId,
    'titleAr': 'هاتف ذكي',
    'titleEn': titleEn,
    'slug': 'smart-phone',
    'basePrice': 1500.00,
    'thumbnailUrl': '/uploads/phone-thumb.jpg',
  };
}

Map<String, dynamic> searchEnvelope({
  List<Map<String, dynamic>>? products,
  List<String>? suggestions,
  List<Map<String, dynamic>>? popularProducts,
  bool hasNext = true,
  int page = 0,
  int size = 20,
  String query = 'phone',
}) {
  return {
    'success': true,
    'message': null,
    'data': {
      'query': query,
      'products': products ?? [sampleProductItem()],
      'meta': {
        'page': page,
        'size': size,
        'total': 42,
        'totalPages': 3,
        'hasNext': hasNext,
        'hasPrev': page > 0,
        'last': !hasNext,
      },
      'suggestions': suggestions ?? const [],
      'popularProducts': popularProducts ?? const [],
      'totalResults': products?.length ?? (products == null ? 1 : 0),
    },
    'timestamp': 1715824800000,
  };
}

Map<String, dynamic> autocompleteEnvelope({
  List<Map<String, dynamic>>? products,
  List<String>? suggestions,
}) {
  return {
    'success': true,
    'message': null,
    'data': {
      'products': products ?? [sampleAutocompleteItem()],
      'suggestions': suggestions ?? const ['phone cases'],
    },
    'timestamp': 1715824800000,
  };
}

Map<String, dynamic> sampleProductDetailData({
  String slug = 'example-product',
  bool includeVariants = true,
}) {
  final data = <String, dynamic>{
    'productId': '550e8400-e29b-41d4-a716-446655440000',
    'titleAr': 'مثال عن المنتج',
    'titleEn': 'Example Product',
    'slug': slug,
    'isAvailable': true,
    'pricing': {
      'basePrice': 1500.50,
      'displayPrice': '1,500.50 SYP',
      'currencyCode': 'SYP',
      'hasDiscount': false,
    },
    'inventory': {
      'stockStatus': 'IN_STOCK',
      'isOutOfStock': false,
      'isLowStock': false,
    },
    'images': [
      {
        'mediaAssetId': 'img-1',
        'publicUrl': '/uploads/product.jpg',
        'thumbnailUrls': {'150': '/uploads/product-150.jpg'},
        'isPrimary': true,
      },
    ],
    'categories': [
      {
        'categoryId': 'cat-1',
        'nameAr': 'إلكترونيات',
        'nameEn': 'Electronics',
        'slug': 'electronics',
      },
    ],
    'tags': [
      {
        'tagId': 'tag-1',
        'nameAr': 'جديد',
        'nameEn': 'New',
        'slug': 'new',
      },
    ],
  };

  if (includeVariants) {
    data['variants'] = [
      {
        'variantId': 'var-1',
        'sku': 'SKU-001',
        'price': 1500.50,
        'stockQty': 10,
        'available': true,
        'optionValues': [
          {
            'optionId': 'opt-1',
            'optionName': 'Color',
            'value': 'Black',
          },
        ],
      },
    ];
  }

  return data;
}

Map<String, dynamic> productDetailEnvelope({
  Map<String, dynamic>? data,
}) {
  return {
    'success': true,
    'message': null,
    'data': data ?? sampleProductDetailData(),
    'timestamp': 1715824800000,
  };
}

Map<String, dynamic> sampleCategoryItem({
  String slug = 'electronics',
  List<Map<String, dynamic>>? children,
}) {
  return {
    'categoryId': 'cat-$slug',
    'nameAr': 'إلكترونيات',
    'nameEn': 'Electronics',
    'slug': slug,
    'imageUrl': '/uploads/category.jpg',
    'depth': 0,
    'sortOrder': 1,
    'isActive': true,
    'children': children ?? const [],
  };
}

Map<String, dynamic> categoryTreeEnvelope({
  List<Map<String, dynamic>>? categories,
}) {
  return {
    'success': true,
    'message': null,
    'data': categories ??
        [
          sampleCategoryItem(
            children: [
              sampleCategoryItem(slug: 'phones'),
            ],
          ),
        ],
    'timestamp': 1715824800000,
  };
}

Map<String, dynamic> singleCategoryEnvelope({String slug = 'electronics'}) {
  return {
    'success': true,
    'message': null,
    'data': sampleCategoryItem(
      slug: slug,
      children: [sampleCategoryItem(slug: 'phones')],
    ),
    'timestamp': 1715824800000,
  };
}
