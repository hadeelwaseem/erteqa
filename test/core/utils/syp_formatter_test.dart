import 'package:flutter_test/flutter_test.dart';
import 'package:sooq_merchant/core/utils/syp_formatter.dart';

void main() {
  group('formatSyp', () {
    test('formats integer with thousands separators', () {
      expect(formatSyp(125000), '125,000 ل.س');
    });

    test('formats zero', () {
      expect(formatSyp(0), '0 ل.س');
    });

    test('formats negative amounts', () {
      expect(formatSyp(-5000), '-5,000 ل.س');
    });
  });

  group('parseSypAmount', () {
    test('parses int', () {
      expect(parseSypAmount(125000), 125000);
    });

    test('parses whole double', () {
      expect(parseSypAmount(125000.0), 125000);
    });

    test('rejects fractional double', () {
      expect(parseSypAmount(125000.5), isNull);
    });

    test('parses numeric string', () {
      expect(parseSypAmount('25000'), 25000);
    });
  });

  group('SypAmount', () {
    test('toString uses formatter', () {
      expect(SypAmount(1000).toString(), '1,000 ل.س');
    });
  });
}
