import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sooq_merchant/core/errors/failures.dart';
import 'package:sooq_merchant/core/network/network_config.dart';
import 'package:sooq_merchant/features/commerce/shipping/data/repos/shipping_repo_impl.dart';

import '../../product/support/product_test_utils.dart';

Dio _testDio(FakeHttpClientAdapter adapter) {
  return Dio(BaseOptions(baseUrl: NetworkConfig.defaultBaseUrl))
    ..httpClientAdapter = adapter;
}

void main() {
  group('ShippingRepoImpl', () {
    test('trackShipment parses success envelope', () async {
      final adapter = FakeHttpClientAdapter((options) async {
        expect(options.path, '/api/v1/public/shipping/track/ord-1');
        return jsonResponse({
          'success': true,
          'data': {
            'shipmentId': 'ship-1',
            'orderId': 'ord-1',
            'shipmentStatus': 'IN_TRANSIT',
            'statusLabel': 'In transit',
            'createdAt': '2026-06-01T09:00:00.000Z',
            'statusHistory': [],
          },
        });
      });
      final repo = ShippingRepoImpl(_testDio(adapter));

      final result = await repo.trackShipment(
        orderId: 'ord-1',
        tenantId: 'tenant-1',
      );

      result.fold(
        (failure) => fail(failure.errMessage),
        (shipment) {
          expect(shipment.orderId, 'ord-1');
          expect(shipment.statusLabel, 'In transit');
        },
      );
    });

    test('trackShipment maps 404 to ShipmentNotFoundFailure', () async {
      final adapter = FakeHttpClientAdapter((options) async {
        return jsonResponse({'success': false, 'message': 'Not found'}, statusCode: 404);
      });
      final repo = ShippingRepoImpl(_testDio(adapter));

      final result = await repo.trackShipment(orderId: 'missing');

      expect(result.isLeft(), isTrue);
      result.fold(
        (failure) => expect(failure, isA<ShipmentNotFoundFailure>()),
        (_) => fail('expected failure'),
      );
    });
  });
}
