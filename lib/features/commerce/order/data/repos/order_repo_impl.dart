import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:sooq_merchant/core/errors/failures.dart';
import 'package:sooq_merchant/core/network/api_envelope.dart';
import 'package:sooq_merchant/features/commerce/data/models/cancel_order_request.dart';
import 'package:sooq_merchant/features/commerce/data/models/customer_order.dart';
import 'package:sooq_merchant/features/commerce/data/models/invoice_response.dart';
import 'package:sooq_merchant/features/commerce/data/models/order_list_response.dart';
import 'package:sooq_merchant/features/commerce/order/data/repos/order_repo.dart';

class OrderRepoImpl implements OrderRepo {
  OrderRepoImpl(this._dio);

  static const String _ordersPath = '/api/v1/customer/orders';

  final Dio _dio;

  @override
  Future<Either<Failure, OrderListResponse>> getOrders({
    required int page,
    required int size,
    String? status,
    String? tenantId,
  }) async {
    try {
      final response = await _dio.get<Object>(
        _ordersPath,
        queryParameters: {
          'page': page,
          'size': size,
          if (status != null && status.isNotEmpty) 'status': status,
        },
      );
      final envelope = ApiEnvelope.requireEnvelope(response.data);
      return Right(OrderListResponse.fromJson(envelope));
    } on Failure catch (failure) {
      return Left(failure);
    } on DioException catch (error) {
      return Left(_mapDioException(error));
    } catch (error) {
      return Left(ServerFailure('Unexpected error: $error'));
    }
  }

  @override
  Future<Either<Failure, CustomerOrder>> getOrderDetail({
    required String orderId,
    String? tenantId,
  }) async {
    try {
      final response = await _dio.get<Object>(
        '$_ordersPath/$orderId',
      );
      final parsed = ApiResponse<CustomerOrder>.fromJson(
        ApiEnvelope.requireEnvelope(response.data),
        parseData: CustomerOrder.fromEnvelopeData,
      );
      if (!parsed.success || parsed.data == null) {
        return Left(
          ServerFailure(parsed.message ?? 'الطلب غير موجود'),
        );
      }
      return Right(parsed.data!);
    } on Failure catch (failure) {
      return Left(failure);
    } on DioException catch (error) {
      return Left(_mapDioException(error));
    } catch (error) {
      return Left(ServerFailure('Unexpected error: $error'));
    }
  }

  @override
  Future<Either<Failure, CustomerOrder>> cancelOrder({
    required String orderId,
    CancelOrderRequest? request,
    String? tenantId,
  }) async {
    try {
      final response = await _dio.post<Object>(
        '$_ordersPath/$orderId/cancel',
        data: request?.toJson(),
      );
      final parsed = ApiResponse<CustomerOrder>.fromJson(
        ApiEnvelope.requireEnvelope(response.data),
        parseData: CustomerOrder.fromEnvelopeData,
      );
      if (!parsed.success || parsed.data == null) {
        return Left(
          ServerFailure(parsed.message ?? 'لا يمكن إلغاء هذا الطلب'),
        );
      }
      return Right(parsed.data!);
    } on Failure catch (failure) {
      return Left(failure);
    } on DioException catch (error) {
      return Left(_mapDioException(error));
    } catch (error) {
      return Left(ServerFailure('Unexpected error: $error'));
    }
  }

  @override
  Future<Either<Failure, InvoiceResponse>> getInvoice({
    required String orderId,
    String? tenantId,
  }) async {
    try {
      final response = await _dio.get<Object>(
        '$_ordersPath/$orderId/invoice',
      );
      final parsed = ApiResponse<InvoiceResponse>.fromJson(
        ApiEnvelope.requireEnvelope(response.data),
        parseData: InvoiceResponse.fromEnvelopeData,
      );
      if (!parsed.success || parsed.data == null) {
        return Left(
          ServerFailure(parsed.message ?? 'الفاتورة غير موجودة'),
        );
      }
      return Right(parsed.data!);
    } on Failure catch (failure) {
      return Left(failure);
    } on DioException catch (error) {
      return Left(_mapDioException(error));
    } catch (error) {
      return Left(ServerFailure('Unexpected error: $error'));
    }
  }

  Failure _mapDioException(DioException error) {
    final statusCode = error.response?.statusCode;
    final payload = error.response?.data;
    if (statusCode != null) {
      return ServerFailure.fromResponse(statusCode, payload);
    }
    return ServerFailure(error.message ?? 'Network error');
  }
}
