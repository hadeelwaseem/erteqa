/// Syrian Pound (SYP) amounts — spec: JSON numbers as non-fractional integers.
class SypAmount {
  const SypAmount(this.value);

  final int value;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is SypAmount && other.value == value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => formatSyp(value);
}

/// Formats [amount] as integer SYP with thousands separators and ل.س suffix.
String formatSyp(int amount) {
  final negative = amount < 0;
  final digits = amount.abs().toString();
  final buffer = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) {
      buffer.write(',');
    }
    buffer.write(digits[i]);
  }
  final formatted = buffer.toString();
  return negative ? '-$formatted ل.س' : '$formatted ل.س';
}

/// Parses a wire JSON number as integer SYP; rejects fractional values.
int? parseSypAmount(dynamic raw) {
  if (raw == null) return null;
  if (raw is int) return raw;
  if (raw is num) {
    if (raw is double && raw != raw.roundToDouble()) {
      return null;
    }
    return raw.toInt();
  }
  if (raw is String) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return null;
    final parsed = int.tryParse(trimmed);
    if (parsed != null) return parsed;
    final asDouble = double.tryParse(trimmed);
    if (asDouble == null || asDouble != asDouble.roundToDouble()) {
      return null;
    }
    return asDouble.toInt();
  }
  return null;
}
