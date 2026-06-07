import 'package:equatable/equatable.dart';

import 'package:sooq_merchant/features/commerce/data/models/apply_discount_result.dart';
import 'package:sooq_merchant/features/commerce/data/models/customer_order.dart';
import 'package:sooq_merchant/features/commerce/data/models/shipping_address.dart';
import 'package:sooq_merchant/features/commerce/data/models/shipping_cost_response.dart';

/// Session-persisted checkout wizard draft.
class CheckoutDraft extends Equatable {
  const CheckoutDraft({
    this.latitude,
    this.longitude,
    this.shippingAddress,
    this.paymentMethod,
    this.discountCode,
    this.discountResult,
    this.shippingQuote,
    this.notesCustomer,
    this.guestEmail,
    this.checkoutToken,
    this.lastOrder,
    this.discountMessage,
  });

  final double? latitude;
  final double? longitude;
  final ShippingAddress? shippingAddress;
  final String? paymentMethod;
  final String? discountCode;
  final ApplyDiscountResult? discountResult;
  final ShippingCostResponse? shippingQuote;
  final String? notesCustomer;
  final String? guestEmail;
  final String? checkoutToken;
  final CustomerOrder? lastOrder;
  final String? discountMessage;

  bool get hasLocation => latitude != null && longitude != null;

  CheckoutDraft copyWith({
    double? latitude,
    double? longitude,
    ShippingAddress? shippingAddress,
    String? paymentMethod,
    String? discountCode,
    ApplyDiscountResult? discountResult,
    ShippingCostResponse? shippingQuote,
    String? notesCustomer,
    String? guestEmail,
    String? checkoutToken,
    CustomerOrder? lastOrder,
    String? discountMessage,
    bool clearDiscountResult = false,
    bool clearDiscountMessage = false,
    bool clearShippingQuote = false,
  }) {
    return CheckoutDraft(
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      shippingAddress: shippingAddress ?? this.shippingAddress,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      discountCode: discountCode ?? this.discountCode,
      discountResult:
          clearDiscountResult ? null : (discountResult ?? this.discountResult),
      shippingQuote:
          clearShippingQuote ? null : (shippingQuote ?? this.shippingQuote),
      notesCustomer: notesCustomer ?? this.notesCustomer,
      guestEmail: guestEmail ?? this.guestEmail,
      checkoutToken: checkoutToken ?? this.checkoutToken,
      lastOrder: lastOrder ?? this.lastOrder,
      discountMessage: clearDiscountMessage
          ? null
          : (discountMessage ?? this.discountMessage),
    );
  }

  Map<String, dynamic> toJson() => {
        if (latitude != null) 'latitude': latitude,
        if (longitude != null) 'longitude': longitude,
        if (shippingAddress != null)
          'shippingAddress': shippingAddress!.toJson(),
        if (paymentMethod != null) 'paymentMethod': paymentMethod,
        if (discountCode != null) 'discountCode': discountCode,
        if (discountResult != null) 'discountResult': discountResult!.toJson(),
        if (shippingQuote != null) 'shippingQuote': shippingQuote!.toJson(),
        if (notesCustomer != null) 'notesCustomer': notesCustomer,
        if (guestEmail != null) 'guestEmail': guestEmail,
        if (checkoutToken != null) 'checkoutToken': checkoutToken,
        if (lastOrder != null) 'lastOrder': lastOrder!.toJson(),
        if (discountMessage != null) 'discountMessage': discountMessage,
      };

  factory CheckoutDraft.fromJson(Map<String, dynamic> json) {
    return CheckoutDraft(
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      shippingAddress: json['shippingAddress'] is Map
          ? ShippingAddress.fromJson(
              Map<String, dynamic>.from(json['shippingAddress'] as Map),
            )
          : null,
      paymentMethod: json['paymentMethod'] as String?,
      discountCode: json['discountCode'] as String?,
      discountResult: json['discountResult'] is Map
          ? ApplyDiscountResult.fromJson(
              Map<String, dynamic>.from(json['discountResult'] as Map),
            )
          : null,
      shippingQuote: json['shippingQuote'] is Map
          ? ShippingCostResponse.fromJson(
              Map<String, dynamic>.from(json['shippingQuote'] as Map),
            )
          : null,
      notesCustomer: json['notesCustomer'] as String?,
      guestEmail: json['guestEmail'] as String?,
      checkoutToken: json['checkoutToken'] as String?,
      lastOrder: json['lastOrder'] is Map
          ? CustomerOrder.fromJson(
              Map<String, dynamic>.from(json['lastOrder'] as Map),
            )
          : null,
      discountMessage: json['discountMessage'] as String?,
    );
  }

  @override
  List<Object?> get props => [
        latitude,
        longitude,
        shippingAddress,
        paymentMethod,
        discountCode,
        discountResult,
        shippingQuote,
        notesCustomer,
        guestEmail,
        checkoutToken,
        lastOrder,
        discountMessage,
      ];
}
