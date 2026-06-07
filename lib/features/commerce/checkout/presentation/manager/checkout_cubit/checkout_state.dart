import 'package:equatable/equatable.dart';

import 'package:sooq_merchant/features/commerce/checkout/data/models/checkout_draft.dart';
import 'package:sooq_merchant/features/commerce/data/models/public_payment_method.dart';

abstract class CheckoutState extends Equatable {
  const CheckoutState();

  @override
  List<Object?> get props => [];
}

class CheckoutInitial extends CheckoutState {
  const CheckoutInitial();
}

class CheckoutLoading extends CheckoutState {
  const CheckoutLoading({
    this.draft,
    this.operation,
    this.paymentMethodsRequestKey,
  });

  final CheckoutDraft? draft;
  final String? operation;
  final String? paymentMethodsRequestKey;

  @override
  List<Object?> get props => [draft, operation, paymentMethodsRequestKey];
}

class CheckoutLoaded extends CheckoutState {
  const CheckoutLoaded(
    this.draft, {
    this.paymentMethods,
    this.paymentMethodsRequestKey,
  });

  final CheckoutDraft draft;
  final List<PublicPaymentMethod>? paymentMethods;
  final String? paymentMethodsRequestKey;

  @override
  List<Object?> get props => [draft, paymentMethods, paymentMethodsRequestKey];
}

class CheckoutFailureState extends CheckoutState {
  const CheckoutFailureState(
    this.message, {
    this.draft,
    this.paymentMethodsRequestKey,
  });

  final String message;
  final CheckoutDraft? draft;
  final String? paymentMethodsRequestKey;

  @override
  List<Object?> get props => [message, draft, paymentMethodsRequestKey];
}

class CheckoutActionSuccess extends CheckoutState {
  const CheckoutActionSuccess(this.draft, {this.message});

  final CheckoutDraft draft;
  final String? message;

  @override
  List<Object?> get props => [draft, message];
}
