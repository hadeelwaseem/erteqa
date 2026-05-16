import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sooq_merchant/core/cubits/token_cubit/token_cubit.dart';
import 'package:sooq_merchant/core/errors/failures.dart';
import 'package:sooq_merchant/core/utils/app_logger.dart';
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
      AppLogger.auth('requestOtp validation failed: $validationError');
      emit(AuthFailureState(errMessage: validationError));
      return;
    }

    AppLogger.auth(
      'requestOtp start phone=$phone tenantSlug=${tenantSlug ?? "null"} '
      'tenantId=${tenantId ?? "null"}',
    );
    emit(AuthRequestingOtp(phone: phone, tenantId: tenantId, tenantSlug: tenantSlug));
    final result = await authRepo.requestOtp(request: request);

    if (isClosed) {
      return;
    }

    result.fold(
      (failure) => emit(_emitFailure('requestOtp', failure)),
      (message) {
        AppLogger.auth('requestOtp success: $message');
        emit(
          AuthOtpRequested(
            phone: phone,
            tenantId: tenantId,
            tenantSlug: tenantSlug,
            fullName: fullName,
            message: message,
          ),
        );
      },
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
      AppLogger.auth('verifyOtp validation failed: $validationError');
      emit(AuthFailureState(errMessage: validationError));
      return;
    }

    AppLogger.auth(
      'verifyOtp start phone=$phone tenantSlug=${tenantSlug ?? "null"} '
      'otpLength=${otpCode.length}',
    );
    emit(AuthVerifyingOtp(phone: phone, tenantId: tenantId, tenantSlug: tenantSlug));
    final result = await authRepo.verifyOtp(request: request);

    if (isClosed) {
      return;
    }

    result.fold(
      (failure) => emit(_emitFailure('verifyOtp', failure)),
      (AuthTokenResponse tokenResponse) async {
        AppLogger.auth('verifyOtp success userId=${tokenResponse.userId ?? "n/a"}');
        await tokenCubit.syncFromStorage();
        if (isClosed) {
          return;
        }
        emit(
          AuthAuthenticated(
            tokenResponse: tokenResponse,
          ),
        );
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

  AuthState _emitFailure(String operation, Failure failure) {
    if (failure is AuthFailure) {
      AppLogger.auth(
        '$operation failed: message=${failure.errMessage} '
        'code=${failure.code ?? "n/a"} status=${failure.statusCode ?? "n/a"} '
        'retryAfter=${failure.retryAfterSeconds ?? "n/a"}',
      );
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

    AppLogger.auth('$operation failed: ${failure.errMessage}');
    return AuthFailureState(errMessage: failure.errMessage);
  }
}