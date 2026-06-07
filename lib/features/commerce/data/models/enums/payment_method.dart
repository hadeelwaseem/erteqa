/// Checkout payment method provider code (spec §0.5).
enum PaymentMethod {
  cod('COD'),
  paymera('PAYMERA'),
  unknown('');

  const PaymentMethod(this.wireValue);

  final String wireValue;

  static PaymentMethod fromWire(String? value) {
    if (value == null || value.isEmpty) return unknown;
    for (final method in PaymentMethod.values) {
      if (method.wireValue == value) return method;
    }
    return unknown;
  }

  String toWire() => wireValue;
}
