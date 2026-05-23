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
      primaryImageUrl:
          'https://images.unsplash.com/photo-1542291026-7eec264c27ff?w=600&q=80',
      primaryThumbnailUrl:
          'https://images.unsplash.com/photo-1542291026-7eec264c27ff?w=200&q=80',
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
      imageUrl:
          'https://images.unsplash.com/photo-1521572163474-6864f9cf17ab?w=400&q=80',
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
