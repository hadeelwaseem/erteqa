import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sooq_merchant/core/cubits/token_cubit/token_cubit.dart';
import 'package:sooq_merchant/core/errors/failures.dart';
import 'package:sooq_merchant/features/auth/data/models/auth_token_response.dart';
import 'package:sooq_merchant/features/auth/data/models/customer_otp_request.dart';
import 'package:sooq_merchant/features/auth/data/models/customer_otp_verify_request.dart';
import 'package:sooq_merchant/features/auth/data/repos/auth_repo.dart';

part 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  AuthCubit(this.authRepo, this.tokenCubit) : super(const AuthInitial());

  final AuthRepo authRepo;
  final TokenCubit tokenCubit;

  Future<void> requestOtp({
    required String phone,
    String? tenantId,
    String? tenantSlug,
    String? fullName,
  }) async {
    final request = CustomerOtpRequest(
      phone: phone,
      tenantId: tenantId,
      tenantSlug: tenantSlug,
      fullName: fullName,
    );
    final validationError = request.validate();
    if (validationError != null) {
      emit(AuthFailureState(errMessage: validationError));
      return;
    }

    emit(AuthRequestingOtp(phone: phone, tenantId: tenantId, tenantSlug: tenantSlug));
    final result = await authRepo.requestOtp(request: request);

    if (isClosed) {
      return;
    }

    result.fold(
      (failure) => emit(_mapFailure(failure)),
      (message) => emit(
        AuthOtpRequested(
          phone: phone,
          tenantId: tenantId,
          tenantSlug: tenantSlug,
          fullName: fullName,
          message: message,
        ),
      ),
    );
  }

  Future<void> verifyOtp({
    required String phone,
    required String otpCode,
    String? tenantId,
    String? tenantSlug,
    String? totpCode,
    String? backupCode,
  }) async {
    final request = CustomerOtpVerifyRequest(
      phone: phone,
      otpCode: otpCode,
      tenantId: tenantId,
      tenantSlug: tenantSlug,
      totpCode: totpCode,
      backupCode: backupCode,
    );
    final validationError = request.validate();
    if (validationError != null) {
      emit(AuthFailureState(errMessage: validationError));
      return;
    }

    emit(AuthVerifyingOtp(phone: phone, tenantId: tenantId, tenantSlug: tenantSlug));
    final result = await authRepo.verifyOtp(request: request);

    if (isClosed) {
      return;
    }

    result.fold(
      (failure) => emit(_mapFailure(failure)),
      (AuthTokenResponse tokenResponse) async {
        await tokenCubit.storeToken(tokenResponse.accessToken);
        if (isClosed) {
          return;
        }
        emit(AuthAuthenticated(tokenResponse: tokenResponse));
      },
    );
  }

  Future<void> logout() async {
    await tokenCubit.deleteSavedToken();
    if (isClosed) {
      return;
    }
    emit(const AuthInitial());
  }

  AuthState _mapFailure(Failure failure) {
    if (failure is AuthFailure) {
      if (failure.isRateLimited) {
        return AuthRateLimited(
          errMessage: failure.errMessage,
          retryAfterSeconds: failure.retryAfterSeconds,
          code: failure.code,
        );
      }

      return AuthFailureState(
        errMessage: failure.errMessage,
        code: failure.code,
        retryAfterSeconds: failure.retryAfterSeconds,
      );
    }

    return AuthFailureState(errMessage: failure.errMessage);
  }
}