import 'package:flutter_test/flutter_test.dart';
import 'package:sooq_merchant/core/navigation/auth_redirect.dart';

void main() {
  group('AuthRedirect', () {
    test('initialLocation is home when token exists', () {
      expect(
        AuthRedirect.initialLocation(token: 'access-token'),
        '/home',
      );
    });

    test('initialLocation is splash when logged out', () {
      expect(
        AuthRedirect.initialLocation(token: null),
        '/splash',
      );
    });

    test('logged-in user on login route redirects to home', () {
      expect(
        AuthRedirect.resolve(
          token: 'access-token',
          matchedLocation: '/auth/login',
        ),
        '/home',
      );
    });

    test('logged-out user on home redirects to login', () {
      expect(
        AuthRedirect.resolve(
          token: null,
          matchedLocation: '/home',
        ),
        '/auth/login',
      );
    });

    test('logged-out user may access auth routes', () {
      expect(
        AuthRedirect.resolve(
          token: null,
          matchedLocation: '/auth/otp-reset',
        ),
        isNull,
      );
    });
  });
}
