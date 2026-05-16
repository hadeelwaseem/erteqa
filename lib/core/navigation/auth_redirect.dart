import 'package:sooq_merchant/config/mobile_app_config.dart';

/// Route guards for customer OTP auth and session restore.
class AuthRedirect {
  AuthRedirect._();

  static const String homeRoute = '/home';
  static const String loginRoute = '/auth/login';

  static const Set<String> authRoutes = {
    '/auth/login',
    '/auth/otp-reset',
  };

  static const Set<String> guestIntroRoutes = {
    '/splash',
    '/onboarding',
  };

  static const Set<String> publicGuestRoutes = {
    ...authRoutes,
    ...guestIntroRoutes,
  };

  static bool isLoggedIn(String? token) =>
      token != null && token.trim().isNotEmpty;

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
      if (authRoutes.contains(location) || guestIntroRoutes.contains(location)) {
        return homeRoute;
      }
      return null;
    }

    if (publicGuestRoutes.contains(location)) {
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
