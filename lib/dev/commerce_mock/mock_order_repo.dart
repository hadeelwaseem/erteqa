import 'package:dartz/dartz.dart';
import 'package:sooq_merchant/core/errors/failures.dart';
import 'package:sooq_merchant/core/network/api_envelope.dart';
import 'package:sooq_merchant/core/utils/app_logger.dart';
import 'package:sooq_merchant/dev/commerce_mock/commerce_mock_config.dart';
import 'package:sooq_merchant/dev/commerce_mock/mock_commerce_data.dart';
import 'package:sooq_merchant/features/commerce/data/models/cancel_order_request.dart';
import 'package:sooq_merchant/features/commerce/data/models/customer_order.dart';
import 'package:sooq_merchant/features/commerce/data/models/invoice_response.dart';
import 'package:sooq_merchant/features/commerce/data/models/order_list_response.dart';
import 'package:sooq_merchant/features/commerce/order/data/repos/order_repo.dart';

class MockOrderRepo implements OrderRepo {
  Future<void> _delay() =>
      Future<void>.delayed(CommerceMockConfig.requestDelay);

  @override
  Future<Either<Failure, OrderListResponse>> getOrders({
    required int page,
    required int size,
    String? status,
    String? tenantId,
  }) async {
    AppLogger.network(
      '[MOCK] getOrders page=$page size=$size status=$status tenantId=$tenantId',
    );
    await _delay();
    try {
      final raw = MockCommerceData.ordersPageEnvelope(
        page: page,
        size: size,
        status: status,
      );
      final envelope = ApiEnvelope.requireEnvelope(raw);
      return Right(OrderListResponse.fromJson(envelope));
    } catch (_) {
      return Left(ServerFailure('تعذر تحميل الطلبات'));
    }
  }

  @override
  Future<Either<Failure, CustomerOrder>> getOrderDetail({
    required String orderId,
    String? tenantId,
  }) async {
    AppLogger.network('[MOCK] getOrderDetail orderId=$orderId tenantId=$tenantId');
    await _delay();
    final raw = MockCommerceData.orderDetailEnvelope(orderId);
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

  @override
  Future<Either<Failure, CustomerOrder>> cancelOrder({
    required String orderId,
    CancelOrderRequest? request,
    String? tenantId,
  }) async {
    AppLogger.network('[MOCK] cancelOrder orderId=$orderId tenantId=$tenantId');
    await _delay();
    final raw = MockCommerceData.cancelOrderEnvelope(
      orderId,
      reason: request?.reason,
    );
    if (raw == null) {
      return Left(ServerFailure('لا يمكن إلغاء هذا الطلب'));
    }
    try {
      final response = ApiResponse<CustomerOrder>.fromJson(
        raw,
        parseData: CustomerOrder.fromEnvelopeData,
      );
      if (!response.success || response.data == null) {
        return Left(ServerFailure(response.message ?? 'لا يمكن إلغاء هذا الطلب'));
      }
      return Right(response.data!);
    } catch (_) {
      return Left(ServerFailure('لا يمكن إلغاء هذا الطلب'));
    }
  }

  @override
  Future<Either<Failure, InvoiceResponse>> getInvoice({
    required String orderId,
    String? tenantId,
  }) async {
    AppLogger.network('[MOCK] getInvoice orderId=$orderId tenantId=$tenantId');
    await _delay();
    final raw = MockCommerceData.invoiceEnvelope(orderId);
    if (raw == null) {
      return Left(ServerFailure('الفاتورة غير موجودة'));
    }
    try {
      final response = ApiResponse<InvoiceResponse>.fromJson(
        raw,
        parseData: InvoiceResponse.fromEnvelopeData,
      );
      if (!response.success || response.data == null) {
        return Left(ServerFailure(response.message ?? 'الفاتورة غير موجودة'));
      }
      return Right(response.data!);
    } catch (_) {
      return Left(ServerFailure('الفاتورة غير موجودة'));
    }
  }
}
