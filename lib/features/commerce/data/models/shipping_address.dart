import 'package:equatable/equatable.dart';

import 'commerce_json_helpers.dart';

/// Shipping address on checkout and order detail (GPS + recipient).
class ShippingAddress extends Equatable {
  const ShippingAddress({
    required this.latitude,
    required this.longitude,
    required this.recipientName,
    required this.phone,
    this.addressLabel,
  });

  final double latitude;
  final double longitude;
  final String recipientName;
  final String phone;
  final String? addressLabel;

  factory ShippingAddress.fromJson(Map<String, dynamic> json) {
    return ShippingAddress(
      latitude: readCommerceDouble(json['latitude']),
      longitude: readCommerceDouble(json['longitude']),
      recipientName: readCommerceString(json['recipientName']) ?? '',
      phone: readCommerceString(json['phone']) ?? '',
      addressLabel: readCommerceString(json['addressLabel']),
    );
  }

  factory ShippingAddress.fromEnvelopeData(Map<String, dynamic> data) =>
      ShippingAddress.fromJson(data);

  Map<String, dynamic> toJson() => {
        'latitude': latitude,
        'longitude': longitude,
        'recipientName': recipientName,
        'phone': phone,
        if (addressLabel != null) 'addressLabel': addressLabel,
      };

  @override
  List<Object?> get props => [
        latitude,
        longitude,
        recipientName,
        phone,
        addressLabel,
      ];
}
