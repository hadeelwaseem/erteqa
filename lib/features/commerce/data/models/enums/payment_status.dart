/// Order payment lifecycle (spec §0.5).
enum PaymentStatus {
  unpaid('UNPAID'),
  pending('PENDING'),
  paid('PAID'),
  failed('FAILED'),
  refunded('REFUNDED'),
  unknown('');

  const PaymentStatus(this.wireValue);

  final String wireValue;

  static PaymentStatus fromWire(String? value) {
    if (value == null || value.isEmpty) return unknown;
    for (final status in PaymentStatus.values) {
      if (status.wireValue == value) return status;
    }
    return unknown;
  }

  String toWire() => wireValue;
}
