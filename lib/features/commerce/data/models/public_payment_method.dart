import 'package:equatable/equatable.dart';

import 'commerce_json_helpers.dart';

/// Payment method from `GET /public/payments/methods` (spec §2.1).
class PublicPaymentMethod extends Equatable {
  const PublicPaymentMethod({
    required this.providerCode,
    required this.displayName,
    required this.requiresRedirect,
    required this.supportsSavedCards,
  });

  final String providerCode;
  final String displayName;
  final bool requiresRedirect;
  final bool supportsSavedCards;

  factory PublicPaymentMethod.fromJson(Map<String, dynamic> json) {
    return PublicPaymentMethod(
      providerCode: readCommerceString(json['providerCode']) ?? '',
      displayName: readCommerceString(json['displayName']) ?? '',
      requiresRedirect: json['requiresRedirect'] as bool? ?? false,
      supportsSavedCards: json['supportsSavedCards'] as bool? ?? false,
    );
  }

  factory PublicPaymentMethod.fromEnvelopeData(Map<String, dynamic> data) =>
      PublicPaymentMethod.fromJson(data);

  Map<String, dynamic> toJson() => {
        'providerCode': providerCode,
        'displayName': displayName,
        'requiresRedirect': requiresRedirect,
        'supportsSavedCards': supportsSavedCards,
      };

  @override
  List<Object?> get props => [
        providerCode,
        displayName,
        requiresRedirect,
        supportsSavedCards,
      ];
}
