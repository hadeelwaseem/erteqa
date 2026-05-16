# Customer Product Module — Complete Flutter Integration Guide

## Overview

This is a comprehensive, self-contained guide for integrating the Customer Product Module from ShopEngine into a Flutter application. This guide covers **only** the customer-facing product endpoints (storefront browsing, search, autocomplete, product detail, and category navigation). It excludes all admin, vendor management, and internal backend services.

## Covered Endpoints

| Endpoint | Method | Purpose |
|----------|--------|---------|
| `/api/v1/public/products` | GET | Browse active products with pagination |
| `/api/v1/public/products/search` | GET | Search products with filters and pagination |
| `/api/v1/public/products/autocomplete` | GET | Search-as-you-type autocomplete suggestions |
| `/api/v1/public/products/{slug}` | GET | Get product detail with conditional response blocks |
| `/api/v1/public/categories` | GET | Get hierarchical category tree |
| `/api/v1/public/categories/{slug}` | GET | Get single category by slug |
| `/api/v1/public/categories/{slug}/products` | GET | Get paginated products in a category |

## Common API Characteristics

### Authentication
- All endpoints under `/api/v1/public/*` are **public** and require **no authentication**.
- No `Authorization` headers are needed.
- No API keys or tokens are required.

### Response Structure
All responses follow a standard wrapper format:

**Non-Paginated Response:**
```json
{
  "success": true,
  "message": null,
  "data": { /* specific response data */ },
  "timestamp": 1715824800000
}
```

**Paginated Response:**
```json
{
  "success": true,
  "message": null,
  "data": [ /* array of items */ ],
  "meta": {
    "page": 0,
    "size": 20,
    "total": 150,
    "totalPages": 8,
    "hasNext": true,
    "hasPrev": false
  },
  "timestamp": 1715824800000
}
```

### Pagination Parameters
For endpoints returning lists, use these query parameters:
- `page` (integer, 0-based): Page number. Default: 0
- `size` (integer): Items per page. Default: 20
- `sort` (string): Sort clause, e.g., `createdAt,desc` or `basePrice,asc`

### Timestamps
All timestamp fields are ISO 8601 format (UTC): `2026-05-16T14:30:00`

### Currency
- `currencyCode` is ISO 4217 format (e.g., "SYP", "USD")
- Prices are numeric (BigDecimal in backend → `double` in Flutter)
- Use a dedicated decimal package (e.g., `decimal`) for financial calculations to avoid floating-point rounding errors

## Endpoint 1: Browse All Products

### Purpose
Display the storefront "Shop All" product list with merchandising-ready product cards suitable for grid/list layouts.

### Request

**Endpoint:** `GET /api/v1/public/products`

**Query Parameters:**
| Parameter | Type | Default | Notes |
|-----------|------|---------|-------|
| `page` | integer | 0 | 0-based page number |
| `size` | integer | 20 | Items per page |
| `sort` | string | `createdAt` | Sort clause, e.g., `basePrice,asc` or `createdAt,desc` |

**Example Request:**
```
GET /api/v1/public/products?page=0&size=20&sort=createdAt,desc
```

### Response

**Response Type:** `PagedApiResponse<ProductListItem>`

**ProductListItem Data Model:**
```json
{
  "productId": "550e8400-e29b-41d4-a716-446655440000",
  "titleAr": "مثال عن المنتج",
  "titleEn": "Example Product",
  "slug": "example-product",
  "status": "ACTIVE",
  "primaryImageUrl": "https://cdn.example.com/products/550e8400/full.jpg",
  "primaryThumbnailUrl": "https://cdn.example.com/products/550e8400/thumb-150.jpg",
  "basePrice": 1500.50,
  "compareAtPrice": 2000.00,
  "currencyCode": "SYP",
  "displayPrice": "1,500.50 SYP",
  "discountPercentage": 25,
  "hasDiscount": true,
  "variantCount": 3,
  "totalStock": 45,
  "stockStatus": "IN_STOCK",
  "isAvailable": true,
  "createdAt": "2026-05-15T10:30:00",
  "updatedAt": "2026-05-16T14:30:00"
}
```

**Complete Response Example:**
```json
{
  "success": true,
  "message": null,
  "data": [
    { /* ProductListItem */ },
    { /* ProductListItem */ }
  ],
  "meta": {
    "page": 0,
    "size": 20,
    "total": 150,
    "totalPages": 8,
    "hasNext": true,
    "hasPrev": false
  },
  "timestamp": 1715824800000
}
```

### Data Model Details

**ProductListItem Field Descriptions:**

