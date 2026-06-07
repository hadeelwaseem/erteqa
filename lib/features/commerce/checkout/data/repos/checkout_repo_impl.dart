import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:sooq_merchant/core/errors/failures.dart';
import 'package:sooq_merchant/core/network/api_envelope.dart';
import 'package:sooq_merchant/core/network/tenant_headers.dart';
import 'package:sooq_merchant/features/commerce/checkout/data/repos/checkout_repo.dart';
import 'package:sooq_merchant/features/commerce/data/models/apply_discount_result.dart';
import 'package:sooq_merchant/features/commerce/data/models/checkout_request.dart';
import 'package:sooq_merchant/features/commerce/data/models/customer_order.dart';
import 'package:sooq_merchant/features/commerce/data/models/guest_order_lookup.dart';
import 'package:sooq_merchant/features/commerce/data/models/public_payment_method.dart';
import 'package:sooq_merchant/features/commerce/data/models/shipping_cost_request.dart';
import 'package:sooq_merchant/features/commerce/data/models/shipping_cost_response.dart';

class CheckoutRepoImpl implements CheckoutRepo {
  CheckoutRepoImpl(this._dio);

  static const String _paymentMethodsPath = '/api/v1/public/payments/methods';
  static const String _shippingCalculatePath = '/api/v1/public/shipping/calculate';
  static const String _validateDiscountPath =
      '/api/v1/public/checkout/validate-discount';
  static const String _checkoutPath = '/api/v1/public/checkout';
  static const String _guestLookupPath = '/api/v1/public/checkout/orders/lookup';

  final Dio _dio;

  Map<String, String> _headers(String? tenantId) =>
      TenantHeaders.buildPublicHeaders(tenantId: tenantId);

  @override
  Future<Either<Failure, List<PublicPaymentMethod>>> getPaymentMethods({
    String? tenantId,
  }) async {
    try {
      final response = await _dio.get<Object>(
        _paymentMethodsPath,
        options: Options(headers: _headers(tenantId)),
      );
      final envelope = ApiEnvelope.requireEnvelope(response.data);
      final items = ApiEnvelope.listFromEnvelope(
        envelope,
        parseItem: PublicPaymentMethod.fromEnvelopeData,
      );
      return Right(items);
    } on Failure catch (failure) {
      return Left(failure);
    } on DioException catch (error) {
      return Left(_mapDioException(error));
    } catch (error) {
      return Left(ServerFailure('Unexpected error: $error'));
    }
  }

  @override
  Future<Either<Failure, ShippingCostResponse>> calculateShipping({
    required ShippingCostRequest request,
    String? tenantId,
  }) async {
    try {
      final response = await _dio.post<Object>(
        _shippingCalculatePath,
        data: request.toJson(),
        options: Options(headers: _headers(tenantId)),
      );
      final parsed = ApiResponse<ShippingCostResponse>.fromJson(
        ApiEnvelope.requireEnvelope(response.data),
        parseData: ShippingCostResponse.fromEnvelopeData,
      );
      if (!parsed.success || parsed.data == null) {
        return Left(
          ServerFailure(parsed.message ?? 'تعذر حساب الشحن'),
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
  Future<Either<Failure, ApplyDiscountResult>> validateDiscount({
    required String code,
    required int subtotal,
    required int shippingCost,
    String? tenantId,
  }) async {
    try {
      final response = await _dio.get<Object>(
        _validateDiscountPath,
        queryParameters: {
          'code': code,
          'subtotal': subtotal,
          'shippingCost': shippingCost,
        },
        options: Options(headers: _headers(tenantId)),
      );
      final parsed = ApiResponse<ApplyDiscountResult>.fromJson(
        ApiEnvelope.requireEnvelope(response.data),
        parseData: ApplyDiscountResult.fromEnvelopeData,
      );
      if (!parsed.success || parsed.data == null) {
        return Left(
          ServerFailure(parsed.message ?? 'كود الخصم غير صالح'),
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
  Future<Either<Failure, CustomerOrder>> placeOrder({
    required CheckoutRequest request,
    String? tenantId,
  }) async {
    try {
      final response = await _dio.post<Object>(
        _checkoutPath,
        data: request.toJson(),
        options: Options(headers: _headers(tenantId)),
      );
      final parsed = ApiResponse<CustomerOrder>.fromJson(
        ApiEnvelope.requireEnvelope(response.data),
        parseData: CustomerOrder.fromEnvelopeData,
      );
      if (!parsed.success || parsed.data == null) {
        return Left(
          ServerFailure(parsed.message ?? 'تعذر إنشاء الطلب'),
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
  Future<Either<Failure, CustomerOrder>> lookupGuestOrder({
    required GuestOrderLookup lookup,
    String? tenantId,
  }) async {
    try {
      final response = await _dio.get<Object>(
        _guestLookupPath,
        queryParameters: lookup.toQueryParameters(),
        options: Options(headers: _headers(tenantId)),
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

  Failure _mapDioException(DioException error) {
    final statusCode = error.response?.statusCode;
    final payload = error.response?.data;
    if (statusCode != null) {
      return ServerFailure.fromResponse(statusCode, payload);
    }
    return ServerFailure(error.message ?? 'Network error');
  }
}
