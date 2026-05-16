import 'package:dio/dio.dart';

abstract class Failure {
  final String errMessage;

  const Failure(this.errMessage);
}

class AuthFailure extends Failure {
  final String? code;
  final int? statusCode;
  final int? retryAfterSeconds;
  final Map<String, dynamic>? details;

  const AuthFailure(
    super.errMessage, {
    this.code,
    this.statusCode,
    this.retryAfterSeconds,
    this.details,
  });

  bool get isRateLimited => statusCode == 429 || code == 'RATE_LIMITED';

  bool get isOtpExpired => code == 'OTP_EXPIRED';

  bool get isOtpInvalid => code == 'OTP_INVALID';
}

class ServerFailure extends Failure {
  ServerFailure(super.errMessage);

  factory ServerFailure.fromDioException(DioException dioException) {
    switch (dioException.type) {
      case DioExceptionType.badCertificate:
        return ServerFailure('badCertificate with ApiServer');

      case DioExceptionType.connectionError ||
          DioExceptionType.connectionTimeout:
        {
          return ServerFailure('لا يوجد اتصال بالانترنت');
        }

      case DioExceptionType.sendTimeout:
        return ServerFailure('Send timeout with ApiServer');

      case DioExceptionType.receiveTimeout:
        return ServerFailure('Receive timeout with ApiServer');

      case DioExceptionType.badResponse:
        return ServerFailure.fromResponse(
          dioException.response!.statusCode,
          dioException.response!.data,
        );
      case DioExceptionType.cancel:
        return ServerFailure('تم الإلغاء');

      case DioExceptionType.unknown:
        return ServerFailure('حدث خطأ, يرجى المحاولة مجدداً');
    }
  }

  factory ServerFailure.fromResponse(int? statusCode, dynamic response) {
    final message = _messageFromResponse(response);

    if (statusCode == 401) {
      return ServerFailure(message ?? 'غير مصرح');
    }
    if (statusCode == 400 || statusCode == 403 || statusCode == 422) {
      return ServerFailure(message ?? 'حدث خطأ, يرجى المحاولة مجدداً');
    }
    if (statusCode == 404) {
      return ServerFailure(message ?? 'غير موجود, يرجى المحاولة لاحقاً');
    }
    if (statusCode == 500) {
      return ServerFailure(message ?? 'حدث خطأ, يرجى المحاولة مجدداً');
    }
    return ServerFailure(message ?? 'حدث خطأ, يرجى المحاولة مجدداً');
  }

  static String? _messageFromResponse(dynamic response) {
    if (response == null) {
      return null;
    }
    if (response is String) {
      final trimmed = response.trim();
      return trimmed.isEmpty ? null : trimmed;
    }
    if (response is Map) {
      final message = response['message'];
      if (message is String && message.isNotEmpty) {
        return message;
      }
      final error = response['error'];
      if (error is String && error.isNotEmpty) {
        return error;
      }
      if (error is Map) {
        final nested = error['message'];
        if (nested is String && nested.isNotEmpty) {
          return nested;
        }
      }
    }
    return null;
  }
}
