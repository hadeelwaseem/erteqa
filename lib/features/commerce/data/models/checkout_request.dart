import 'package:equatable/equatable.dart';

import 'checkout_item.dart';
import 'commerce_json_helpers.dart';
import 'shipping_address.dart';

/// Body for `POST /public/checkout` (spec §2.4).
class CheckoutRequest extends Equatable {
  const CheckoutRequest({
    required this.items,
    required this.shippingAddress,
    required this.paymentMethod,
    required this.checkoutToken,
    this.discountCode,
    this.notesCustomer,
    this.guestEmail,
  });

  final List<CheckoutItem> items;
  final ShippingAddress shippingAddress;
  final String paymentMethod;
  final String checkoutToken;
  final String? discountCode;
  final String? notesCustomer;
  final String? guestEmail;

  factory CheckoutRequest.fromJson(Map<String, dynamic> json) {
    return CheckoutRequest(
      items: readCommerceList(json['items'], CheckoutItem.fromJson),
      shippingAddress: ShippingAddress.fromJson(
        Map<String, dynamic>.from(json['shippingAddress'] as Map? ?? {}),
      ),
      paymentMethod: readCommerceString(json['paymentMethod']) ?? '',
      checkoutToken: readCommerceString(json['checkoutToken']) ?? '',
      discountCode: readCommerceString(json['discountCode']),
      notesCustomer: readCommerceString(json['notesCustomer']),
      guestEmail: readCommerceString(json['guestEmail']),
    );
  }

  Map<String, dynamic> toJson() => {
        'items': items.map((item) => item.toJson()).toList(),
        'shippingAddress': shippingAddress.toJson(),
        'paymentMethod': paymentMethod,
        'checkoutToken': checkoutToken,
        if (discountCode != null) 'discountCode': discountCode,
        if (notesCustomer != null) 'notesCustomer': notesCustomer,
        if (guestEmail != null) 'guestEmail': guestEmail,
      };

  @override
  List<Object?> get props => [
        items,
        shippingAddress,
        paymentMethod,
        checkoutToken,
        discountCode,
        notesCustomer,
        guestEmail,
      ];
}
