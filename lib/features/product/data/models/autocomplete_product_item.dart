import 'package:equatable/equatable.dart';
import 'package:sooq_merchant/core/network/remote_image_url.dart';

class AutocompleteProductItem extends Equatable {
  final String? productId;
  final String? titleAr;
  final String? titleEn;
  final String? slug;
  final dynamic basePrice;
  final String? primaryImageUrl;
  final String? thumbnailUrl;

  const AutocompleteProductItem({
    this.productId,
    this.titleAr,
    this.titleEn,
    this.slug,
    this.basePrice,
    this.primaryImageUrl,
    this.thumbnailUrl,
  });

  factory AutocompleteProductItem.fromJson(Map<String, dynamic> json) {
    return AutocompleteProductItem(
      productId: _readString(json['productId'] ?? json['id']),
      titleAr: _readString(json['titleAr']),
      titleEn: _readString(json['titleEn']),
      slug: _readString(json['slug']),
      basePrice: json['basePrice'],
      primaryImageUrl: _resolveBackendUrl(
        _readString(
          json['primaryImageUrl'] ?? json['imageUrl'] ?? json['image'],
        ),
      ),
      thumbnailUrl: _resolveBackendUrl(
        _readString(json['thumbnailUrl'] ?? json['primaryThumbnailUrl']),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'productId': productId,
      'titleAr': titleAr,
      'titleEn': titleEn,
      'slug': slug,
      'basePrice': basePrice,
      'primaryImageUrl': primaryImageUrl,
      'thumbnailUrl': thumbnailUrl,
      'name': name,
      'image': image,
    };
  }

  String get name {
    final arabic = titleAr?.trim();
    if (arabic != null && arabic.isNotEmpty) return arabic;
    final english = titleEn?.trim();
    if (english != null && english.isNotEmpty) return english;
    return '';
  }

  String get image => primaryImageUrl ?? thumbnailUrl ?? '';

  static String? _readString(dynamic value) {
    final text = value?.toString().trim();
    if (text == null || text.isEmpty) return null;
    return text;
  }

  static String? _resolveBackendUrl(String? value) {
    final text = value?.trim();
    if (text == null || text.isEmpty) return null;
    final resolved = resolveRemoteImageUrl(text);
    return resolved.isEmpty ? null : resolved;
  }

  @override
  List<Object?> get props => [
    productId,
    titleAr,
    titleEn,
    slug,
    basePrice,
    primaryImageUrl,
    thumbnailUrl,
  ];
}
