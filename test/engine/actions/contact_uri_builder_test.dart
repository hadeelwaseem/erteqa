import 'package:flutter_test/flutter_test.dart';
import 'package:sooq_merchant/engine/actions/contact_uri_builder.dart';

void main() {
  group('ContactUriBuilder', () {
    test('whatsapp strips non-digits', () {
      expect(
        ContactUriBuilder.buildUri(
          channel: 'whatsapp',
          target: '+963 935 237 452',
        ),
        'https://wa.me/963935237452',
      );
    });

    test('tel uses tel scheme', () {
      expect(
        ContactUriBuilder.buildUri(channel: 'tel', target: '963935237452'),
        'tel:963935237452',
      );
    });

    test('sms uses sms scheme', () {
      expect(
        ContactUriBuilder.buildUri(channel: 'sms', target: '963935237452'),
        'sms:963935237452',
      );
    });

    test('email uses mailto', () {
      expect(
        ContactUriBuilder.buildUri(channel: 'email', target: 'help@sooq.app'),
        'mailto:help@sooq.app',
      );
    });

    test('empty target returns null', () {
      expect(
        ContactUriBuilder.buildUri(channel: 'whatsapp', target: ''),
        isNull,
      );
    });
  });
}
