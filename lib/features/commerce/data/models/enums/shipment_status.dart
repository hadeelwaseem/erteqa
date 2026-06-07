/// Shipment carrier lifecycle (spec §0.5).
enum ShipmentStatus {
  pending('PENDING'),
  pickedUp('PICKED_UP'),
  inTransit('IN_TRANSIT'),
  readyForPickupAtOffice('READY_FOR_PICKUP_AT_OFFICE'),
  delivered('DELIVERED'),
  failed('FAILED'),
  returned('RETURNED'),
  unknown('');

  const ShipmentStatus(this.wireValue);

  final String wireValue;

  static ShipmentStatus fromWire(String? value) {
    if (value == null || value.isEmpty) return unknown;
    for (final status in ShipmentStatus.values) {
      if (status.wireValue == value) return status;
    }
    return unknown;
  }

  String toWire() => wireValue;
}
