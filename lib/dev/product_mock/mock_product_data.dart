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
    'https://placehold.co/400x400/png?text=Cat+03',
    'https://placehold.co/400x400/png?text=Cat+04',
    'https://placehold.co/400x400/png?text=Cat+05',
    'https://placehold.co/400x400/png?text=Cat+06',
    'https://placehold.co/400x400/png?text=Cat+07',
    'https://placehold.co/400x400/png?text=Cat+08',
    'https://placehold.co/400x400/png?text=Cat+09',
    'https://placehold.co/400x400/png?text=Cat+10',
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
    10,
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
    final slugs = [
      "food-beverage",
      "fashion",
      "electronics",
      "home-garden",
      "beauty",
      "sports",
      "kids",
      "books",
      "automotive",
      "pets",
    ];
    final enNames = [
      "Food & Beverage",
      "Fashion",
      "Electronics",
      "Home & Garden",
      "Beauty & Health",
      "Sports & Outdoors",
      "Kids & Babies",
      "Books & Stationery",
      "Automotive",
      "Pets & Supplies",
    ];
    final arNames = [
      "مأكولات ومشروبات",
      "موضة",
      "إلكترونيات",
      "المنزل والحديقة",
      "الجمال والصحة",
      "رياضة وهواء طلق",
      "الأطفال والرضع",
      "كتب وأدوات مكتبية",
      "السيارات",
      "الحيوانات الأليفة وإمداداتها",
    ];
    final idx = (n - 1);
    final slug = idx < slugs.length ? slugs[idx] : 'category-$n';
    final nameEn = idx < enNames.length ? enNames[idx] : 'Category $n';
    final nameAr = idx < arNames.length ? arNames[idx] : 'تصنيف $n';
    return Category(
      categoryId: 'cat-${n.toString().padLeft(3, '0')}',
      nameAr: nameAr,
      nameEn: nameEn,
      slug: slug,
      imageUrl: _categoryImageUrl(n),
      depth: 0,
      sortOrder: idx,
      isActive: true,
      children: const [],
    );
  }

  /// Mock catalog: product-N belongs to category cat-NNN (cycles across categories).
  static String categoryIdForProduct(Product product) {
    final n = int.tryParse(product.slug?.replaceFirst('product-', '') ?? '') ?? 1;
    final catIndex = ((n - 1) % _categories.length) + 1;
    return 'cat-${catIndex.toString().padLeft(3, '0')}';
  }

  static String categorySlugForProduct(Product product) {
    final catId = categoryIdForProduct(product);
    return _categories
        .firstWhere(
          (c) => c.categoryId == catId,
          orElse: () => _categories.first,
        )
        .slug!;
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

    if (categoryId != null && categoryId.isNotEmpty) {
      filtered = filtered
          .where((p) => categoryIdForProduct(p) == categoryId)
          .toList();
    }

    if (tagId != null && tagId.isNotEmpty) {
      filtered = filtered.where((_) => false).toList();
    }

    if (inStockOnly == true) {
      filtered = filtered.where((p) => p.isAvailable == true).toList();
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

  static List<Map<String, dynamic>> _variantsForProduct(
    int productNumber,
    double basePrice,
  ) {
    final defaultId = 'var-${productNumber.toString().padLeft(3, '0')}-default';
    final defaultVariant = <String, dynamic>{
      'variantId': defaultId,
      'sku': 'SKU-$productNumber',
      'price': basePrice,
      'compareAtPrice': basePrice + 5,
      'stockQty': 10 + productNumber,
      'available': true,
      'optionValues': <Map<String, dynamic>>[],
    };

    if (productNumber > 2) {
      return [defaultVariant];
    }

    final multi = <Map<String, dynamic>>[
      defaultVariant,
      {
        'variantId': 'var-${productNumber.toString().padLeft(3, '0')}-b',
        'sku': 'SKU-$productNumber-B',
        'price': basePrice + 10,
        'compareAtPrice': basePrice + 15,
        'stockQty': 5 + productNumber,
        'available': true,
        'optionValues': [
          {'name': 'Size', 'value': 'M'},
        ],
      },
    ];

    if (productNumber == 1) {
      multi.add({
        'variantId': 'var-001-c',
        'sku': 'SKU-1-C',
        'price': basePrice + 20,
        'compareAtPrice': basePrice + 25,
        'stockQty': 3,
        'available': true,
        'optionValues': [
          {'name': 'Size', 'value': 'L'},
        ],
      });
    }

    return multi;
  }

  static ProductDetail productDetail(String slug) {
    final found = _products.firstWhere(
      (p) => p.slug == slug,
      orElse: () => _products[0],
    );
    final productNumber = min(
      max(_products.indexOf(found) + 1, 1),
      _products.length,
    );
    final detailImages = _detailImageSet(productNumber, found.primaryImageUrl);
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
      'images': detailImages,
      'variants': _variantsForProduct(productNumber, found.basePrice ?? 0),
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

  static List<Map<String, dynamic>> _detailImageSet(
    int productNumber,
    String? primaryImageUrl,
  ) {
    final primary = (primaryImageUrl ?? '').trim();
    final candidates = <String>[
      if (primary.isNotEmpty) primary,
      _productImageUrl(productNumber + 1),
      _productImageUrl(productNumber + 2),
      _productImageUrl(productNumber + 3),
    ];
    final unique = <String>[];
    for (final url in candidates) {
      if (url.isEmpty) continue;
      if (unique.contains(url)) continue;
      unique.add(url);
    }
    return [
      for (var i = 0; i < unique.length; i++)
        {
          'publicUrl': unique[i],
          'isPrimary': i == 0,
          'alt': 'Product ${productNumber.toString().padLeft(2, '0')} Image ${i + 1}',
        },
    ];
  }

  static List<Category> categories() => _categories;

  static Category categoryBySlug(String slug) {
    return _categories.firstWhere(
      (c) => c.slug == slug,
      orElse: () => _categories[0],
    );
  }
}
