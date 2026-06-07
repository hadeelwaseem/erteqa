import 'package:equatable/equatable.dart';

import 'commerce_json_helpers.dart';
import 'enums/payment_status.dart';

/// Response from `GET /public/payments/{txnId}/status` (future Paymera poll).
class PaymentStatusResult extends Equatable {
  const PaymentStatusResult({
    required this.status,
    this.rrn,
    required this.amountMinor,
    this.rawResponse,
  });

  final PaymentStatus status;
  final String? rrn;
  final int amountMinor;
  final String? rawResponse;

  factory PaymentStatusResult.fromJson(Map<String, dynamic> json) {
    return PaymentStatusResult(
      status: PaymentStatus.fromWire(json['status'] as String?),
      rrn: readCommerceString(json['rrn']),
      amountMinor: readCommerceInt(json['amountMinor']),
      rawResponse: readCommerceString(json['rawResponse']),
    );
  }

  factory PaymentStatusResult.fromEnvelopeData(Map<String, dynamic> data) =>
      PaymentStatusResult.fromJson(data);

  Map<String, dynamic> toJson() => {
        'status': status.toWire(),
        if (rrn != null) 'rrn': rrn,
        'amountMinor': amountMinor,
        if (rawResponse != null) 'rawResponse': rawResponse,
      };

  @override
  List<Object?> get props => [status, rrn, amountMinor, rawResponse];
}
