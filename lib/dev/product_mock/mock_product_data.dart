import 'dart:math';

import 'package:sooq_merchant/dev/product_mock/product_mock_config.dart';
import 'package:sooq_merchant/features/product/data/models/product.dart';
import 'package:sooq_merchant/features/product/data/models/product_list_response.dart';
import 'package:sooq_merchant/features/product/data/models/product_meta.dart';
import 'package:sooq_merchant/features/product/data/models/product_search_result.dart';
import 'package:sooq_merchant/features/product/data/models/product_autocomplete_result.dart';
import 'package:sooq_merchant/features/product/data/models/product_detail.dart';
import 'package:sooq_merchant/features/product/data/models/category.dart';
import 'package:sooq_merchant/features/product/data/models/autocomplete_product_item.dart';

class MockProductData {
  MockProductData._();

  /// Distinct HTTPS catalog images (placehold.co — reliable on real devices).
  ///
  /// Do not use picsum.photos here; many mobile networks get CDN "Global locked" / 403.
  static const List<String> _kMockProductImageUrls = [
    'https://placehold.co/600x600/png?text=Prod+01',
    'https://placehold.co/600x600/png?text=Prod+02',
    'https://placehold.co/600x600/png?text=Prod+03',
    'https://placehold.co/600x600/png?text=Prod+04',
    'https://placehold.co/600x600/png?text=Prod+05',
    'https://placehold.co/600x600/png?text=Prod+06',
    'https://placehold.co/600x600/png?text=Prod+07',
    'https://placehold.co/600x600/png?text=Prod+08',
    'https://placehold.co/600x600/png?text=Prod+09',
    'https://placehold.co/600x600/png?text=Prod+10',
    'https://placehold.co/600x600/png?text=Prod+11',
    'https://placehold.co/600x600/png?text=Prod+12',
    'https://placehold.co/600x600/png?text=Prod+13',
    'https://placehold.co/600x600/png?text=Prod+14',
    'https://placehold.co/600x600/png?text=Prod+15',
  ];

  static const List<String> _kMockCategoryImageUrls = [
    'https://placehold.co/400x400/png?text=Cat+01',
    'https://placehold.co/400x400/png?text=Cat+02',
  ];

  static String _productImageUrl(int n) =>
      _kMockProductImageUrls[(n - 1) % _kMockProductImageUrls.length];

  static String _productThumbnailUrl(int n) {
    final label = n.toString().padLeft(2, '0');
    return 'https://placehold.co/200x200/png?text=P$label';
  }

  static String _categoryImageUrl(int n) =>
      _kMockCategoryImageUrls[(n - 1) % _kMockCategoryImageUrls.length];

  static final List<Product> _products = List.generate(
    ProductMockConfig.sampleProductCount,
    (i) => _sampleProduct(i + 1),
  );

  static final List<Category> _categories = List.generate(
    ProductMockConfig.sampleCategoryCount,
    (i) => _sampleCategory(i + 1),
  );

  static Product _sampleProduct(int n) {
    final id = 'prod-${n.toString().padLeft(3, '0')}';
    final slug = 'product-$n';
    final titleEn = 'Sample Product $n';
    final titleAr = 'منتج تجريبي $n';
    final basePrice = (10 + n * 5).toDouble();
    final compareAt = (basePrice + 5).toDouble();
    final hasDiscount = basePrice < compareAt;

    return Product(
      id: id,
      productId: id,
      slug: slug,
      titleAr: titleAr,
      titleEn: titleEn,
      status: 'ACTIVE',
      primaryImageUrl: _productImageUrl(n),
      primaryThumbnailUrl: _productThumbnailUrl(n),
      basePrice: basePrice,
      compareAtPrice: compareAt,
      currencyCode: 'AED',
      displayPrice: '$basePrice AED',
      discountPercentage: hasDiscount ? 10.0 : 0.0,
      hasDiscount: hasDiscount,
      variantCount: 1,
      totalStock: 10 + n,
      stockStatus: 'IN_STOCK',
      isAvailable: true,
      createdAt: DateTime.now().toUtc().toIso8601String(),
      updatedAt: DateTime.now().toUtc().toIso8601String(),
    );
  }

  static Category _sampleCategory(int n) {
    final slug = 'category-$n';
    return Category(
      categoryId: 'cat-${n.toString().padLeft(3, '0')}',
      nameAr: 'تصنيف $n',
      nameEn: 'Category $n',
      slug: slug,
      imageUrl: _categoryImageUrl(n),
      depth: 0,
      sortOrder: 0,
      isActive: true,
      children: const [],
    );
  }

