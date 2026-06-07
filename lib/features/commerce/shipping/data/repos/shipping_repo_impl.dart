import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:sooq_merchant/core/errors/failures.dart';
import 'package:sooq_merchant/core/network/api_envelope.dart';
import 'package:sooq_merchant/core/network/tenant_headers.dart';
import 'package:sooq_merchant/features/commerce/data/models/customer_shipment_status.dart';
import 'package:sooq_merchant/features/commerce/shipping/data/repos/shipping_repo.dart';

class ShippingRepoImpl implements ShippingRepo {
  ShippingRepoImpl(this._dio);

  final Dio _dio;

  static String _trackPath(String orderId) =>
      '/api/v1/public/shipping/track/$orderId';

  Map<String, String> _headers(String? tenantId) =>
      TenantHeaders.buildPublicHeaders(tenantId: tenantId);

  @override
  Future<Either<Failure, CustomerShipmentStatus>> trackShipment({
    required String orderId,
    String? tenantId,
  }) async {
    try {
      final response = await _dio.get<Object>(
        _trackPath(orderId),
        options: Options(headers: _headers(tenantId)),
      );
      final parsed = ApiResponse<CustomerShipmentStatus>.fromJson(
        ApiEnvelope.requireEnvelope(response.data),
        parseData: CustomerShipmentStatus.fromEnvelopeData,
      );
      if (!parsed.success || parsed.data == null) {
        return const Left(ShipmentNotFoundFailure());
      }
      return Right(parsed.data!);
    } on Failure catch (failure) {
      return Left(failure);
    } on DioException catch (error) {
      if (error.response?.statusCode == 404) {
        return const Left(ShipmentNotFoundFailure());
      }
      return Left(_mapDioException(error));
    } catch (error) {
      return Left(ServerFailure('Unexpected error: $error'));
    }
  }

  Failure _mapDioException(DioException error) {
    final statusCode = error.response?.statusCode;
    final payload = error.response?.data;
    if (statusCode == 404) {
      return const ShipmentNotFoundFailure();
    }
    if (statusCode != null) {
      return ServerFailure.fromResponse(statusCode, payload);
    }
    return ServerFailure(error.message ?? 'Network error');
  }
}
