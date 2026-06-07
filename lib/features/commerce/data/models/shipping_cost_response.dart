import 'package:equatable/equatable.dart';

import 'commerce_json_helpers.dart';

/// Response from `POST /public/shipping/calculate` (spec §2.2).
class ShippingCostResponse extends Equatable {
  const ShippingCostResponse({
    required this.shippingCostSyp,
    required this.providerCode,
    required this.providerName,
    required this.estimatedDeliveryHours,
  });

  final int shippingCostSyp;
  final String providerCode;
  final String providerName;
  final int estimatedDeliveryHours;

  factory ShippingCostResponse.fromJson(Map<String, dynamic> json) {
    return ShippingCostResponse(
      shippingCostSyp: readCommerceInt(json['shippingCostSyp']),
      providerCode: readCommerceString(json['providerCode']) ?? '',
      providerName: readCommerceString(json['providerName']) ?? '',
      estimatedDeliveryHours:
          readCommerceInt(json['estimatedDeliveryHours']),
    );
  }

  factory ShippingCostResponse.fromEnvelopeData(Map<String, dynamic> data) =>
      ShippingCostResponse.fromJson(data);

  Map<String, dynamic> toJson() => {
        'shippingCostSyp': shippingCostSyp,
        'providerCode': providerCode,
        'providerName': providerName,
        'estimatedDeliveryHours': estimatedDeliveryHours,
      };

  @override
  List<Object?> get props => [
        shippingCostSyp,
        providerCode,
        providerName,
        estimatedDeliveryHours,
      ];
}
