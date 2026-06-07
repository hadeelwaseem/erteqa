/// Discount application type from validate-discount response.
enum DiscountType {
  percentage('PERCENTAGE'),
  unknown('');

  const DiscountType(this.wireValue);

  final String wireValue;

  static DiscountType fromWire(String? value) {
    if (value == null || value.isEmpty) return unknown;
    for (final type in DiscountType.values) {
      if (type.wireValue == value) return type;
    }
    return unknown;
  }

  String toWire() => wireValue;
}