  static ProductListResponse productList({
    required int page,
    required int size,
    String? sort,
  }) {
    final total = _products.length;
    final totalPages = (total / size).ceil();
    final pageIndex = page;
    final start = pageIndex * size;
    final end = min(start + size, total);
    final slice = start >= total ? <Product>[] : _products.sublist(start, end);

    final meta = ProductMeta(
      page: pageIndex,
      size: size,
      total: total,
      totalPages: totalPages,
      hasNext: pageIndex < (totalPages - 1),
      hasPrev: pageIndex > 0,
      last: pageIndex >= (totalPages - 1),
    );

    return ProductListResponse(
      success: true,
      message: null,
      data: slice,
      meta: meta,
      timestamp: DateTime.now().toUtc().millisecondsSinceEpoch,
    );
  }

  static ProductSearchResult search({
    String? q,
    String? categoryId,
    String? tagId,
    double? minPrice,
    double? maxPrice,
    bool? inStockOnly,
    required int page,
    required int size,
    String? sort,
  }) {
    var filtered = _products;
    if (q != null && q.isNotEmpty) {
      final term = q.toLowerCase();
      filtered = filtered
          .where(
            (p) =>
                (p.titleEn ?? '').toLowerCase().contains(term) ||
                (p.titleAr ?? '').toLowerCase().contains(term),
          )
          .toList();
    }

    if (minPrice != null) {
      filtered = filtered
          .where((p) => (p.basePrice as num).toDouble() >= minPrice)
          .toList();
    }
    if (maxPrice != null) {
      filtered = filtered
          .where((p) => (p.basePrice as num).toDouble() <= maxPrice)
          .toList();
    }

    final total = filtered.length;
    final totalPages = (total / size).ceil();
    final pageIndex = page;
    final start = pageIndex * size;
    final end = min(start + size, total);
    final slice = start >= total ? <Product>[] : filtered.sublist(start, end);

    final meta = ProductMeta(
      page: pageIndex,
      size: size,
      total: total,
      totalPages: totalPages,
      hasNext: pageIndex < (totalPages - 1),
      hasPrev: pageIndex > 0,
      last: pageIndex >= (totalPages - 1),
    );

    final suggestions = filtered.take(5).map((p) => p.titleEn ?? '').toList();

    return ProductSearchResult(
      query: q,
      products: slice,
      meta: meta,
      suggestions: suggestions,
      popularProducts: filtered.take(3).toList(),
      totalResults: total,
    );
  }

  static ProductAutocompleteResult autocomplete({required String q}) {
    if (q.isEmpty) return ProductAutocompleteResult.empty;

    final term = q.toLowerCase();
    final matches = _products
        .where(
          (p) =>
              (p.titleEn ?? '').toLowerCase().contains(term) ||
              (p.titleAr ?? '').toLowerCase().contains(term),
        )
        .take(7)
        .map(
          (p) => AutocompleteProductItem(
            productId: p.productId,
            titleAr: p.titleAr,
            titleEn: p.titleEn,
            slug: p.slug,
            basePrice: p.basePrice,
            thumbnailUrl: p.primaryThumbnailUrl,
          ),
        )
        .toList();

    final suggestions = matches.map((m) => m.titleEn ?? '').toList();

    return ProductAutocompleteResult(
      products: matches,
      suggestions: suggestions,
    );
  }

  static ProductDetail productDetail(String slug) {
    final found = _products.firstWhere(
      (p) => p.slug == slug,
      orElse: () => _products[0],
    );
    return ProductDetail.fromEnvelopeData({
      'productId': found.productId ?? found.id,
      'titleAr': found.titleAr,
      'titleEn': found.titleEn,
      'descriptionAr': '${found.titleAr} وصف تجريبي',
      'descriptionEn': '${found.titleEn} sample description',
      'slug': found.slug,
      'isAvailable': true,
      'pricing': {
        'basePrice': found.basePrice,
        'compareAtPrice': found.compareAtPrice,
        'currency': found.currencyCode,
        'displayPrice': found.displayPrice,
      },
      'inventory': {'stockStatus': 'IN_STOCK'},
      'images': [
        {'publicUrl': found.primaryImageUrl, 'isPrimary': true},
      ],
      'variants': [],
      'categories': [
        {
          'categoryId': _categories[0].categoryId,
          'nameEn': _categories[0].nameEn,
          'slug': _categories[0].slug,
        },
      ],
      'tags': [],
      'attributes': [],
    });
  }

  static List<Category> categories() => _categories;

  static Category categoryBySlug(String slug) {
    return _categories.firstWhere(
      (c) => c.slug == slug,
      orElse: () => _categories[0],
    );
  }
}
