part of 'auth_cubit.dart';

sealed class AuthState {
  const AuthState();
}

final class AuthInitial extends AuthState {
  const AuthInitial();
}

final class AuthRequestingOtp extends AuthState {
  final String phone;
  final String? tenantId;
  final String? tenantSlug;

  const AuthRequestingOtp({
    required this.phone,
    this.tenantId,
    this.tenantSlug,
  });
}

final class AuthOtpRequested extends AuthState {
  final String phone;
  final String? tenantId;
  final String? tenantSlug;
  final String? fullName;
  final String message;

  const AuthOtpRequested({
    required this.phone,
    required this.message,
    this.tenantId,
    this.tenantSlug,
    this.fullName,
  });
}

final class AuthVerifyingOtp extends AuthState {
  final String phone;
  final String? tenantId;
  final String? tenantSlug;

  const AuthVerifyingOtp({
    required this.phone,
    this.tenantId,
    this.tenantSlug,
  });
}

final class AuthAuthenticated extends AuthState {
  final AuthTokenResponse tokenResponse;

  const AuthAuthenticated({required this.tokenResponse});
}

final class AuthFailureState extends AuthState {
  final String errMessage;
  final String? code;
  final int? retryAfterSeconds;

  const AuthFailureState({
    required this.errMessage,
    this.code,
    this.retryAfterSeconds,
  });

  @override
  String toString() =>
      'AuthFailureState(message: $errMessage, code: ${code ?? "n/a"}, retryAfter: ${retryAfterSeconds ?? "n/a"})';
}

final class AuthRateLimited extends AuthFailureState {
  const AuthRateLimited({
    required super.errMessage,
    super.code,
    super.retryAfterSeconds,
  });

  @override
  String toString() =>
      'AuthRateLimited(message: $errMessage, code: ${code ?? "n/a"}, retryAfter: ${retryAfterSeconds ?? "n/a"}s)';
}