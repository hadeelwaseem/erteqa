import 'package:equatable/equatable.dart';

import 'commerce_json_helpers.dart';

/// Response from `GET /customer/orders/{orderId}/invoice` (spec §8).
class InvoiceResponse extends Equatable {
  const InvoiceResponse({
    required this.invoiceId,
    required this.orderId,
    required this.invoiceNumber,
    required this.pdfUrl,
    required this.generatedAt,
  });

  final String invoiceId;
  final String orderId;
  final String invoiceNumber;
  final String pdfUrl;
  final String generatedAt;

  factory InvoiceResponse.fromJson(Map<String, dynamic> json) {
    return InvoiceResponse(
      invoiceId: readCommerceString(json['invoiceId']) ?? '',
      orderId: readCommerceString(json['orderId']) ?? '',
      invoiceNumber: readCommerceString(json['invoiceNumber']) ?? '',
      pdfUrl: readCommerceString(json['pdfUrl']) ?? '',
      generatedAt: readCommerceString(json['generatedAt']) ?? '',
    );
  }

  factory InvoiceResponse.fromEnvelopeData(Map<String, dynamic> data) =>
      InvoiceResponse.fromJson(data);

  Map<String, dynamic> toJson() => {
        'invoiceId': invoiceId,
        'orderId': orderId,
        'invoiceNumber': invoiceNumber,
        'pdfUrl': pdfUrl,
        'generatedAt': generatedAt,
      };

  @override
  List<Object?> get props => [
        invoiceId,
        orderId,
        invoiceNumber,
        pdfUrl,
        generatedAt,
      ];
}
