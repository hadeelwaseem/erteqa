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
