import 'package:flutter_test/flutter_test.dart';
import 'package:sooq_merchant/core/errors/failures.dart';
import 'package:sooq_merchant/core/network/api_envelope.dart';

void main() {
  group('ApiEnvelope.requireEnvelope', () {
    test('returns envelope when success is true', () {
      final envelope = ApiEnvelope.requireEnvelope({
        'success': true,
        'data': {'id': '1'},
      });
      expect(envelope['success'], isTrue);
    });

    test('throws ServerFailure when success is false', () {
      expect(
        () => ApiEnvelope.requireEnvelope({
          'success': false,
          'message': 'Invalid code',
          'fieldErrors': [
            {'field': 'code', 'message': 'expired'},
          ],
        }),
        throwsA(isA<ServerFailure>()),
      );
    });

    test('throws when response is not a map', () {
      expect(
        () => ApiEnvelope.requireEnvelope('bad'),
        throwsA(isA<ServerFailure>()),
      );
    });
  });

  group('ApiEnvelope.parseFieldErrors', () {
    test('parses field error list', () {
      final errors = ApiEnvelope.parseFieldErrors([
        {'field': 'items[0].variantId', 'message': 'must not be null'},
      ]);
      expect(errors, hasLength(1));
      expect(errors.first.field, 'items[0].variantId');
      expect(errors.first.message, 'must not be null');
    });
  });

  group('ApiEnvelope.normalizePagedList', () {
    test('passes through direct list data', () {
      final normalized = ApiEnvelope.normalizePagedList({
        'success': true,
        'data': [
          {'orderId': 'a'},
        ],
        'meta': {'page': 0, 'size': 20, 'total': 1},
      });
      expect(normalized['data'], isA<List>());
      expect((normalized['data'] as List), hasLength(1));
    });

    test('normalizes Spring Page under data', () {
      final normalized = ApiEnvelope.normalizePagedList({
        'success': true,
        'data': {
          'content': [
            {'orderId': 'a'},
          ],
          'totalElements': 137,
          'totalPages': 7,
          'number': 0,
          'size': 20,
          'first': true,
          'last': false,
        },
      });
      expect((normalized['data'] as List), hasLength(1));
      final meta = normalized['meta'] as Map<String, dynamic>;
      expect(meta['page'], 0);
      expect(meta['total'], 137);
      expect(meta['totalPages'], 7);
    });
  });

  group('ApiEnvelope.dataFromEnvelope', () {
    test('parses typed data object', () {
      final result = ApiEnvelope.dataFromEnvelope<Map<String, dynamic>>(
        {
          'success': true,
          'data': {'shippingCostSyp': 25000},
        },
        parse: (data) => data,
      );
      expect(result['shippingCostSyp'], 25000);
    });
  });
}
