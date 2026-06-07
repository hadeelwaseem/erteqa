import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:latlong2/latlong.dart';

import 'package:sooq_merchant/core/cubits/token_cubit/token_cubit.dart';
import 'package:sooq_merchant/features/commerce/cart/presentation/manager/cart_cubit/cart_cubit.dart';
import 'package:sooq_merchant/features/commerce/cart/presentation/manager/cart_cubit/cart_state.dart';
import 'package:sooq_merchant/features/commerce/checkout/data/commerce_store_origin.dart';
import 'package:sooq_merchant/features/commerce/checkout/data/datasources/checkout_session_store.dart';
import 'package:sooq_merchant/features/commerce/checkout/data/models/checkout_draft.dart';
import 'package:sooq_merchant/features/commerce/checkout/data/repos/checkout_repo.dart';
import 'package:sooq_merchant/features/commerce/checkout/presentation/manager/checkout_cubit/checkout_state.dart';
import 'package:sooq_merchant/features/commerce/checkout/presentation/widgets/checkout_location_picker_page.dart';
import 'package:sooq_merchant/features/commerce/data/models/checkout_item.dart';
import 'package:sooq_merchant/features/commerce/data/models/checkout_request.dart';
import 'package:sooq_merchant/features/commerce/data/models/shipping_address.dart';
import 'package:sooq_merchant/features/commerce/data/models/shipping_cost_request.dart';

class CheckoutCubit extends Cubit<CheckoutState> {
  CheckoutCubit(
    this._repo,
    this._sessionStore,
    this._cartCubit,
    this._tokenCubit,
  ) : super(const CheckoutInitial());

  final CheckoutRepo _repo;
  final CheckoutSessionStore _sessionStore;
  final CartCubit _cartCubit;
  final TokenCubit _tokenCubit;

  String? _tenantId;

  CheckoutDraft? get _currentDraft {
    return switch (state) {
      CheckoutLoaded(:final draft) => draft,
      CheckoutLoading(:final draft) => draft,
      CheckoutFailureState(:final draft) => draft,
      CheckoutActionSuccess(:final draft) => draft,
      _ => null,
    };
  }

  void setTenantId(String? tenantId) {
    final trimmed = tenantId?.trim();
    _tenantId = (trimmed != null && trimmed.isNotEmpty) ? trimmed : null;
  }

  Future<void> loadDraft() async {
    final draft = await _sessionStore.loadDraft();
    if (isClosed) return;
    emit(CheckoutLoaded(draft));
  }

  Future<void> pickLocation(BuildContext context) async {
    final draft = _currentDraft ?? await _sessionStore.loadDraft();
    final initial = (draft.latitude != null && draft.longitude != null)
        ? LatLng(draft.latitude!, draft.longitude!)
        : const LatLng(
            CommerceStoreOrigin.latitude,
            CommerceStoreOrigin.longitude,
          );

    final selected = await Navigator.of(context).push<LatLng>(
      MaterialPageRoute(
        builder: (_) => CheckoutLocationPickerPage(initial: initial),
      ),
    );

    if (isClosed || selected == null) return;

    final next = draft.copyWith(
      latitude: selected.latitude,
      longitude: selected.longitude,
    );
    await _sessionStore.saveDraft(next);
    if (isClosed) return;
    emit(CheckoutLoaded(next));
  }