| Field | Type | Nullable | Description |
|-------|------|----------|-------------|
| `productId` | UUID (String) | No | Unique product identifier |
| `titleAr` | String | No | Product title in Arabic |
| `titleEn` | String | No | Product title in English |
| `slug` | String | No | URL-friendly product slug |
| `status` | String | No | Product status: `DRAFT`, `ACTIVE`, `ARCHIVED` |
| `primaryImageUrl` | String | Yes | Full-size primary image URL; may be null |
| `primaryThumbnailUrl` | String | Yes | Thumbnail (150px) of primary image; may be null |
| `basePrice` | Decimal | No | Base selling price |
| `compareAtPrice` | Decimal | Yes | Compare-at/original price; null if no comparison |
| `currencyCode` | String | No | ISO 4217 currency code (e.g., "SYP") |
| `displayPrice` | String | No | Formatted price string ready for display (e.g., "1,500.50 SYP") |
| `discountPercentage` | Integer | Yes | Discount as percentage; null if no discount |
| `hasDiscount` | Boolean | No | Whether product has active discount |
| `variantCount` | Integer | No | Number of product variants available |
| `totalStock` | Integer | No | Total stock across all variants |
| `stockStatus` | String | No | Stock status: `IN_STOCK`, `LOW_STOCK`, `OUT_OF_STOCK` |
| `isAvailable` | Boolean | No | Whether product can be purchased |
| `createdAt` | ISO DateTime | No | When product was created |
| `updatedAt` | ISO DateTime | No | When product was last updated |

### Pagination & Sorting Behavior

- **Default sort:** `createdAt` (newest first)
- **Supported sorts:** `createdAt`, `basePrice`, and other product attributes
- **Page numbering:** 0-based (page 0 = first page)
- **Empty results:** Server returns empty data array and pagination meta with `total: 0`

### Flutter Implementation Guidance

**Dart Model (using `freezed` + `json_serializable`):**
```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'product_list_item.freezed.dart';
part 'product_list_item.g.dart';

@freezed
class ProductListItem with _$ProductListItem {
  const factory ProductListItem({
    @JsonKey(name: 'productId') required String id,
    required String titleAr,
    required String titleEn,
    required String slug,
    required String status,
    String? primaryImageUrl,
    String? primaryThumbnailUrl,
    required double basePrice,
    double? compareAtPrice,
    required String currencyCode,
    required String displayPrice,
    int? discountPercentage,
    required bool hasDiscount,
    required int variantCount,
    required int totalStock,
    required String stockStatus,
    required bool isAvailable,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _ProductListItem;

  factory ProductListItem.fromJson(Map<String, dynamic> json) =>
      _$ProductListItemFromJson(json);
}
```

**Handle Missing Images:** 
- Always check if `primaryImageUrl` and `primaryThumbnailUrl` are null before displaying
- Use a placeholder/skeleton image while loading
- Implement retry logic for failed image loads

**Currency Display:**
- Use the `displayPrice` field directly for UI (already formatted by server)
- Do not reformat prices on the client side
- Store `basePrice` and `compareAtPrice` as high-precision decimals if performing calculations

### Error Handling

| Status Code | Error Condition | Recommended UX Action |
|-------------|-----------------|----------------------|
| 200 | Success | Display products and pagination controls |
| 400 | Invalid page/size parameters | Show validation error; validate client input |
| 500 | Server error | Show generic error message; allow user retry |
| 429 | Rate limit exceeded | Show cooldown message; implement backoff |

### Caching Strategy

- **Cache key:** `products_page_{page}_size_{size}_sort_{sort}`
- **TTL:** 5–15 minutes for category/search results, 1–2 minutes for frequent updates
- **Invalidation:** Refresh on app resume or after user action (add to cart, wishlist)
- **Offline support:** Keep 1–2 pages cached for offline browsing

### Performance Considerations

- **Pagination:** Avoid prefetching all pages; lazy-load on scroll (infinite scroll)
- **Image loading:** Load thumbnails first, then upgrade to full images on demand
- **Debouncing:** Not needed for pagination; can load on scroll immediately
- **Network timeout:** Set to 10–15 seconds per request

---

## Endpoint 2: Search Products

### Purpose
Full-text product search with filtering by category, tags, price range, and stock status. Includes empty-state fallback (suggestions and popular products).

### Request

**Endpoint:** `GET /api/v1/public/products/search`

**Query Parameters:**
| Parameter | Type | Required | Notes |
|-----------|------|----------|-------|
| `q` | String | No | Search query (Arabic, English, or mixed); if empty, returns active products |
| `categoryId` | UUID | No | Filter by category UUID |
| `tagId` | UUID | No | Filter by tag UUID |
| `minPrice` | Decimal | No | Minimum price filter |
| `maxPrice` | Decimal | No | Maximum price filter |
| `inStockOnly` | Boolean | No | If true, return only in-stock products |
| `page` | Integer | No | 0-based page number; default 0 |
| `size` | Integer | No | Items per page; default 20 |
| `sort` | String | No | Sort clause; default `createdAt,desc` |

