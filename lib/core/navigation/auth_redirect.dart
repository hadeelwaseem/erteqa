import 'package:sooq_merchant/config/mobile_app_config.dart';

/// Route guards for customer OTP auth and session restore.
class AuthRedirect {
  AuthRedirect._();

  static const String homeRoute = '/home';
  static const String loginRoute = '/auth/login';

  static const Set<String> authRoutes = {'/auth/login', '/auth/otp-reset'};

  static const Set<String> guestIntroRoutes = {'/splash', '/splash-carousel'};

  static const Set<String> publicGuestRoutes = {
    ...authRoutes,
    ...guestIntroRoutes,
  };

  /// Storefront routes reachable without login (browse, search, detail).
  static const Set<String> publicStorefrontRoutes = {
    homeRoute,
    '/products',
    '/search',
    '/categories',
    '/cart',
    '/wishlist',
  };

  static bool isLoggedIn(String? token) =>
      token != null && token.trim().isNotEmpty;

  /// Whether a logged-out user may open [location] without being sent to login.
  static bool isPublicGuestRoute(String location) {
    final path = _normalize(location);
    if (publicGuestRoutes.contains(path)) {
      return true;
    }
    if (publicStorefrontRoutes.contains(path)) {
      return true;
    }
    if (path.startsWith('/product/details/')) {
      return true;
    }
    if (RegExp(r'^/categories/[^/]+/products$').hasMatch(path)) {
      return true;
    }
    return false;
  }

  static String initialLocation({
    required String? token,
    MobileAppConfig? mobileConfig,
  }) {
    if (isLoggedIn(token)) {
      return homeRoute;
    }
    return mobileConfig?.navigation.initialRoute ?? '/splash';
  }

  /// Returns a redirect path, or null to stay on the current route.
  static String? resolve({
    required String? token,
    required String matchedLocation,
  }) {
    final location = _normalize(matchedLocation);
    final loggedIn = isLoggedIn(token);

    if (loggedIn) {
      if (authRoutes.contains(location) ||
          guestIntroRoutes.contains(location)) {
        return homeRoute;
      }
      return null;
    }

    if (isPublicGuestRoute(location)) {
      return null;
    }

    return loginRoute;
  }

  static String _normalize(String location) {
    if (location.isEmpty) {
      return '/';
    }
    final uri = Uri.tryParse(location);
    if (uri != null && uri.path.isNotEmpty) {
      return uri.path;
    }
    return location.split('?').first;
  }
}
