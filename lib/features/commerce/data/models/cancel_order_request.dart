import 'package:equatable/equatable.dart';

import 'commerce_json_helpers.dart';

/// Optional body for `POST /customer/orders/{orderId}/cancel` (spec §7).
class CancelOrderRequest extends Equatable {
  const CancelOrderRequest({this.reason});

  final String? reason;

  factory CancelOrderRequest.fromJson(Map<String, dynamic> json) {
    return CancelOrderRequest(
      reason: readCommerceString(json['reason']),
    );
  }

  Map<String, dynamic> toJson() => {
        if (reason != null) 'reason': reason,
      };

  @override
  List<Object?> get props => [reason];
}