**Example Requests:**
```
# Basic search
GET /api/v1/public/products/search?q=phone&page=0&size=20

# Search with filters
GET /api/v1/public/products/search?q=phone&categoryId=abc-123&minPrice=100&maxPrice=1000&inStockOnly=true

# Price filter only (no query)
GET /api/v1/public/products/search?minPrice=50&maxPrice=500&page=0&size=20
```

### Response

**Response Type:** `ApiResponse<ProductSearchResult>`

**ProductSearchResult Data Model:**
```json
{
  "query": "phone",
  "products": [
    { /* ProductListItem */ },
    { /* ProductListItem */ }
  ],
  "meta": {
    "page": 0,
    "size": 20,
    "total": 42,
    "totalPages": 3,
    "hasNext": true,
    "hasPrev": false
  },
  "suggestions": [
    "phones with warranty",
    "phone cases",
    "phone chargers"
  ],
  "popularProducts": [
    { /* ProductListItem */ },
    { /* ProductListItem */ }
  ],
  "totalResults": 42
}
```

**ProductSearchResult Field Descriptions:**

| Field | Type | Description |
|-------|------|-------------|
| `query` | String | Echoed search query |
| `products` | Array | List of ProductListItem matching query |
| `meta` | PaginationMeta | Pagination metadata |
| `suggestions` | Array<String> | Did-you-mean suggestions (only if results empty) |
| `popularProducts` | Array<ProductListItem> | Popular/trending products fallback (only if results empty) |
| `totalResults` | Integer | Total count of matching products |

### Flutter Implementation Guidance

**Search Debouncing:**
```dart
// Debounce search input to avoid excessive API calls
final searchController = TextEditingController();
Timer? _searchTimer;

void onSearchChanged(String query) {
  _searchTimer?.cancel();
  _searchTimer = Timer(const Duration(milliseconds: 300), () {
    // Trigger search API call
    searchProducts(query);
  });
}
```

**Handle Empty Results:**
1. Check `if (result.products.isEmpty)`
2. Display `result.suggestions` as "Did you mean?" links
3. Display `result.popularProducts` as "Popular products"
4. Allow user to tap suggestions to refine search

**Cancel In-Flight Requests:**
- Use `CancelToken` in `dio` to cancel previous search requests when new query is entered
- Prevents race conditions where older results overwrite newer ones

**Filter State Management:**
- Store selected filters (`categoryId`, `minPrice`, `maxPrice`, `inStockOnly`) in a notifier/bloc
- Rebuild search request when any filter changes
- Persist filter selections for UX continuity

### Error Handling

| Status Code | Condition | UX Action |
|-------------|-----------|-----------|
| 200 | Success (with or without results) | Display results; show suggestions if empty |
| 400 | Invalid filter values (e.g., malformed UUID) | Show validation error |
| 500 | Server error | Show error message; allow retry |
| 429 | Rate limit | Show cooldown message |

### Caching Strategy

- **Do not cache search results** (user expects fresh results)
- **Cache filter metadata** (categories, tags, price ranges) — useful for filter UI
- **Cache suggestions** (did-you-mean, popular products) with 1-day TTL

---

## Endpoint 3: Search Autocomplete

### Purpose
Provide real-time search-as-you-type suggestions with minimal latency for a search bar.

### Request

**Endpoint:** `GET /api/v1/public/products/autocomplete`

**Query Parameters:**
| Parameter | Type | Required | Notes |
|-----------|------|----------|-------|
| `q` | String | Yes | Search query; minimum 3 characters required |

**Example Requests:**
```
GET /api/v1/public/products/autocomplete?q=pho
GET /api/v1/public/products/autocomplete?q=هاتف
```

### Response

**Response Type:** `ApiResponse<AutocompleteResult>`

**AutocompleteResult Data Model:**
```json
{
  "products": [
    {
      "productId": "550e8400-e29b-41d4-a716-446655440000",
      "titleAr": "هاتف ذكي",
      "titleEn": "Smart Phone",
      "slug": "smart-phone",
      "basePrice": 1500.00,
      "thumbnailUrl": "https://cdn.example.com/products/550e8400/thumb-150.jpg"
    },
    { /* More autocomplete items */ }
  ],
  "suggestions": [
    "phone cases",
    "phone chargers",
    "phone protectors"
  ]
}
```

**AutocompleteItem Field Descriptions:**