  Future<void> saveAddress({
    required String recipientName,
    required String phone,
    String? addressLabel,
    String? guestEmail,
    String? notesCustomer,
  }) async {
    final draft = _currentDraft ?? await _sessionStore.loadDraft();
    if (!draft.hasLocation) {
      emit(
        CheckoutFailureState(
          'يرجى تحديد موقع التوصيل على الخريطة',
          draft: draft,
        ),
      );
      return;
    }

    emit(CheckoutLoading(draft: draft, operation: 'saveAddress'));

    final address = ShippingAddress(
      latitude: draft.latitude!,
      longitude: draft.longitude!,
      recipientName: recipientName.trim(),
      phone: phone.trim(),
      addressLabel: addressLabel?.trim(),
    );

    var next = draft.copyWith(
      shippingAddress: address,
      guestEmail: () {
        final trimmed = guestEmail?.trim();
        if (trimmed == null || trimmed.isEmpty) return draft.guestEmail;
        return trimmed;
      }(),
      notesCustomer: notesCustomer?.trim(),
      clearDiscountMessage: true,
    );
    await _sessionStore.saveDraft(next);

    final shippingRequest = ShippingCostRequest(
      originLat: CommerceStoreOrigin.latitude,
      originLng: CommerceStoreOrigin.longitude,
      destinationLat: address.latitude,
      destinationLng: address.longitude,
    );

    final shippingResult = await _repo.calculateShipping(
      request: shippingRequest,
      tenantId: _tenantId,
    );

    if (isClosed) return;

    await shippingResult.fold(
      (failure) async {
        emit(CheckoutFailureState(failure.errMessage, draft: next));
      },
      (quote) async {
        next = next.copyWith(shippingQuote: quote);
        await _sessionStore.saveDraft(next);
        if (isClosed) return;
        emit(CheckoutLoaded(next));
      },
    );
  }

  Future<void> selectPaymentMethod({required String providerCode}) async {
    final draft = _currentDraft ?? await _sessionStore.loadDraft();
    final code = providerCode.trim();
    if (code.isEmpty) {
      emit(
        CheckoutFailureState(
          'يرجى اختيار وسيلة الدفع',
          draft: draft,
        ),
      );
      return;
    }

    final cachedMethods = switch (state) {
      CheckoutLoaded(:final paymentMethods) => paymentMethods,
      _ => null,
    };

    if (cachedMethods != null) {
      final selected =
          cachedMethods.where((m) => m.providerCode == code).toList();
      if (selected.isEmpty) {
        emit(
          CheckoutFailureState(
            'وسيلة الدفع غير متاحة',
            draft: draft,
          ),
        );
        return;
      }
      if (selected.first.requiresRedirect) {
        emit(
          CheckoutFailureState(
            'هذه الوسيلة غير متاحة حالياً',
            draft: draft,
          ),
        );
        return;
      }

      final next = draft.copyWith(paymentMethod: code);
      await _sessionStore.saveDraft(next);
      if (isClosed) return;
      emit(CheckoutLoaded(next, paymentMethods: cachedMethods));
      return;
    }

    final methodsResult = await _repo.getPaymentMethods(tenantId: _tenantId);
    if (isClosed) return;

    await methodsResult.fold(
      (failure) async {
        emit(CheckoutFailureState(failure.errMessage, draft: draft));
      },
      (methods) async {
        final selected = methods.where((m) => m.providerCode == code).toList();
        if (selected.isEmpty) {
          emit(
            CheckoutFailureState(
              'وسيلة الدفع غير متاحة',
              draft: draft,
            ),
          );
          return;
        }
        if (selected.first.requiresRedirect) {
          emit(
            CheckoutFailureState(
              'هذه الوسيلة غير متاحة حالياً',
              draft: draft,
            ),
          );
          return;
        }

        final next = draft.copyWith(paymentMethod: code);
        await _sessionStore.saveDraft(next);
        if (isClosed) return;
        emit(CheckoutLoaded(next, paymentMethods: methods));
      },
    );
  }

  Future<void> validateDiscount({required String code}) async {
    final draft = _currentDraft ?? await _sessionStore.loadDraft();
    final trimmed = code.trim();
    if (trimmed.isEmpty) {
      final next = draft.copyWith(
        discountMessage: 'يرجى إدخال كود الخصم',
        clearDiscountResult: true,
      );
      await _sessionStore.saveDraft(next);
      if (isClosed) return;
      emit(CheckoutLoaded(next));
      return;
    }

    final cart = _readCart();
    final subtotal = cart?.subtotalSyp ?? 0;
    final shippingCost = draft.shippingQuote?.shippingCostSyp ?? 0;

    final result = await _repo.validateDiscount(
      code: trimmed,
      subtotal: subtotal,
      shippingCost: shippingCost,
      tenantId: _tenantId,
    );

    if (isClosed) return;

    await result.fold(
      (failure) async {
        final next = draft.copyWith(
          discountCode: trimmed,
          discountMessage: failure.errMessage,
          clearDiscountResult: true,
        );
        await _sessionStore.saveDraft(next);
        if (isClosed) return;
        emit(CheckoutLoaded(next));
      },
      (discount) async {
        final next = draft.copyWith(
          discountCode: trimmed,
          discountResult: discount,
          discountMessage: 'تم تطبيق الخصم',
        );
        await _sessionStore.saveDraft(next);
        if (isClosed) return;
        emit(CheckoutLoaded(next));
      },
    );
  }

