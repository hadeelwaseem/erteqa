import 'package:flutter_test/flutter_test.dart';
import 'package:sooq_merchant/core/navigation/auth_redirect.dart';

void main() {
  group('AuthRedirect', () {
    test('initialLocation is splash when token exists', () {
      expect(
        AuthRedirect.initialLocation(token: 'access-token'),
        AuthRedirect.splashRoute,
      );
    });

    test('initialLocation is splash when logged out', () {
      expect(AuthRedirect.initialLocation(token: null), '/splash');
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

    test('logged-out user may access storefront routes', () {
      expect(
        AuthRedirect.resolve(token: null, matchedLocation: '/home'),
        isNull,
      );
      expect(
        AuthRedirect.resolve(
          token: null,
          matchedLocation: '/product/details/example-product',
        ),
        isNull,
      );
      expect(
        AuthRedirect.resolve(
          token: null,
          matchedLocation: '/categories/clothing-test/products',
        ),
        isNull,
      );
    });

    test('logged-out user on protected route redirects to login', () {
      expect(
        AuthRedirect.resolve(token: null, matchedLocation: '/checkout'),
        '/auth/login',
      );
    });

    test('logged-out user may access auth routes', () {
      expect(
        AuthRedirect.resolve(token: null, matchedLocation: '/auth/otp-reset'),
        isNull,
      );
    });

    group('logout and protected routes', () {
      test('settings is not a public guest route', () {
        expect(AuthRedirect.isPublicGuestRoute('/settings'), isFalse);
      });

      test('logged-out user on settings redirects to login', () {
        expect(
          AuthRedirect.resolve(token: null, matchedLocation: '/settings'),
          AuthRedirect.loginRoute,
        );
      });

      test('logged-in user on settings stays', () {
        expect(
          AuthRedirect.resolve(
            token: 'access-token',
            matchedLocation: '/settings',
          ),
          isNull,
        );
      });

      test('logged-out user on login route stays', () {
        expect(
          AuthRedirect.resolve(token: null, matchedLocation: '/auth/login'),
          isNull,
        );
      });

      test('logged-in user on splash stays', () {
        expect(
          AuthRedirect.resolve(
            token: 'access-token',
            matchedLocation: AuthRedirect.splashRoute,
          ),
          isNull,
        );
      });

      test('logged-in user on splash-carousel redirects to home', () {
        expect(
          AuthRedirect.resolve(
            token: 'access-token',
            matchedLocation: AuthRedirect.splashCarouselRoute,
          ),
          AuthRedirect.homeRoute,
        );
      });

      test('logged-out user on splash-carousel stays', () {
        expect(
          AuthRedirect.resolve(
            token: null,
            matchedLocation: AuthRedirect.splashCarouselRoute,
          ),
          isNull,
        );
      });
    });
  });
}
