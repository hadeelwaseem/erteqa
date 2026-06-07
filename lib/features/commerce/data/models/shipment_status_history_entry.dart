import 'package:equatable/equatable.dart';

import 'commerce_json_helpers.dart';
import 'enums/shipment_status.dart';

/// Single status transition in shipment history (spec Shipment embed).
class ShipmentStatusHistoryEntry extends Equatable {
  const ShipmentStatusHistoryEntry({
    required this.status,
    required this.timestamp,
  });

  final ShipmentStatus status;
  final String timestamp;

  factory ShipmentStatusHistoryEntry.fromJson(Map<String, dynamic> json) {
    return ShipmentStatusHistoryEntry(
      status: ShipmentStatus.fromWire(json['status'] as String?),
      timestamp: readCommerceString(json['timestamp']) ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'status': status.toWire(),
        'timestamp': timestamp,
      };

  @override
  List<Object?> get props => [status, timestamp];
}
