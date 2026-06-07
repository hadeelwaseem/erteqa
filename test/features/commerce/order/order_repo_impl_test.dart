import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sooq_merchant/core/network/network_config.dart';
import 'package:sooq_merchant/features/commerce/data/models/cancel_order_request.dart';
import 'package:sooq_merchant/features/commerce/order/data/repos/order_repo_impl.dart';

import '../../product/support/product_test_utils.dart';

Dio _testDio(FakeHttpClientAdapter adapter) {
  return Dio(BaseOptions(baseUrl: NetworkConfig.defaultBaseUrl))
    ..httpClientAdapter = adapter;
}

void main() {
  group('OrderRepoImpl', () {
    test('getOrders parses paged envelope', () async {
      final adapter = FakeHttpClientAdapter((options) async {
        expect(options.path, '/api/v1/customer/orders');
        expect(options.queryParameters['page'], 0);
        expect(options.queryParameters['size'], 20);
        return jsonResponse({
          'success': true,
          'data': [
            {
              'orderId': 'ord-1',
              'tenantId': 'tenant-1',
              'orderNumber': 'SOQ-1',
              'orderStatus': 'CONFIRMED',
              'paymentStatus': 'PAID',
              'paymentMethod': 'COD',
              'subtotal': 100000,
              'discountAmount': 0,
              'taxAmount': 0,
              'total': 100000,
              'itemCount': 1,
              'placedAt': '2026-06-01T09:00:00.000Z',
            },
          ],
          'meta': {
            'page': 0,
            'size': 20,
            'totalPages': 1,
            'totalElements': 1,
            'hasNext': false,
            'last': true,
          },
          'timestamp': 1,
        });
      });
      final repo = OrderRepoImpl(_testDio(adapter));

      final result = await repo.getOrders(page: 0, size: 20);

      result.fold(
        (failure) => fail(failure.errMessage),
        (response) {
          expect(response.data, hasLength(1));
          expect(response.data.first.orderNumber, 'SOQ-1');
        },
      );
    });

    test('getOrderDetail parses single order envelope', () async {
      final adapter = FakeHttpClientAdapter((options) async {
        expect(options.path, '/api/v1/customer/orders/ord-1');
        return jsonResponse({
          'success': true,
          'data': {
            'orderId': 'ord-1',
            'tenantId': 'tenant-1',
            'orderNumber': 'SOQ-1',
            'orderStatus': 'CONFIRMED',
            'paymentStatus': 'PAID',
            'paymentMethod': 'COD',
            'currencyCode': 'SYP',
            'subtotal': 100000,
            'discountAmount': 0,
            'taxAmount': 0,
            'shippingCost': 5000,
            'total': 105000,
            'shippingAddress': {
              'recipientName': 'Test',
              'phone': '+963900000000',
              'addressLabel': 'Home',
              'latitude': 33.5,
              'longitude': 36.3,
            },
            'placedAt': '2026-06-01T09:00:00.000Z',
            'items': [],
            'timeline': [],
          },
        });
      });
      final repo = OrderRepoImpl(_testDio(adapter));

      final result = await repo.getOrderDetail(orderId: 'ord-1');

      result.fold(
        (failure) => fail(failure.errMessage),
        (order) => expect(order.orderId, 'ord-1'),
      );
    });

    test('cancelOrder posts optional reason body', () async {
      final adapter = FakeHttpClientAdapter((options) async {
        expect(options.path, '/api/v1/customer/orders/ord-1/cancel');
        expect(options.method, 'POST');
        expect(options.data, {'reason': 'Changed mind'});
        return jsonResponse({
          'success': true,
          'data': {
            'orderId': 'ord-1',
            'tenantId': 'tenant-1',
            'orderNumber': 'SOQ-1',
            'orderStatus': 'CANCELLED',
            'paymentStatus': 'PAID',
            'paymentMethod': 'COD',
            'currencyCode': 'SYP',
            'subtotal': 100000,
            'discountAmount': 0,
            'taxAmount': 0,
            'shippingCost': 5000,
            'total': 105000,
            'shippingAddress': {
              'recipientName': 'Test',
              'phone': '+963900000000',
              'addressLabel': 'Home',
              'latitude': 33.5,
              'longitude': 36.3,
            },
            'placedAt': '2026-06-01T09:00:00.000Z',
            'items': [],
            'timeline': [],
          },
        });
      });
      final repo = OrderRepoImpl(_testDio(adapter));

      final result = await repo.cancelOrder(
        orderId: 'ord-1',
        request: const CancelOrderRequest(reason: 'Changed mind'),
      );

      result.fold(
        (failure) => fail(failure.errMessage),
        (order) => expect(order.orderStatus.toWire(), 'CANCELLED'),
      );
    });

    test('getInvoice parses pdf url', () async {
      final adapter = FakeHttpClientAdapter((options) async {
        expect(options.path, '/api/v1/customer/orders/ord-1/invoice');
        return jsonResponse({
          'success': true,
          'data': {
            'pdfUrl': 'https://example.com/invoice.pdf',
            'invoiceNumber': 'INV-1',
          },
        });
      });
      final repo = OrderRepoImpl(_testDio(adapter));

      final result = await repo.getInvoice(orderId: 'ord-1');

      result.fold(
        (failure) => fail(failure.errMessage),
        (invoice) => expect(invoice.pdfUrl, 'https://example.com/invoice.pdf'),
      );
    });
  });
}
