import 'package:equatable/equatable.dart';

import 'package:sooq_merchant/features/commerce/data/models/customer_order.dart';
import 'package:sooq_merchant/features/commerce/data/models/customer_shipment_status.dart';
import 'package:sooq_merchant/features/commerce/data/models/order_list_response.dart';

abstract class OrderState extends Equatable {
  const OrderState();

  @override
  List<Object?> get props => [];
}

class OrderInitial extends OrderState {
  const OrderInitial();
}

class OrderLoading extends OrderState {
  const OrderLoading({
    required this.operation,
    this.requestKey,
  });

  final String operation;
  final String? requestKey;

  @override
  List<Object?> get props => [operation, requestKey];
}

class OrderListSuccess extends OrderState {
  const OrderListSuccess({
    required this.requestKey,
    required this.response,
  });

  final String requestKey;
  final OrderListResponse response;

  @override
  List<Object?> get props => [requestKey, response];
}

class OrderDetailSuccess extends OrderState {
  const OrderDetailSuccess({
    required this.requestKey,
    required this.order,
  });

  final String requestKey;
  final CustomerOrder order;

  @override
  List<Object?> get props => [requestKey, order];
}

class OrderShipmentSuccess extends OrderState {
  const OrderShipmentSuccess({
    required this.requestKey,
    required this.shipment,
  });

  final String requestKey;
  final CustomerShipmentStatus shipment;

  @override
  List<Object?> get props => [requestKey, shipment];
}

class OrderShipmentEmpty extends OrderState {
  const OrderShipmentEmpty({
    required this.requestKey,
    this.message = 'لم تبدأ عملية الشحن بعد.',
  });

  final String requestKey;
  final String message;

  @override
  List<Object?> get props => [requestKey, message];
}

class OrderFailureState extends OrderState {
  const OrderFailureState(
    this.message, {
    this.requestKey,
    this.operation,
    this.suppressMessenger = false,
  });

  final String message;
  final String? requestKey;
  final String? operation;
  final bool suppressMessenger;

  @override
  List<Object?> get props => [message, requestKey, operation, suppressMessenger];
}

class OrderGuestLookupUpdated extends OrderState {
  const OrderGuestLookupUpdated({
    this.guestLookupError,
    this.lastLookupOrderId,
  });

  final String? guestLookupError;
  final String? lastLookupOrderId;

  @override
  List<Object?> get props => [guestLookupError, lastLookupOrderId];
}

class OrderActionSuccess extends OrderState {
  const OrderActionSuccess({
    required this.operation,
    this.order,
  });

  final String operation;
  final CustomerOrder? order;

  @override
  List<Object?> get props => [operation, order];
}
