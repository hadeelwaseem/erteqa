import 'package:equatable/equatable.dart';
import 'package:get_it/get_it.dart';
import 'package:sooq_merchant/core/network/network_config.dart';
import 'package:sooq_merchant/core/utils/constants.dart';

class AutocompleteProductItem extends Equatable {
  final String? productId;
  final String? titleAr;
  final String? titleEn;
  final String? slug;
  final dynamic basePrice;
  final String? thumbnailUrl;

  const AutocompleteProductItem({
    this.productId,
    this.titleAr,
    this.titleEn,
    this.slug,
    this.basePrice,
    this.thumbnailUrl,
  });

  factory AutocompleteProductItem.fromJson(Map<String, dynamic> json) {
    return AutocompleteProductItem(
      productId: _readString(json['productId'] ?? json['id']),
      titleAr: _readString(json['titleAr']),
      titleEn: _readString(json['titleEn']),
      slug: _readString(json['slug']),
      basePrice: json['basePrice'],
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

  String get image => thumbnailUrl ?? '';

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
      final assetBase = GetIt.I.isRegistered<NetworkConfig>()
          ? GetIt.I<NetworkConfig>().assetBaseUrl
          : kBaseUrlAsset;
      return '$assetBase$text';
    }
    return text;
  }

  @override
  List<Object?> get props => [
    productId,
    titleAr,
    titleEn,
    slug,
    basePrice,
    thumbnailUrl,
  ];
}
