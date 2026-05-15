class CustomerOtpVerifyRequest {
  static final RegExp phonePattern = RegExp(r'^[0-9+]{8,15}$');
  static final RegExp otpPattern = RegExp(r'^\d{6}$');

  const CustomerOtpVerifyRequest({
    required this.phone,
    required this.otpCode,
    this.tenantId,
    this.tenantSlug,
    this.totpCode,
    this.backupCode,
  });

  final String phone;
  final String otpCode;
  final String? tenantId;
  final String? tenantSlug;
  final String? totpCode;
  final String? backupCode;

  String? validate() {
    if (phone.trim().isEmpty) {
      return 'Phone number is required.';
    }
    if (!phonePattern.hasMatch(phone.trim())) {
      return 'Phone must be 8-15 digits and may start with +.';
    }
    if (!otpPattern.hasMatch(otpCode.trim())) {
      return 'OTP code must be exactly 6 digits.';
    }
    if (totpCode != null && totpCode!.trim().isNotEmpty && !otpPattern.hasMatch(totpCode!.trim())) {
      return 'TOTP code must be exactly 6 digits.';
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
      'otpCode': otpCode.trim(),
      'totpCode': totpCode?.trim(),
      'backupCode': backupCode?.trim(),
    };
    json.removeWhere((key, value) => value == null || (value is String && value.isEmpty));
    return json;
  }
}