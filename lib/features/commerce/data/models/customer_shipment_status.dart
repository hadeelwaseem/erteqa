import 'package:equatable/equatable.dart';

import 'commerce_json_helpers.dart';
import 'enums/shipment_status.dart';
import 'shipment_status_history_entry.dart';

/// Response from `GET /public/shipping/track/{orderId}` (spec Shipment embed).
class CustomerShipmentStatus extends Equatable {
  const CustomerShipmentStatus({
    required this.shipmentId,
    required this.orderId,
    required this.shipmentStatus,
    this.statusLabel,
    this.carrierTrackingUrl,
    this.officePickupInstructions,
    this.deliveredAt,
    required this.createdAt,
    this.statusHistory = const [],
  });

  final String shipmentId;
  final String orderId;
  final ShipmentStatus shipmentStatus;
  final String? statusLabel;
  final String? carrierTrackingUrl;
  final String? officePickupInstructions;
  final String? deliveredAt;
  final String createdAt;
  final List<ShipmentStatusHistoryEntry> statusHistory;

  factory CustomerShipmentStatus.fromJson(Map<String, dynamic> json) {
    return CustomerShipmentStatus(
      shipmentId: readCommerceString(json['shipmentId']) ?? '',
      orderId: readCommerceString(json['orderId']) ?? '',
      shipmentStatus:
          ShipmentStatus.fromWire(json['shipmentStatus'] as String?),
      statusLabel: readCommerceString(json['statusLabel']),
      carrierTrackingUrl: readCommerceString(json['carrierTrackingUrl']),
      officePickupInstructions:
          readCommerceString(json['officePickupInstructions']),
      deliveredAt: readCommerceString(json['deliveredAt']),
      createdAt: readCommerceString(json['createdAt']) ?? '',
      statusHistory: readCommerceList(
        json['statusHistory'],
        ShipmentStatusHistoryEntry.fromJson,
      ),
    );
  }

  factory CustomerShipmentStatus.fromEnvelopeData(Map<String, dynamic> data) =>
      CustomerShipmentStatus.fromJson(data);

  Map<String, dynamic> toJson() => {
        'shipmentId': shipmentId,
        'orderId': orderId,
        'shipmentStatus': shipmentStatus.toWire(),
        if (statusLabel != null) 'statusLabel': statusLabel,
        if (carrierTrackingUrl != null) 'carrierTrackingUrl': carrierTrackingUrl,
        if (officePickupInstructions != null)
          'officePickupInstructions': officePickupInstructions,
        if (deliveredAt != null) 'deliveredAt': deliveredAt,
        'createdAt': createdAt,
        'statusHistory':
            statusHistory.map((entry) => entry.toJson()).toList(),
      };

  @override
  List<Object?> get props => [
        shipmentId,
        orderId,
        shipmentStatus,
        statusLabel,
        carrierTrackingUrl,
        officePickupInstructions,
        deliveredAt,
        createdAt,
        statusHistory,
      ];
}
