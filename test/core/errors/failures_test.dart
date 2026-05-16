import 'package:flutter_test/flutter_test.dart';
import 'package:sooq_merchant/core/errors/failures.dart';

void main() {
  group('ServerFailure.fromResponse', () {
    test('handles string response bodies without throwing', () {
      final failure = ServerFailure.fromResponse(400, 'Invalid tenant');

      expect(failure.errMessage, 'Invalid tenant');
    });

    test('reads message from map response bodies', () {
      final failure = ServerFailure.fromResponse(422, {
        'message': 'Validation failed',
      });

      expect(failure.errMessage, 'Validation failed');
    });

    test('falls back to default message when body is empty', () {
      final failure = ServerFailure.fromResponse(404, '');

      expect(failure.errMessage, contains('غير موجود'));
    });
  });
}
