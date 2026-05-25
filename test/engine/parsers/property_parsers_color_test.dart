import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sooq_merchant/engine/tree/parsers/property_parsers.dart';

void main() {
  group('PropertyParsers.parseColor', () {
    test('parses 6-digit opaque hex', () {
      expect(
        PropertyParsers.parseColor('#FF0000'),
        const Color(0xFFFF0000),
      );
    });

    test('parses 8-digit ARGB hex with alpha', () {
      expect(
        PropertyParsers.parseColor('#00000000'),
        Colors.transparent,
      );
      expect(
        PropertyParsers.parseColor('#80FF0000'),
        const Color(0x80FF0000),
      );
    });

    test('parses transparent literal', () {
      expect(PropertyParsers.parseColor('transparent'), Colors.transparent);
    });

    test('returns null for invalid values', () {
      expect(PropertyParsers.parseColor(''), isNull);
      expect(PropertyParsers.parseColor('not-a-color'), isNull);
    });
  });
}
