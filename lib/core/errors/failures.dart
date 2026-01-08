import 'package:dio/dio.dart';

abstract class Failure {
  final String errMessage;

  const Failure(this.errMessage);
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
          //  customToast(null,'لا يوجد اتصال بالانترنت');
          return ServerFailure('لا يوجد اتصال بالانترنت');
        }

      // case DioExceptionType.connectionTimeout:
      //   return ServerFailure('Connection timeout with ApiServer');

      case DioExceptionType.sendTimeout:
        return ServerFailure('Send timeout with ApiServer');

      case DioExceptionType.receiveTimeout:
        return ServerFailure('Receive timeout with ApiServer');

      case DioExceptionType.badResponse:
        return ServerFailure.fromResponse(
            dioException.response!.statusCode, dioException.response!.data);
      case DioExceptionType.cancel:
        return ServerFailure('تم الإلغاء');

      case DioExceptionType.unknown:
        return ServerFailure('حدث خطأ, يرجى المحاولة مجدداً');
      default:
        return ServerFailure('Oops! There was an Error, Please try again');
    }
  }

  factory ServerFailure.fromResponse(int? statusCode, dynamic response) {
    if (statusCode == 401) {
      return ServerFailure('غير مصرح');
    }
    if (statusCode == 400 || statusCode == 403) {
      if (response['message'] == null) {
        return ServerFailure(response['error']);
      } else {
        return ServerFailure(response['message']);
      }
    } else if (statusCode == 404) {
      return ServerFailure('غير موجود, يرجى المحاولة لاحقاً');
    } else if (statusCode == 500) {
      return ServerFailure('حدث خطأ, يرجى المحاولة لاحقاً');
    } else if (statusCode == 422) {
      return ServerFailure((response['message']));
    } else {
      return ServerFailure('حدث خطأ, يرجى المحاولة لاحقاً');
    }
  }
}
// import 'package:dio/dio.dart';

// abstract class Failure {
//   final String errMessage;

//   const Failure(this.errMessage);
// }

// class ServerFailure extends Failure {
//   ServerFailure(super.errMessage);

//   factory ServerFailure.fromDioException(DioException dioException) {
//     switch (dioException.type) {
//       case DioExceptionType.badCertificate:
//         return ServerFailure('badCertificate with ApiServer');

//       case DioExceptionType.connectionError:
//         return ServerFailure('Connection error');

//       case DioExceptionType.connectionTimeout:
//         return ServerFailure('Connection timeout with ApiServer');

//       case DioExceptionType.sendTimeout:
//         return ServerFailure('Send timeout with ApiServer');

//       case DioExceptionType.receiveTimeout:
//         return ServerFailure('Receive timeout with ApiServer');

//       case DioExceptionType.badResponse:
//         return ServerFailure.fromResponse(
//             dioException.response!.statusCode, dioException.response!.data);
//       case DioExceptionType.cancel:
//         return ServerFailure('Request to ApiServer was canceled');

//       case DioExceptionType.unknown:
//         return ServerFailure('Unexpected Error, Please try again!');
//       default:
//         return ServerFailure('Oops! There was an Error, Please try again');
//     }
//   }

//   factory ServerFailure.fromResponse(int? statusCode, dynamic response) {
//     if (statusCode == 400 || statusCode == 401 || statusCode == 403) {
//       return ServerFailure(response['message']);
//     } else if (statusCode == 404) {
//       return ServerFailure('Your request not found, Please try later!');
//     } else if (statusCode == 500) {
//       return ServerFailure('Internal Server error, Please try later');
//     } else if (statusCode == 422) {
//       return ServerFailure((response['message']));
//     } else {
//       return ServerFailure('Oops! There was an Error, Please try again');
//     }
//   }
// }