| Field | Type | Nullable | Description |
|-------|------|----------|-------------|
| `productId` | UUID (String) | No | Product identifier |
| `titleAr` | String | No | Arabic product title |
| `titleEn` | String | No | English product title |
| `slug` | String | No | URL-friendly product slug |
| `basePrice` | Decimal | No | Product price |
| `thumbnailUrl` | String | Yes | Small thumbnail URL (150px) |

### Flutter Implementation Guidance

**Client-Side Validation:**
- Enforce minimum length of 3 characters before making API call
- Cancel previous requests when new input arrives (race condition prevention)

```dart
void onAutocompleteInput(String text) {
  if (text.length < 3) {
    clearSuggestions();
    return;
  }
  _autocompleteTimer?.cancel();
  _autocompleteTimer = Timer(const Duration(milliseconds: 300), () {
    fetchAutocompleteSuggestions(text);
  });
}
```

**Display Suggestions:**
- Show product suggestions with small thumbnails in a dropdown
- Show text suggestions below product suggestions
- Tapping a product should navigate to product detail
- Tapping a text suggestion should trigger full search with that query

### Error Handling

| Status Code | Condition | UX Action |
|-------------|-----------|-----------|
| 200 | Success | Show results (may be empty) |
| 400 | Query < 3 characters | Don't show error; silently no results |
| 500 | Server error | Don't disrupt UX; show empty suggestions |

### Caching Strategy

- **Do not cache** (autocomplete should be fresh)
- **Debounce aggressively** (300–500ms) to reduce API calls

---

## Endpoint 4: Product Detail

### Purpose
Retrieve complete product information by slug with conditional response blocks. Allows client to request only needed data (pricing, images, variants, etc.).

### Request

**Endpoint:** `GET /api/v1/public/products/{slug}`

**Path Parameters:**
| Parameter | Type | Description |
|-----------|------|-------------|
| `slug` | String | URL-friendly product slug (lowercase, hyphens) |

**Query Parameters:**
| Parameter | Type | Notes |
|-----------|------|-------|
| `include` | String (comma-separated) | Optional blocks to include. Default: `PRICING,IMAGES,VARIANTS,CATEGORIES,TAGS` |

**Include Block Options:**
- `PRICING` — pricing and discount information
- `IMAGES` — product images and thumbnails
- `VARIANTS` — variant list with options
- `CATEGORIES` — product categories
- `TAGS` — product tags
- `ATTRIBUTES` — storefront-visible custom attributes
- `INVENTORY` — stock status (no raw numbers)

**Example Requests:**
```
# Default blocks (no include param)
GET /api/v1/public/products/example-product

# Minimal (only pricing and images)
GET /api/v1/public/products/example-product?include=PRICING,IMAGES

# All blocks
GET /api/v1/public/products/example-product?include=PRICING,IMAGES,VARIANTS,CATEGORIES,TAGS,ATTRIBUTES,INVENTORY
```

### Response

**Response Type:** `ApiResponse<ProductDetail>`

**ProductDetail Data Model:**
```json
{
  "productId": "550e8400-e29b-41d4-a716-446655440000",
  "titleAr": "منتج مثال",
  "titleEn": "Example Product",
  "descriptionAr": "وصف المنتج بالعربية",
  "descriptionEn": "Product description in English",
  "slug": "example-product",
  "seoTitle": "Example Product | Store Name",
  "seoDescription": "High-quality example product with fast shipping",
  "isAvailable": true,
  "pricing": {
    "basePrice": 1500.50,
    "compareAtPrice": 2000.00,
    "currencyCode": "SYP",
    "displayPrice": "1,500.50 SYP",
    "displayCompareAt": "2,000.00 SYP",
    "discountPercentage": 25,
    "hasDiscount": true
  },
  "inventory": {
    "isOutOfStock": false,
    "isLowStock": false,
    "stockStatus": "IN_STOCK"
  },
  "images": [
    {
      "mediaAssetId": "asset-uuid-1",
      "filename": "product-front.jpg",
      "mimeType": "image/jpeg",
      "publicUrl": "https://cdn.example.com/products/asset-uuid-1/full.jpg",
      "thumbnailUrls": {
        "150": "https://cdn.example.com/products/asset-uuid-1/thumb-150.jpg",
        "300": "https://cdn.example.com/products/asset-uuid-1/thumb-300.jpg",
        "600": "https://cdn.example.com/products/asset-uuid-1/thumb-600.jpg"
      },
      "sortOrder": 0,
      "isPrimary": true,
      "attachedAt": "2026-05-01T10:00:00"
    }
  ],
  "variants": [
    {
      "variantId": "variant-uuid-1",
      "sku": "PROD-SKU-001",
      "price": 1500.50,
      "compareAtPrice": 2000.00,
      "stockQty": 25,
      "weightGrams": 150,
      "barcode": "1234567890123",
      "optionValues": [
        {
          "optionId": "option-uuid-1",
          "optionName": "Color",
          "optionNameAr": "اللون",
          "value": "Red",
          "valueAr": "أحمر",
          "sortOrder": 0
        }
      ],
      "available": true
    }
  ],
  "categories": [
    {
      "categoryId": "cat-uuid-1",
      "nameAr": "الإلكترونيات",
      "nameEn": "Electronics",
      "slug": "electronics",
      "depth": 0
    }
  ],
  "tags": [
    {
      "tagId": "tag-uuid-1",
      "nameAr": "جديد",
      "nameEn": "New",
      "slug": "new"
    }
  ],
  "attributes": [
    {
      "attributeId": "attr-uuid-1",
      "nameAr": "اللون",
      "nameEn": "Color",
      "value": "Red",
      "valueAr": "أحمر",
      "visibleOnStorefront": true
    }
  ]
}
```

