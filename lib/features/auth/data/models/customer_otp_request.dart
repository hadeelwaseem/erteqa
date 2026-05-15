class CustomerOtpRequest {
  static final RegExp phonePattern = RegExp(r'^[0-9+]{8,15}$');

  const CustomerOtpRequest({
    required this.phone,
    this.tenantId,
    this.tenantSlug,
    this.fullName,
  });

  final String phone;
  final String? tenantId;
  final String? tenantSlug;
  final String? fullName;

  String? validate() {
    if (phone.trim().isEmpty) {
      return 'Phone number is required.';
    }
    if (!phonePattern.hasMatch(phone.trim())) {
      return 'Phone must be 8-15 digits and may start with +.';
    }
    if ((tenantId == null || tenantId!.trim().isEmpty) &&
        (tenantSlug == null || tenantSlug!.trim().isEmpty)) {
      return 'Provide tenantId or tenantSlug.';
    }
    return null;
  }

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'phone': phone.trim(),
      'tenantId': tenantId?.trim(),
      'tenantSlug': tenantSlug?.trim(),
      'fullName': fullName?.trim(),
    };
    json.removeWhere((key, value) => value == null || (value is String && value.isEmpty));
    return json;
  }
}