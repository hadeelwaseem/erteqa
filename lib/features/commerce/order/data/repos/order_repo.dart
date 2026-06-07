import 'package:dartz/dartz.dart';
import 'package:sooq_merchant/core/errors/failures.dart';
import 'package:sooq_merchant/features/commerce/data/models/cancel_order_request.dart';
import 'package:sooq_merchant/features/commerce/data/models/customer_order.dart';
import 'package:sooq_merchant/features/commerce/data/models/invoice_response.dart';
import 'package:sooq_merchant/features/commerce/data/models/order_list_response.dart';

abstract class OrderRepo {
  Future<Either<Failure, OrderListResponse>> getOrders({
    required int page,
    required int size,
    String? status,
    String? tenantId,
  });

  Future<Either<Failure, CustomerOrder>> getOrderDetail({
    required String orderId,
    String? tenantId,
  });

  Future<Either<Failure, CustomerOrder>> cancelOrder({
    required String orderId,
    CancelOrderRequest? request,
    String? tenantId,
  });

  Future<Either<Failure, InvoiceResponse>> getInvoice({
    required String orderId,
    String? tenantId,
  });
}
