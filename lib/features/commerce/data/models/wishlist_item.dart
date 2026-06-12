import 'package:equatable/equatable.dart';

import 'commerce_json_helpers.dart';

/// Local wishlist entry persisted on device.
class WishlistItem extends Equatable {
  const WishlistItem({
    required this.productId,
    required this.productTitle,
    this.thumbnailUrl,
    this.displayPrice,
  });

  final String productId;
  final String productTitle;
  final String? thumbnailUrl;
  final String? displayPrice;

  factory WishlistItem.fromJson(Map<String, dynamic> json) {
    return WishlistItem(
      productId: readCommerceString(json['productId']) ?? '',
      productTitle: readCommerceString(json['productTitle']) ?? '',
      thumbnailUrl: readCommerceString(json['thumbnailUrl']),
      displayPrice: readCommerceString(json['displayPrice']),
    );
  }

  Map<String, dynamic> toJson() => {
        'productId': productId,
        'productTitle': productTitle,
        if (thumbnailUrl != null) 'thumbnailUrl': thumbnailUrl,
        if (displayPrice != null) 'displayPrice': displayPrice,
      };

  WishlistItem copyWith({
    String? productId,
    String? productTitle,
    String? thumbnailUrl,
    String? displayPrice,
  }) {
    return WishlistItem(
      productId: productId ?? this.productId,
      productTitle: productTitle ?? this.productTitle,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      displayPrice: displayPrice ?? this.displayPrice,
    );
  }

  @override
  List<Object?> get props => [productId, productTitle, thumbnailUrl, displayPrice];
}
