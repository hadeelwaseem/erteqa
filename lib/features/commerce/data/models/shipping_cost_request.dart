import 'package:equatable/equatable.dart';

import 'commerce_json_helpers.dart';

/// Body for `POST /public/shipping/calculate` (spec §2.2).
class ShippingCostRequest extends Equatable {
  const ShippingCostRequest({
    required this.originLat,
    required this.originLng,
    required this.destinationLat,
    required this.destinationLng,
    this.shippingProviderId,
  });

  final double originLat;
  final double originLng;
  final double destinationLat;
  final double destinationLng;
  final String? shippingProviderId;

  factory ShippingCostRequest.fromJson(Map<String, dynamic> json) {
    return ShippingCostRequest(
      originLat: readCommerceDouble(json['originLat']),
      originLng: readCommerceDouble(json['originLng']),
      destinationLat: readCommerceDouble(json['destinationLat']),
      destinationLng: readCommerceDouble(json['destinationLng']),
      shippingProviderId: readCommerceString(json['shippingProviderId']),
    );
  }

  Map<String, dynamic> toJson() => {
        'originLat': originLat,
        'originLng': originLng,
        'destinationLat': destinationLat,
        'destinationLng': destinationLng,
        if (shippingProviderId != null)
          'shippingProviderId': shippingProviderId,
      };

  @override
  List<Object?> get props => [
        originLat,
        originLng,
        destinationLat,
        destinationLng,
        shippingProviderId,
      ];
}
