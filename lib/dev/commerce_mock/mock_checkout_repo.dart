import 'package:dartz/dartz.dart';
import 'package:sooq_merchant/core/errors/failures.dart';
import 'package:sooq_merchant/core/network/api_envelope.dart';
import 'package:sooq_merchant/core/utils/app_logger.dart';
import 'package:sooq_merchant/dev/commerce_mock/commerce_mock_config.dart';
import 'package:sooq_merchant/dev/commerce_mock/mock_commerce_data.dart';
import 'package:sooq_merchant/features/commerce/checkout/data/repos/checkout_repo.dart';
import 'package:sooq_merchant/features/commerce/data/models/apply_discount_result.dart';
import 'package:sooq_merchant/features/commerce/data/models/checkout_request.dart';
import 'package:sooq_merchant/features/commerce/data/models/customer_order.dart';
import 'package:sooq_merchant/features/commerce/data/models/guest_order_lookup.dart';
import 'package:sooq_merchant/features/commerce/data/models/public_payment_method.dart';
import 'package:sooq_merchant/features/commerce/data/models/shipping_cost_request.dart';
import 'package:sooq_merchant/features/commerce/data/models/shipping_cost_response.dart';

class MockCheckoutRepo implements CheckoutRepo {
  Future<void> _delay() =>
      Future<void>.delayed(CommerceMockConfig.requestDelay);

  @override
  Future<Either<Failure, List<PublicPaymentMethod>>> getPaymentMethods({
    String? tenantId,
  }) async {
    AppLogger.network('[MOCK] getPaymentMethods tenantId=$tenantId');
    await _delay();
    try {
      final envelope = ApiEnvelope.requireEnvelope(
        MockCommerceData.paymentMethodsEnvelope(),
      );
      final items = ApiEnvelope.listFromEnvelope(
        envelope,
        parseItem: PublicPaymentMethod.fromEnvelopeData,
      );
      return Right(items);
    } catch (_) {
      return Left(ServerFailure('تعذر تحميل وسائل الدفع'));
    }
  }

  @override
  Future<Either<Failure, ShippingCostResponse>> calculateShipping({
    required ShippingCostRequest request,
    String? tenantId,
  }) async {
    AppLogger.network('[MOCK] calculateShipping tenantId=$tenantId');
    await _delay();
    try {
      final raw = MockCommerceData.shippingCostEnvelope(request: request);
      final response = ApiResponse<ShippingCostResponse>.fromJson(
        raw,
        parseData: ShippingCostResponse.fromEnvelopeData,
      );
      if (!response.success || response.data == null) {
        return Left(ServerFailure(response.message ?? 'تعذر حساب الشحن'));
      }
      return Right(response.data!);
    } catch (_) {
      return Left(ServerFailure('تعذر حساب الشحن'));
    }
  }

  @override
  Future<Either<Failure, ApplyDiscountResult>> validateDiscount({
    required String code,
    required int subtotal,
    required int shippingCost,
    String? tenantId,
  }) async {
    AppLogger.network(
      '[MOCK] validateDiscount code=$code subtotal=$subtotal shippingCost=$shippingCost',
    );
    await _delay();

    if (code.trim().toUpperCase() != '10OFF') {
      return Left(ServerFailure('كود الخصم غير صالح'));
    }

    try {
      final raw = MockCommerceData.discountEnvelope(
        code: code.trim().toUpperCase(),
        subtotal: subtotal,
      );
      final response = ApiResponse<ApplyDiscountResult>.fromJson(
        raw,
        parseData: ApplyDiscountResult.fromEnvelopeData,
      );
      if (!response.success || response.data == null) {
        return Left(ServerFailure(response.message ?? 'تعذر تطبيق الخصم'));
      }
      return Right(response.data!);
    } catch (_) {
      return Left(ServerFailure('تعذر تطبيق الخصم'));
    }
  }

  @override
  Future<Either<Failure, CustomerOrder>> placeOrder({
    required CheckoutRequest request,
    String? tenantId,
  }) async {
    AppLogger.network(
      '[MOCK] placeOrder checkoutToken=${request.checkoutToken} tenantId=$tenantId',
    );
    await _delay();
    try {
      final raw = MockCommerceData.placeOrderEnvelope(request: request);
      final response = ApiResponse<CustomerOrder>.fromJson(
        raw,
        parseData: CustomerOrder.fromEnvelopeData,
      );
      if (!response.success || response.data == null) {
        return Left(ServerFailure(response.message ?? 'تعذر إنشاء الطلب'));
      }
      return Right(response.data!);
    } catch (_) {
      return Left(ServerFailure('تعذر إنشاء الطلب'));
    }
  }

  @override
  Future<Either<Failure, CustomerOrder>> lookupGuestOrder({
    required GuestOrderLookup lookup,
    String? tenantId,
  }) async {
    AppLogger.network(
      '[MOCK] lookupGuestOrder orderNumber=${lookup.orderNumber} tenantId=$tenantId',
    );
    await _delay();
    final raw = MockCommerceData.lookupGuestOrderEnvelope(
      orderNumber: lookup.orderNumber,
      email: lookup.email,
    );
    if (raw == null) {
      return Left(ServerFailure('الطلب غير موجود'));
    }
    try {
      final response = ApiResponse<CustomerOrder>.fromJson(
        raw,
        parseData: CustomerOrder.fromEnvelopeData,
      );
      if (!response.success || response.data == null) {
        return Left(ServerFailure(response.message ?? 'الطلب غير موجود'));
      }
      return Right(response.data!);
    } catch (_) {
      return Left(ServerFailure('الطلب غير موجود'));
    }
  }
}
