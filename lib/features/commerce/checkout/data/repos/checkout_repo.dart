import 'package:dartz/dartz.dart';
import 'package:sooq_merchant/core/errors/failures.dart';
import 'package:sooq_merchant/features/commerce/data/models/apply_discount_result.dart';
import 'package:sooq_merchant/features/commerce/data/models/checkout_request.dart';
import 'package:sooq_merchant/features/commerce/data/models/customer_order.dart';
import 'package:sooq_merchant/features/commerce/data/models/guest_order_lookup.dart';
import 'package:sooq_merchant/features/commerce/data/models/public_payment_method.dart';
import 'package:sooq_merchant/features/commerce/data/models/shipping_cost_request.dart';
import 'package:sooq_merchant/features/commerce/data/models/shipping_cost_response.dart';

abstract class CheckoutRepo {
  Future<Either<Failure, List<PublicPaymentMethod>>> getPaymentMethods({
    String? tenantId,
  });

  Future<Either<Failure, ShippingCostResponse>> calculateShipping({
    required ShippingCostRequest request,
    String? tenantId,
  });

  Future<Either<Failure, ApplyDiscountResult>> validateDiscount({
    required String code,
    required int subtotal,
    required int shippingCost,
    String? tenantId,
  });

  Future<Either<Failure, CustomerOrder>> placeOrder({
    required CheckoutRequest request,
    String? tenantId,
  });

  Future<Either<Failure, CustomerOrder>> lookupGuestOrder({
    required GuestOrderLookup lookup,
    String? tenantId,
  });
}