**ProductDetail Field Descriptions:**

| Field | Type | Nullable | Description |
|-------|------|----------|-------------|
| `productId` | UUID (String) | No | Product identifier |
| `titleAr` | String | No | Arabic title |
| `titleEn` | String | No | English title |
| `descriptionAr` | String | Yes | Arabic description |
| `descriptionEn` | String | Yes | English description |
| `slug` | String | No | URL slug |
| `seoTitle` | String | Yes | SEO meta title |
| `seoDescription` | String | Yes | SEO meta description |
| `isAvailable` | Boolean | No | Whether product can be purchased |
| `pricing` | PricingBlock | Conditional | Included if `include` contains `PRICING` |
| `inventory` | InventoryBlock | Conditional | Included if `include` contains `INVENTORY` |
| `images` | Array<ProductImage> | Conditional | Included if `include` contains `IMAGES` |
| `variants` | Array<Variant> | Conditional | Included if `include` contains `VARIANTS` |
| `categories` | Array<Category> | Conditional | Included if `include` contains `CATEGORIES` |
| `tags` | Array<Tag> | Conditional | Included if `include` contains `TAGS` |
| `attributes` | Array<Attribute> | Conditional | Included if `include` contains `ATTRIBUTES` |

**PricingBlock Details:**

| Field | Type | Nullable | Description |
|-------|------|----------|-------------|
| `basePrice` | Decimal | No | Base selling price |
| `compareAtPrice` | Decimal | Yes | Compare-at/original price |
| `currencyCode` | String | No | ISO 4217 currency |
| `displayPrice` | String | No | Formatted price for display |
| `displayCompareAt` | String | Yes | Formatted compare-at price |
| `discountPercentage` | Integer | Yes | Discount percentage |
| `hasDiscount` | Boolean | No | Whether discount exists |

**InventoryBlock Details:**

| Field | Type | Description |
|-------|------|-------------|
| `isOutOfStock` | Boolean | Whether product is out of stock |
| `isLowStock` | Boolean | Whether product has low stock |
| `stockStatus` | String | Status: `IN_STOCK`, `LOW_STOCK`, `OUT_OF_STOCK` |

**ProductImage Details:**

| Field | Type | Nullable | Description |
|-------|------|----------|-------------|
| `mediaAssetId` | UUID (String) | No | Unique media identifier |
| `filename` | String | No | Original filename |
| `mimeType` | String | No | MIME type (e.g., "image/jpeg") |
| `publicUrl` | String | Yes | Full-size image URL |
| `thumbnailUrls` | Map<Integer, String> | No | Thumbnails by width (150, 300, 600 pixels) |
| `sortOrder` | Integer | No | Display order (0-based) |
| `isPrimary` | Boolean | No | Whether this is the hero/main image |
| `attachedAt` | ISO DateTime | No | When image was attached |

**Variant Details:**

| Field | Type | Nullable | Description |
|-------|------|----------|-------------|
| `variantId` | UUID (String) | No | Variant identifier |
| `sku` | String | No | Stock keeping unit |
| `price` | Decimal | No | Variant price |
| `compareAtPrice` | Decimal | Yes | Variant compare-at price |
| `stockQty` | Integer | No | Available stock quantity |
| `weightGrams` | Integer | Yes | Weight in grams |
| `barcode` | String | Yes | Product barcode |
| `optionValues` | Array<OptionValue> | No | Option selections (e.g., Color: Red) |
| `available` | Boolean | No | Whether variant can be purchased |

**OptionValue Details:**

| Field | Type | Nullable | Description |
|-------|------|----------|-------------|
| `optionId` | UUID (String) | No | Option type identifier |
| `optionName` | String | No | Option name (English) |
| `optionNameAr` | String | Yes | Option name (Arabic) |
| `value` | String | No | Option value (English) |
| `valueAr` | String | Yes | Option value (Arabic) |
| `sortOrder` | Integer | No | Display order |

