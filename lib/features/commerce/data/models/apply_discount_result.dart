import 'package:equatable/equatable.dart';

import 'commerce_json_helpers.dart';
import 'enums/discount_type.dart';

/// Response from `GET /public/checkout/validate-discount` (spec §2.3).
class ApplyDiscountResult extends Equatable {
  const ApplyDiscountResult({
    required this.discountCodeId,
    required this.code,
    required this.discountType,
    required this.appliedAmount,
  });

  final String discountCodeId;
  final String code;
  final DiscountType discountType;
  final int appliedAmount;

  factory ApplyDiscountResult.fromJson(Map<String, dynamic> json) {
    return ApplyDiscountResult(
      discountCodeId: readCommerceString(json['discountCodeId']) ?? '',
      code: readCommerceString(json['code']) ?? '',
      discountType: DiscountType.fromWire(json['discountType'] as String?),
      appliedAmount: readCommerceInt(json['appliedAmount']),
    );
  }

  factory ApplyDiscountResult.fromEnvelopeData(Map<String, dynamic> data) =>
      ApplyDiscountResult.fromJson(data);

  Map<String, dynamic> toJson() => {
        'discountCodeId': discountCodeId,
        'code': code,
        'discountType': discountType.toWire(),
        'appliedAmount': appliedAmount,
      };

  @override
  List<Object?> get props => [
        discountCodeId,
        code,
        discountType,
        appliedAmount,
      ];
}
