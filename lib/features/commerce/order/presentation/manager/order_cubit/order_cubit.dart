import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:sooq_merchant/core/cubits/token_cubit/token_cubit.dart';
import 'package:sooq_merchant/core/errors/failures.dart';
import 'package:sooq_merchant/features/commerce/checkout/data/repos/checkout_repo.dart';
import 'package:sooq_merchant/features/commerce/data/models/cancel_order_request.dart';
import 'package:sooq_merchant/features/commerce/data/models/customer_order.dart';
import 'package:sooq_merchant/features/commerce/data/models/guest_order_lookup.dart';
import 'package:sooq_merchant/features/commerce/order/data/repos/order_repo.dart';
import 'package:sooq_merchant/features/commerce/order/presentation/manager/order_cubit/order_state.dart';
import 'package:sooq_merchant/features/commerce/shipping/data/repos/shipping_repo.dart';

class OrderCubit extends Cubit<OrderState> {
  OrderCubit(
    this._orderRepo,
    this._checkoutRepo,
    this._shippingRepo,
    this._tokenCubit,
  ) : super(const OrderInitial());

  final OrderRepo _orderRepo;
  final CheckoutRepo _checkoutRepo;
  final ShippingRepo _shippingRepo;
  final TokenCubit _tokenCubit;

  String? _tenantId;
  String? guestLookupError;
  String? lastLookupOrderId;
  final Map<String, CustomerOrder> _guestOrderCache = {};

  bool get isAuthenticated => _tokenCubit.state != null;

  void setTenantId(String? tenantId) {
    final trimmed = tenantId?.trim();
    _tenantId = (trimmed != null && trimmed.isNotEmpty) ? trimmed : null;
  }

  Future<void> loadOrders(
    String requestKey, {
    required int page,
    required int size,
    String? status,
  }) async {
    emit(OrderLoading(operation: 'loadOrders', requestKey: requestKey));

    final result = await _orderRepo.getOrders(
      page: page,
      size: size,
      status: status,
      tenantId: _tenantId,
    );

    if (isClosed) return;

    result.fold(
      (failure) => emit(
        OrderFailureState(
          failure.errMessage,
          requestKey: requestKey,
          operation: 'loadOrders',
        ),
      ),
      (response) => emit(
        OrderListSuccess(requestKey: requestKey, response: response),
      ),
    );
  }

  Future<void> loadOrderDetail({
    required String requestKey,
    required String orderId,
  }) async {
    final trimmedId = orderId.trim();
    if (trimmedId.isEmpty) {
      emit(
        OrderFailureState(
          'معرف الطلب غير صالح',
          requestKey: requestKey,
          operation: 'loadOrderDetail',
        ),
      );
      return;
    }

    if (!isAuthenticated) {
      final cached = _guestOrderCache[trimmedId];
      if (cached != null) {
        emit(OrderDetailSuccess(requestKey: requestKey, order: cached));
        return;
      }
      emit(
        OrderFailureState(
          'يرجى البحث عن الطلب أولاً',
          requestKey: requestKey,
          operation: 'loadOrderDetail',
          suppressMessenger: true,
        ),
      );
      return;
    }

    emit(OrderLoading(operation: 'loadOrderDetail', requestKey: requestKey));

    final result = await _orderRepo.getOrderDetail(
      orderId: trimmedId,
      tenantId: _tenantId,
    );

    if (isClosed) return;

    result.fold(
      (failure) => emit(
        OrderFailureState(
          failure.errMessage,
          requestKey: requestKey,
          operation: 'loadOrderDetail',
        ),
      ),
      (order) => emit(
        OrderDetailSuccess(requestKey: requestKey, order: order),
      ),
    );
  }