**Category Details:**

| Field | Type | Nullable | Description |
|-------|------|----------|-------------|
| `categoryId` | UUID (String) | No | Category identifier |
| `nameAr` | String | No | Category name (Arabic) |
| `nameEn` | String | No | Category name (English) |
| `slug` | String | No | Category slug |
| `depth` | Integer | No | Category depth (0 = root, 1 = subcategory, etc.) |

**Tag Details:**

| Field | Type | Nullable | Description |
|-------|------|----------|-------------|
| `tagId` | UUID (String) | No | Tag identifier |
| `nameAr` | String | No | Tag name (Arabic) |
| `nameEn` | String | No | Tag name (English) |
| `slug` | String | No | Tag slug |

**Attribute Details:**

| Field | Type | Nullable | Description |
|-------|------|----------|-------------|
| `attributeId` | UUID (String) | No | Attribute identifier |
| `nameAr` | String | No | Attribute name (Arabic) |
| `nameEn` | String | No | Attribute name (English) |
| `value` | String | Yes | Attribute value |
| `valueAr` | String | Yes | Attribute value (Arabic) |
| `visibleOnStorefront` | Boolean | No | Whether visible to customers |

### Flutter Implementation Guidance

**Request Strategy:**
- Request only blocks needed for your UI to reduce payload size and latency
- For product list → request only minimal blocks needed
- For detail page → request all blocks

**Variant Selector UI:**
```dart
// Build variant selector from optionValues
Map<String, List<String>> buildOptionMatrix(List<Variant> variants) {
  Map<String, Set<String>> options = {};
  for (var variant in variants) {
    for (var optionValue in variant.optionValues) {
      options.putIfAbsent(optionValue.optionName, () => {})
          .add(optionValue.value);
    }
  }
  return options.map((k, v) => MapEntry(k, v.toList()));
}

// Find variant by selected options
Variant? findVariant(List<Variant> variants, Map<String, String> selectedOptions) {
  return variants.firstWhereOrNull((v) {
    return v.optionValues.every((ov) =>
        selectedOptions[ov.optionName] == ov.value);
  });
}
```

**Image Gallery:**
- Order images by `sortOrder`
- Use `isPrimary` to identify hero image for initial display
- Load low-res thumbnail first, then upgrade to full resolution
- Handle missing `publicUrl` gracefully

**Bilingual Content:**
- Use `titleAr`/`titleEn` and `descriptionAr`/`descriptionEn`
- Use app's current locale to select which language to display
- Fallback to English if Arabic not available

### Error Handling

| Status Code | Condition | UX Action |
|-------------|-----------|-----------|
| 200 | Success | Display product |
| 404 | Slug not found | Show "Product not found" error page |
| 500 | Server error | Show error message; allow retry |

### Caching Strategy

- **Cache key:** `product_{slug}_{include_blocks_sorted}`
- **TTL:** 10–30 minutes (longer for stable product data)
- **ETag:** Use `If-None-Match` header if server provides ETags
- **Invalidation:** Invalidate on user actions (add to cart, wishlist, review)

### Edge Cases

- **Single-variant products:** Variant selector may not be needed; check `variants.length == 1`
- **Missing images:** Display placeholder; don't block product display
- **Oversell allowed:** Product may be `available: true` even with `stockQty: 0`
- **No description:** `descriptionAr`/`descriptionEn` may be null; handle gracefully
- **Null prices:** Rare but possible; show placeholder or error

---

## Endpoint 5: Category Tree

### Purpose
Retrieve the hierarchical category structure for storefront navigation (breadcrumbs, menus).

### Request

**Endpoint:** `GET /api/v1/public/categories`

**Query Parameters:** None

**Example Request:**
```
GET /api/v1/public/categories
```

### Response

**Response Type:** `ApiResponse<Array<Category>>`

**Category Data Model (Hierarchical):**
```json
[
  {
    "categoryId": "cat-uuid-1",
    "parentCategoryId": null,
    "nameAr": "الإلكترونيات",
    "nameEn": "Electronics",
    "slug": "electronics",
    "descriptionAr": "جميع الأجهزة الإلكترونية",
    "descriptionEn": "All electronic devices",
    "imageUrl": "https://cdn.example.com/categories/cat-uuid-1.jpg",
    "depth": 0,
    "sortOrder": 1,
    "isActive": true,
    "children": [
      {
        "categoryId": "cat-uuid-2",
        "parentCategoryId": "cat-uuid-1",
        "nameAr": "الهواتف الذكية",
        "nameEn": "Smart Phones",
        "slug": "smart-phones",
        "descriptionAr": null,
        "descriptionEn": null,
        "imageUrl": null,
        "depth": 1,
        "sortOrder": 1,
        "isActive": true,
        "children": []
      }
    ],
    "createdAt": "2026-01-01T00:00:00"
  }
]
```

