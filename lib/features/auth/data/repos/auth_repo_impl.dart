import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:sooq_merchant/core/errors/failures.dart';
import 'package:sooq_merchant/core/network/auth_token_storage.dart';
import 'package:sooq_merchant/core/utils/constants.dart';
import 'package:sooq_merchant/features/auth/data/models/auth_token_response.dart';
import 'package:sooq_merchant/features/auth/data/models/customer_otp_request.dart';
import 'package:sooq_merchant/features/auth/data/models/customer_otp_verify_request.dart';
import 'package:sooq_merchant/features/auth/data/repos/auth_repo.dart';

class AuthRepoImpl implements AuthRepo {
  AuthRepoImpl(
    this._dio,
    this._tokenStorage, {
    Future<void> Function(Duration) sleep = _defaultSleep,
  }) : _sleep = sleep;

  static const String _requestOtpPath = '/api/v1/customer/auth/otp/request';
  static const String _verifyOtpPath = '/api/v1/customer/auth/otp/verify';

  final Dio _dio;
  final AuthTokenStorage _tokenStorage;
  final Future<void> Function(Duration) _sleep;

  @override
  Future<Either<Failure, String>> requestOtp({
    required CustomerOtpRequest request,
  }) async {
    final validationError = request.validate();
    if (validationError != null) {
      return Left(AuthFailure(validationError));
    }

    return _executeWithRetry<String>(
      operation: () async {
        final response = await _dio.post(
          '$kBaseUrl$_requestOtpPath',
          data: request.toJson(),
          options: _jsonOptions(),
        );
        return _parseOtpRequestResponse(response.data);
      },
      maxAttempts: 3,
      retryDelays: const [
        Duration(milliseconds: 500),
        Duration(seconds: 1),
        Duration(seconds: 2),
      ],
    );
  }

  @override
  Future<Either<Failure, AuthTokenResponse>> verifyOtp({
    required CustomerOtpVerifyRequest request,
  }) async {
    final validationError = request.validate();
    if (validationError != null) {
      return Left(AuthFailure(validationError));
    }

    return _executeWithRetry<AuthTokenResponse>(
      operation: () async {
        final response = await _dio.post(
          '$kBaseUrl$_verifyOtpPath',
          data: request.toJson(),
          options: _jsonOptions(),
        );
        final tokenResponse = _parseVerifyOtpResponse(response.data);
        await _tokenStorage.saveTokens(
          accessToken: tokenResponse.accessToken,
          refreshToken: tokenResponse.refreshToken,
        );
        return tokenResponse;
      },
      maxAttempts: 2,
      retryDelays: const [Duration(milliseconds: 500), Duration(seconds: 1)],
    );
  }

  Options _jsonOptions() {
    return Options(headers: const {'Accept': 'application/json'});
  }

  Future<Either<Failure, T>> _executeWithRetry<T>({
    required Future<T> Function() operation,
    required int maxAttempts,
    required List<Duration> retryDelays,
  }) async {
    var attempt = 0;
    while (true) {
      attempt += 1;
      try {
        final result = await operation();
        return Right(result);
      } on Failure catch (failure) {
        return Left(failure);
      } on DioException catch (error) {
        final failure = _mapDioException(error);
        final shouldRetry = _isNetworkIssue(error) && attempt < maxAttempts;
        if (!shouldRetry) {
          return Left(failure);
        }

        final delayIndex = (attempt - 1).clamp(0, retryDelays.length - 1);
        await _sleep(retryDelays[delayIndex]);
      } catch (error) {
        return Left(ServerFailure('Unexpected error: $error'));
      }
    }
  }

  bool _isNetworkIssue(DioException error) {
    return switch (error.type) {
      DioExceptionType.connectionError ||
      DioExceptionType.connectionTimeout ||
      DioExceptionType.sendTimeout ||
      DioExceptionType.receiveTimeout ||
      DioExceptionType.unknown => true,
      _ => false,
    };
  }