  Future<void> loadPaymentMethods(String requestKey) async {
    final draft = _currentDraft ?? await _sessionStore.loadDraft();
    emit(
      CheckoutLoading(
        draft: draft,
        operation: 'loadPaymentMethods',
        paymentMethodsRequestKey: requestKey,
      ),
    );

    final result = await _repo.getPaymentMethods(tenantId: _tenantId);
    if (isClosed) return;

    result.fold(
      (failure) {
        emit(
          CheckoutFailureState(
            failure.errMessage,
            draft: draft,
            paymentMethodsRequestKey: requestKey,
          ),
        );
      },
      (methods) {
        emit(
          CheckoutLoaded(
            draft,
            paymentMethods: methods,
            paymentMethodsRequestKey: requestKey,
          ),
        );
      },
    );
  }

  Future<void> placeOrder() async {
    final draft = _currentDraft ?? await _sessionStore.loadDraft();
    final cart = _readCart();

    if (cart == null || cart.isEmpty) {
      emit(
        CheckoutFailureState(
          'السلة فارغة — أضف منتجات قبل إتمام الطلب',
          draft: draft,
        ),
      );
      return;
    }

    final address = draft.shippingAddress;
    if (address == null) {
      emit(
        CheckoutFailureState(
          'يرجى إكمال عنوان التوصيل',
          draft: draft,
        ),
      );
      return;
    }

    final paymentMethod = draft.paymentMethod?.trim();
    if (paymentMethod == null || paymentMethod.isEmpty) {
      emit(
        CheckoutFailureState(
          'يرجى اختيار وسيلة الدفع',
          draft: draft,
        ),
      );
      return;
    }

    final isGuest = _tokenCubit.state == null;
    final guestEmail = draft.guestEmail?.trim();
    if (isGuest && (guestEmail == null || guestEmail.isEmpty)) {
      emit(
        CheckoutFailureState(
          'يرجى إدخال البريد الإلكتروني للمتابعة كضيف',
          draft: draft,
        ),
      );
      return;
    }

    emit(CheckoutLoading(draft: draft, operation: 'placeOrder'));

    final token = await _sessionStore.ensureCheckoutToken(draft);
    final withToken = draft.copyWith(checkoutToken: token);
    await _sessionStore.saveDraft(withToken);

    final request = CheckoutRequest(
      items: [
        for (final line in cart.items)
          CheckoutItem(
            variantId: line.variantId,
            quantity: line.quantity,
          ),
      ],
      shippingAddress: address,
      paymentMethod: paymentMethod,
      checkoutToken: token,
      discountCode: draft.discountCode,
      notesCustomer: draft.notesCustomer,
      guestEmail: isGuest ? guestEmail : null,
    );

    final result = await _repo.placeOrder(
      request: request,
      tenantId: _tenantId,
    );

    if (isClosed) return;

    await result.fold(
      (failure) async {
        emit(CheckoutFailureState(failure.errMessage, draft: withToken));
      },
      (order) async {
        final cleared = await _sessionStore.clearAfterSuccess(lastOrder: order);
        await _cartCubit.clear();
        if (isClosed) return;
        emit(CheckoutLoaded(cleared));
      },
    );
  }

  dynamic _readCart() {
    final cartState = _cartCubit.state;
    return switch (cartState) {
      CartLoaded(:final cart) => cart,
      CartActionSuccess(:final cart) => cart,
      CartFailureState(:final cart) => cart,
      _ => null,
    };
  }
}
