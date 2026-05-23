import 'package:equatable/equatable.dart';
import 'package:get_it/get_it.dart';
import 'package:sooq_merchant/core/network/network_config.dart';
import 'package:sooq_merchant/core/utils/constants.dart';

class Category extends Equatable {
  final String? categoryId;
  final String? parentCategoryId;
  final String? nameAr;
  final String? nameEn;
  final String? slug;
  final String? descriptionAr;
  final String? descriptionEn;
  final String? imageUrl;
  final int depth;
  final int sortOrder;
  final bool isActive;
  final List<Category> children;
  final String? createdAt;

  const Category({
    this.categoryId,
    this.parentCategoryId,
    this.nameAr,
    this.nameEn,
    this.slug,
    this.descriptionAr,
    this.descriptionEn,
    this.imageUrl,
    this.depth = 0,
    this.sortOrder = 0,
    this.isActive = true,
    this.children = const [],
    this.createdAt,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    final rawChildren = json['children'] ?? const [];
    return Category(
      categoryId: _readString(json['categoryId'] ?? json['id']),
      parentCategoryId: _readString(json['parentCategoryId']),
      nameAr: _readString(json['nameAr']),
      nameEn: _readString(json['nameEn']),
      slug: _readString(json['slug']),
      descriptionAr: _readString(json['descriptionAr']),
      descriptionEn: _readString(json['descriptionEn']),
      imageUrl: _resolveBackendUrl(_readString(json['imageUrl'])),
      depth: (json['depth'] as num?)?.toInt() ?? 0,
      sortOrder: (json['sortOrder'] as num?)?.toInt() ?? 0,
      isActive: json['isActive'] as bool? ?? true,
      children:
          (rawChildren as List<dynamic>?)
              ?.map((item) => Category.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [],
      createdAt: _readString(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'categoryId': categoryId,
      'parentCategoryId': parentCategoryId,
      'nameAr': nameAr,
      'nameEn': nameEn,
      'name': name,
      'imageUrl': imageUrl,
      'slug': slug,
      'descriptionAr': descriptionAr,
      'descriptionEn': descriptionEn,
      'imageUrl': imageUrl,
      'depth': depth,
      'sortOrder': sortOrder,
      'isActive': isActive,
      'children': children.map((item) => item.toJson()).toList(),
      'createdAt': createdAt,
    };
  }

  String get name {
    final arabic = nameAr?.trim();
    if (arabic != null && arabic.isNotEmpty) return arabic;
    final english = nameEn?.trim();
    if (english != null && english.isNotEmpty) return english;
    return '';
  }

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
    categoryId,
    parentCategoryId,
    nameAr,
    nameEn,
    slug,
    descriptionAr,
    descriptionEn,
    imageUrl,
    depth,
    sortOrder,
    isActive,
    children,
    createdAt,
  ];
}