**Category Field Descriptions:**

| Field | Type | Nullable | Description |
|-------|------|----------|-------------|
| `categoryId` | UUID (String) | No | Category identifier |
| `parentCategoryId` | UUID (String) | Yes | Parent category UUID; null for root |
| `nameAr` | String | No | Arabic name |
| `nameEn` | String | No | English name |
| `slug` | String | No | URL slug |
| `descriptionAr` | String | Yes | Arabic description |
| `descriptionEn` | String | Yes | English description |
| `imageUrl` | String | Yes | Category image/icon URL |
| `depth` | Integer | No | Nesting level (0 = root, 1 = subcategory, max 2) |
| `sortOrder` | Integer | No | Display order (0-based) |
| `isActive` | Boolean | No | Whether category is visible to customers |
| `children` | Array<Category> | No | Child categories (nested recursively) |
| `createdAt` | ISO DateTime | No | When category was created |

### Flutter Implementation Guidance

**Parse Hierarchy:**
```dart
class CategoryTree {
  final List<Category> rootCategories;

  CategoryTree(List<Category> allCategories) {
    rootCategories = allCategories
        .where((c) => c.parentCategoryId == null)
        .toList();
  }

  List<Category> getChildren(String categoryId) {
    // Recursive search through tree
    for (var root in rootCategories) {
      var result = _findChildren(root, categoryId);
      if (result.isNotEmpty) return result;
    }
    return [];
  }

  List<Category> _findChildren(Category node, String targetId) {
    if (node.categoryId == targetId) return node.children;
    for (var child in node.children) {
      var result = _findChildren(child, targetId);
      if (result.isNotEmpty) return result;
    }
    return [];
  }
}
```

**UI Implementation:**
- Use tree structure for hierarchical menu/drawer
- Display root categories at top level
- Expand/collapse children on tap
- Use `sortOrder` to maintain display order
- Show category image if available

### Caching Strategy

- **TTL:** 1 day (category structure is stable)
- **Cache key:** `categories_tree`
- **Refresh:** On app startup; refresh on user request

### Error Handling

| Status Code | Condition | UX Action |
|-------------|-----------|-----------|
| 200 | Success | Display category tree |
| 500 | Server error | Show cached tree if available; show error otherwise |

---

## Endpoint 6: Single Category

### Purpose
Retrieve a single category by slug with its immediate children.

### Request

**Endpoint:** `GET /api/v1/public/categories/{slug}`

**Path Parameters:**
| Parameter | Type | Description |
|-----------|------|-------------|
| `slug` | String | URL-friendly category slug |

**Example Request:**
```
GET /api/v1/public/categories/electronics
```

### Response

**Response Type:** `ApiResponse<Category>`

Returns a single `Category` object (same schema as category tree endpoint) with immediate children populated.

### Error Handling

| Status Code | Condition | UX Action |
|-------------|-----------|-----------|
| 200 | Success | Display category |
| 404 | Slug not found | Show "Category not found" error |
| 500 | Server error | Show error message; allow retry |

---

## Endpoint 7: Products in Category

### Purpose
List products within a specific category with pagination (for category browsing).

### Request

**Endpoint:** `GET /api/v1/public/categories/{slug}/products`

**Path Parameters:**
| Parameter | Type | Description |
|-----------|------|-------------|
| `slug` | String | Category URL slug |

**Query Parameters:**
| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `page` | Integer | 0 | 0-based page number |
| `size` | Integer | 20 | Items per page |
| `sort` | String | `createdAt` | Sort clause |

**Example Request:**
```
GET /api/v1/public/categories/electronics/products?page=0&size=20&sort=basePrice,asc
```

### Response

**Response Type:** `PagedApiResponse<ProductListItem>`

Returns paginated array of `ProductListItem` (same as browse products endpoint).

### Error Handling

| Status Code | Condition | UX Action |
|-------------|-----------|-----------|
| 200 | Success (may be empty) | Display products or empty state |
| 404 | Category not found | Show "Category not found" error |
| 500 | Server error | Show error message; allow retry |

---

## Error Responses

All endpoints follow a consistent error response format:

**Error Response (4xx/5xx):**
```json
{
  "success": false,
  "message": "Specific error description",
  "data": null,
  "timestamp": 1715824800000
}
```

**Common HTTP Status Codes:**