  Future<void> loadShipmentTrack({
    required String requestKey,
    required String orderId,
  }) async {
    final trimmedId = orderId.trim();
    if (trimmedId.isEmpty) {
      emit(OrderShipmentEmpty(requestKey: requestKey));
      return;
    }

    emit(OrderLoading(operation: 'loadShipmentTrack', requestKey: requestKey));

    final result = await _shippingRepo.trackShipment(
      orderId: trimmedId,
      tenantId: _tenantId,
    );

    if (isClosed) return;

    result.fold(
      (failure) {
        if (failure is ShipmentNotFoundFailure ||
            failure.errMessage == 'Shipment not found') {
          emit(OrderShipmentEmpty(requestKey: requestKey));
          return;
        }
        emit(OrderShipmentEmpty(requestKey: requestKey));
      },
      (shipment) => emit(
        OrderShipmentSuccess(requestKey: requestKey, shipment: shipment),
      ),
    );
  }

  Future<void> lookupGuest({
    required String orderNumber,
    required String email,
  }) async {
    final trimmedNumber = orderNumber.trim();
    final trimmedEmail = email.trim();

    if (trimmedNumber.isEmpty || trimmedEmail.isEmpty) {
      guestLookupError = 'يرجى إدخال رقم الطلب والبريد الإلكتروني';
      lastLookupOrderId = null;
      emit(
        OrderGuestLookupUpdated(
          guestLookupError: guestLookupError,
        ),
      );
      return;
    }

    emit(const OrderLoading(operation: 'lookupGuest'));

    final result = await _checkoutRepo.lookupGuestOrder(
      lookup: GuestOrderLookup(
        orderNumber: trimmedNumber,
        email: trimmedEmail,
      ),
      tenantId: _tenantId,
    );

    if (isClosed) return;

    result.fold(
      (failure) {
        guestLookupError =
            'تعذّر العثور على الطلب — تأكد من رقم الطلب والبريد الإلكتروني';
        lastLookupOrderId = null;
        emit(
          OrderGuestLookupUpdated(
            guestLookupError: guestLookupError,
          ),
        );
      },
      (order) {
        guestLookupError = null;
        lastLookupOrderId = order.orderId;
        _guestOrderCache[order.orderId] = order;
        emit(
          OrderGuestLookupUpdated(
            lastLookupOrderId: order.orderId,
          ),
        );
      },
    );
  }

  Future<void> cancelOrder({
    required String orderId,
    String? reason,
  }) async {
    final trimmedId = orderId.trim();
    if (trimmedId.isEmpty) {
      emit(
        const OrderFailureState(
          'معرف الطلب غير صالح',
          operation: 'cancelOrder',
        ),
      );
      return;
    }

    emit(const OrderLoading(operation: 'cancelOrder'));

    final result = await _orderRepo.cancelOrder(
      orderId: trimmedId,
      request: reason == null || reason.trim().isEmpty
          ? null
          : CancelOrderRequest(reason: reason.trim()),
      tenantId: _tenantId,
    );

    if (isClosed) return;

    result.fold(
      (failure) => emit(
        OrderFailureState(
          failure.errMessage,
          operation: 'cancelOrder',
        ),
      ),
      (order) => emit(
        OrderActionSuccess(operation: 'cancelOrder', order: order),
      ),
    );
  }

  Future<void> openInvoice(String orderId) async {
    final trimmedId = orderId.trim();
    if (trimmedId.isEmpty) {
      emit(
        const OrderFailureState(
          'معرف الطلب غير صالح',
          operation: 'openInvoice',
        ),
      );
      return;
    }

    emit(const OrderLoading(operation: 'openInvoice'));

    final result = await _orderRepo.getInvoice(
      orderId: trimmedId,
      tenantId: _tenantId,
    );

    if (isClosed) return;

    await result.fold(
      (failure) async {
        emit(
          OrderFailureState(
            failure.errMessage,
            operation: 'openInvoice',
          ),
        );
      },
      (invoice) async {
        final uri = Uri.tryParse(invoice.pdfUrl);
        if (uri == null) {
          emit(
            const OrderFailureState(
              'رابط الفاتورة غير صالح',
              operation: 'openInvoice',
            ),
          );
          return;
        }
        final launched =
            await launchUrl(uri, mode: LaunchMode.externalApplication);
        if (isClosed) return;
        if (!launched) {
          emit(
            const OrderFailureState(
              'تعذر فتح الفاتورة',
              operation: 'openInvoice',
            ),
          );
          return;
        }
        emit(const OrderActionSuccess(operation: 'openInvoice'));
      },
    );
  }
}
