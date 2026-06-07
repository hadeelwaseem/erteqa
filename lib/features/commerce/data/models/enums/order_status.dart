/// Customer order lifecycle (spec §0.5).
enum OrderStatus {
  pending('PENDING'),
  confirmed('CONFIRMED'),
  processing('PROCESSING'),
  shipped('SHIPPED'),
  delivered('DELIVERED'),
  completed('COMPLETED'),
  cancelled('CANCELLED'),
  returned('RETURNED'),
  refunded('REFUNDED'),
  failed('FAILED'),
  unknown('');

  const OrderStatus(this.wireValue);

  final String wireValue;

  static OrderStatus fromWire(String? value) {
    if (value == null || value.isEmpty) return unknown;
    for (final status in OrderStatus.values) {
      if (status.wireValue == value) return status;
    }
    return unknown;
  }

  String toWire() => wireValue;
}
