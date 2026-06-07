import 'package:dartz/dartz.dart';
import 'package:sooq_merchant/core/errors/failures.dart';
import 'package:sooq_merchant/core/network/api_envelope.dart';
import 'package:sooq_merchant/core/utils/app_logger.dart';
import 'package:sooq_merchant/dev/commerce_mock/commerce_mock_config.dart';
import 'package:sooq_merchant/dev/commerce_mock/mock_commerce_data.dart';
import 'package:sooq_merchant/features/commerce/data/models/customer_shipment_status.dart';
import 'package:sooq_merchant/features/commerce/shipping/data/repos/shipping_repo.dart';

class MockShippingRepo implements ShippingRepo {
  Future<void> _delay() =>
      Future<void>.delayed(CommerceMockConfig.requestDelay);

  @override
  Future<Either<Failure, CustomerShipmentStatus>> trackShipment({
    required String orderId,
    String? tenantId,
  }) async {
    AppLogger.network(
      '[MOCK] trackShipment orderId=$orderId tenantId=$tenantId',
    );
    await _delay();
    final raw = MockCommerceData.shipmentEnvelope(orderId);
    if (raw == null) {
      return const Left(ShipmentNotFoundFailure());
    }
    try {
      final response = ApiResponse<CustomerShipmentStatus>.fromJson(
        raw,
        parseData: CustomerShipmentStatus.fromEnvelopeData,
      );
      if (!response.success || response.data == null) {
        return Left(ServerFailure(response.message ?? 'Shipment not found'));
      }
      return Right(response.data!);
    } catch (_) {
      return const Left(ShipmentNotFoundFailure());
    }
  }
}