  Failure _mapDioException(DioException error) {
    final response = error.response;
    if (response == null) {
      return ServerFailure.fromDioException(error);
    }

    final statusCode = response.statusCode;
    final payload = response.data;
    final payloadMap = payload is Map<String, dynamic> ? payload : <String, dynamic>{};
    final code = _readString(payloadMap, const ['code', 'errorCode', 'error', 'error_code']);
    final message = _readString(payloadMap, const ['message', 'detail', 'error_description']) ??
        _defaultErrorMessage(statusCode);
    final retryAfterSeconds = _readRetryAfter(response.headers, payloadMap);

    if (statusCode == 429) {
      return AuthFailure(
        message,
        code: code ?? 'RATE_LIMITED',
        statusCode: statusCode,
        retryAfterSeconds: retryAfterSeconds,
        details: payloadMap,
      );
    }

    if (code == 'OTP_EXPIRED' || code == 'OTP_INVALID' || code == 'RESOURCE_NOT_FOUND') {
      return AuthFailure(
        message,
        code: code,
        statusCode: statusCode,
        details: payloadMap,
      );
    }

    if (statusCode != null && statusCode >= 500) {
      return AuthFailure(
        'حدث خطأ, يرجى المحاولة مجدداً',
        code: code,
        statusCode: statusCode,
        details: payloadMap,
      );
    }

    return AuthFailure(
      message,
      code: code,
      statusCode: statusCode,
      details: payloadMap,
    );
  }

  String _parseOtpRequestResponse(dynamic responseData) {
    final responseMap = _requireEnvelope(responseData);
    final payload = responseMap['data'] ?? responseMap['message'];
    if (payload is String && payload.isNotEmpty) {
      return payload;
    }
    if (payload is Map<String, dynamic>) {
      final message = _readString(payload, const ['message', 'detail']);
      if (message != null) {
        return message;
      }
    }
    return 'OTP sent via WhatsApp';
  }

  AuthTokenResponse _parseVerifyOtpResponse(dynamic responseData) {
    final responseMap = _requireEnvelope(responseData);
    final payload = responseMap['data'];
    if (payload is! Map<String, dynamic>) {
      throw const FormatException('OTP verify response envelope is invalid');
    }
    return AuthTokenResponse.fromJson(payload);
  }

  Map<String, dynamic> _requireEnvelope(dynamic responseData) {
    if (responseData is! Map<String, dynamic>) {
      throw const FormatException('API response is not a JSON object');
    }

    final success = responseData['success'];
    if (success is bool && !success) {
      throw AuthFailure(
        _readString(responseData, const ['message', 'detail']) ?? 'Request failed',
        code: _readString(responseData, const ['code', 'errorCode', 'error']),
        statusCode: responseData['status'] is int ? responseData['status'] as int : null,
        details: responseData,
      );
    }

    return responseData;
  }

  String? _readString(Map<String, dynamic> payload, List<String> keys) {
    for (final key in keys) {
      final value = payload[key];
      if (value is String && value.isNotEmpty) {
        return value;
      }
    }
    return null;
  }

  int? _readRetryAfter(Headers headers, Map<String, dynamic> payload) {
    final headerValue = headers.value('retry-after');
    final parsedHeader = int.tryParse(headerValue ?? '');
    if (parsedHeader != null) {
      return parsedHeader;
    }

    final retryAfterSeconds = payload['retryAfterSeconds'] ?? payload['retry_after_seconds'];
    if (retryAfterSeconds is int) {
      return retryAfterSeconds;
    }
    if (retryAfterSeconds is String) {
      return int.tryParse(retryAfterSeconds);
    }
    return null;
  }

  String _defaultErrorMessage(int? statusCode) {
    return switch (statusCode) {
      400 || 403 => 'Request could not be completed',
      404 => 'غير موجود, يرجى المحاولة لاحقاً',
      429 => 'Please wait before trying again',
      500 || 502 || 503 || 504 => 'حدث خطأ, يرجى المحاولة مجدداً',
      _ => 'حدث خطأ, يرجى المحاولة مجدداً',
    };
  }

  static Future<void> _defaultSleep(Duration duration) => Future<void>.delayed(duration);
}