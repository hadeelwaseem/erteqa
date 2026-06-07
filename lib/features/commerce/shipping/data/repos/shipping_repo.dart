import 'package:dartz/dartz.dart';
import 'package:sooq_merchant/core/errors/failures.dart';
import 'package:sooq_merchant/features/commerce/data/models/customer_shipment_status.dart';

abstract class ShippingRepo {
  Future<Either<Failure, CustomerShipmentStatus>> trackShipment({
    required String orderId,
    String? tenantId,
  });
}