| Code | Meaning | Retry? |
|------|---------|--------|
| 200 | Success | No |
| 400 | Bad request (invalid params) | No (fix params) |
| 404 | Not found | No |
| 429 | Rate limited | Yes (with backoff) |
| 500 | Internal server error | Yes (with backoff) |
| 502 | Bad gateway | Yes |
| 503 | Service unavailable | Yes |

**Recommended Error Handling Flow:**
```dart
Future<T> apiCall<T>(Future<T> Function() request) async {
  int retryCount = 0;
  const maxRetries = 3;

  while (retryCount < maxRetries) {
    try {
      return await request();
    } on DioException catch (e) {
      if (e.isNoConnectionError) {
        throw OfflineException();
      }
      if (e.response?.statusCode == 429) {
        // Rate limited: wait before retry
        await Future.delayed(Duration(seconds: 2 << retryCount));
        retryCount++;
        continue;
      }
      if (e.response?.statusCode == 500 || e.response?.statusCode == 503) {
        // Server error: exponential backoff
        if (retryCount < maxRetries - 1) {
          await Future.delayed(Duration(seconds: 2 << retryCount));
          retryCount++;
          continue;
        }
      }
      rethrow;
    }
  }
  throw Exception('Max retries exceeded');
}
```

---

## State Management Recommendations

### Riverpod Approach

**Suggested provider structure:**

```dart
// Repository providers
final catalogRepositoryProvider = Provider((ref) => CatalogRepository());

// State notifiers for list management
final productsPageProvider = StateNotifierProvider<
    PaginatedProductNotifier,
    AsyncValue<PaginatedProducts>
>((ref) {
  final repo = ref.watch(catalogRepositoryProvider);
  return PaginatedProductNotifier(repo);
});

final searchProvider = StateNotifierProvider<
    SearchNotifier,
    AsyncValue<SearchResults>
>((ref) {
  final repo = ref.watch(catalogRepositoryProvider);
  return SearchNotifier(repo);
});

final productDetailProvider = FutureProvider.family<ProductDetail, String>(
    (ref, slug) async {
  final repo = ref.watch(catalogRepositoryProvider);
  return repo.getProductDetail(slug);
});

// Category tree (cached)
final categoryTreeProvider = FutureProvider<List<Category>>((ref) async {
  final repo = ref.watch(catalogRepositoryProvider);
  return repo.getCategories();
});
```

### Bloc Approach

**Suggested event/state hierarchy:**

```dart
// Events
abstract class CatalogEvent extends Equatable {}
class FetchProductsPage extends CatalogEvent {
  final int page;
  final int size;
  final String? sort;
}

// States
abstract class CatalogState extends Equatable {}
class ProductsLoading extends CatalogState {}
class ProductsLoaded extends CatalogState {
  final List<ProductListItem> products;
  final PaginationMeta meta;
}
class ProductsError extends CatalogState {
  final String message;
}
```

### Common Patterns

1. **List Pagination:**
   - Store current page + size in state
   - Implement `loadMore()` to increment page
   - Reuse repository layer for data fetching

2. **Search Debouncing:**
   - Debounce user input in UI layer
   - Cancel previous search requests
   - Store search results in separate state

3. **Caching:**
   - Keep 2–3 pages in memory cache
   - Invalidate on specific events (cart update, login)
   - Use persistent cache for offline support

4. **Image Loading:**
   - Use `cached_network_image` package
   - Load thumbnails with progressive upgrade
   - Handle placeholder / error states

---

## Implementation Checklist

- [ ] Create Dart data models for all response types (use `freezed` + `json_serializable`)
- [ ] Implement `CatalogRepository` with all endpoints
- [ ] Configure `dio` with interceptors and base URL
- [ ] Implement state management (Riverpod or Bloc)
- [ ] Build search with debounce logic
- [ ] Build product list with infinite scroll / pagination
- [ ] Build product detail page with conditional includes
- [ ] Build category navigation UI
- [ ] Implement caching strategy
- [ ] Add error handling and user feedback
- [ ] Test with real backend API
- [ ] Implement unit tests for repository and state management

---

## Quick Reference: API Summary

| Endpoint | Method | Auth Required | Paginated | Purpose |
|----------|--------|---------------|-----------|---------|
| `/api/v1/public/products` | GET | No | Yes | Browse products |
| `/api/v1/public/products/search` | GET | No | Yes | Search with filters |
| `/api/v1/public/products/autocomplete` | GET | No | No | Search suggestions |
| `/api/v1/public/products/{slug}` | GET | No | No | Product detail |
| `/api/v1/public/categories` | GET | No | No | Category tree |
| `/api/v1/public/categories/{slug}` | GET | No | No | Single category |
| `/api/v1/public/categories/{slug}/products` | GET | No | Yes | Category products |
