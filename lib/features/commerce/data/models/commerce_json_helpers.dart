import 'package:sooq_merchant/core/utils/syp_formatter.dart';

String? readCommerceString(dynamic value) {
  if (value == null) return null;
  final text = value.toString().trim();
  return text.isEmpty ? null : text;
}

int readCommerceInt(dynamic value, {int fallback = 0}) {
  return parseSypAmount(value) ?? fallback;
}

double readCommerceDouble(dynamic value, {double fallback = 0}) {
  if (value is num) return value.toDouble();
  if (value is String) {
    return double.tryParse(value.trim()) ?? fallback;
  }
  return fallback;
}

List<T> readCommerceList<T>(
  dynamic raw,
  T Function(Map<String, dynamic> json) parse,
) {
  if (raw is! List) return const [];
  return raw
      .whereType<Map>()
      .map((item) => parse(Map<String, dynamic>.from(item)))
      .toList();
}
