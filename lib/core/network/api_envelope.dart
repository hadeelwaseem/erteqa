import 'package:sooq_merchant/core/errors/failures.dart';
import 'package:sooq_merchant/features/product/data/models/product_meta.dart';

/// Parsed field-level validation error from API error envelopes (§0.4).
class ApiFieldError {
  const ApiFieldError({required this.field, required this.message});

  final String field;
  final String message;

  factory ApiFieldError.fromJson(Map<String, dynamic> json) {
    return ApiFieldError(
      field: json['field'] as String? ?? '',
      message: json['message'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {'field': field, 'message': message};
}

/// Single-object API response wrapper (`ApiResponse<T>` in spec §0.3).
class ApiResponse<T> {
  const ApiResponse({
    required this.success,
    this.message,
    this.data,
    this.errorCode,
    this.fieldErrors = const [],
    this.timestamp,
  });

  final bool success;
  final String? message;
  final T? data;
  final String? errorCode;
  final List<ApiFieldError> fieldErrors;
  final int? timestamp;

  factory ApiResponse.fromJson(
    Map<String, dynamic> json, {
    required T Function(Map<String, dynamic> data)? parseData,
  }) {
    final rawData = json['data'];
    T? data;
    if (parseData != null && rawData is Map<String, dynamic>) {
      data = parseData(rawData);
    }
    return ApiResponse(
      success: json['success'] as bool? ?? false,
      message: ApiEnvelope.readString(json, const ['message']),
      data: data,
      errorCode: ApiEnvelope.readString(json, const ['errorCode']),
      fieldErrors: ApiEnvelope.parseFieldErrors(json['fieldErrors']),
      timestamp: (json['timestamp'] as num?)?.toInt(),
    );
  }
}

/// Paged list response after envelope normalization.
class PagedApiResponse<T> {
  const PagedApiResponse({
    required this.success,
    required this.data,
    required this.meta,
    this.message,
    this.timestamp = 0,
  });

  final bool success;
  final String? message;
  final List<T> data;
  final ProductMeta meta;
  final int timestamp;
}

/// Shared helpers for commerce (and future) repos parsing spec envelopes.
class ApiEnvelope {
  ApiEnvelope._();

  /// Validates a JSON object envelope; throws [ServerFailure] when `success == false`.
  static Map<String, dynamic> requireEnvelope(dynamic responseData) {
    if (responseData is! Map<String, dynamic>) {
      throw ServerFailure('API response is not a JSON object');
    }

    final success = responseData['success'];
    if (success is bool && !success) {
      final message = readString(responseData, const ['message', 'detail']) ??
          'Request failed';
      final fieldErrors = parseFieldErrors(responseData['fieldErrors']);
      if (fieldErrors.isNotEmpty) {
        final details = fieldErrors.map((e) => '${e.field}: ${e.message}').join('; ');
        throw ServerFailure('$message ($details)');
      }
      throw ServerFailure(message);
    }

    return responseData;
  }

  static List<ApiFieldError> parseFieldErrors(dynamic raw) {
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((item) => ApiFieldError.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  /// Extracts and parses `data` from a success envelope.
  static T dataFromEnvelope<T>(
    Map<String, dynamic> envelope, {
    required T Function(Map<String, dynamic> data) parse,
  }) {
    final data = envelope['data'];
    if (data is! Map<String, dynamic>) {
      throw ServerFailure('Response data must be an object');
    }
    return parse(data);
  }

  /// Extracts a list from `data` in a success envelope.
  static List<T> listFromEnvelope<T>(
    Map<String, dynamic> envelope, {
    required T Function(Map<String, dynamic> item) parseItem,
  }) {
    final data = envelope['data'];
    if (data is! List) {
      throw ServerFailure('Response data must be a list');
    }
    return data
        .whereType<Map>()
        .map((item) => parseItem(Map<String, dynamic>.from(item)))
        .toList();
  }

  /// Normalizes list payloads inside an envelope to `{ data: List, meta?: Map }`.
  ///
  /// Accepts:
  /// - `data` as a direct list (`PagedApiResponse`)
  /// - `data` as Spring `Page` (`content`, `totalElements`, …)
  static Map<String, dynamic> normalizePagedList(Map<String, dynamic> envelope) {
    final data = envelope['data'];
    if (data is List) {
      return envelope;
    }

    if (data is Map<String, dynamic>) {
      final items = data['content'] ?? data['items'] ?? data['products'];
      if (items is List) {
        return {
          ...envelope,
          'data': items,
          if (envelope['meta'] == null)
            'meta': normalizeSpringPageMeta(data),
        };
      }
    }

    throw ServerFailure('Paged response data must be a list or page object');
  }

  /// Maps Spring Page fields to [ProductMeta]-compatible meta map.
  static Map<String, dynamic> normalizeSpringPageMeta(Map<String, dynamic> page) {
    if (page.containsKey('page') || page.containsKey('meta')) {
      final meta = page['meta'];
      if (meta is Map<String, dynamic>) return meta;
    }

    final number = (page['number'] as num?)?.toInt() ?? 0;
    final size = (page['size'] as num?)?.toInt() ?? 20;
    final totalElements = (page['totalElements'] as num?)?.toInt() ?? 0;
    final totalPages = (page['totalPages'] as num?)?.toInt() ?? 0;
    final last = page['last'] as bool? ?? false;
    final first = page['first'] as bool? ?? number == 0;

    return {
      'page': number,
      'size': size,
      'total': totalElements,
      'totalPages': totalPages,
      'hasNext': !last && number < (totalPages - 1),
      'hasPrev': !first && number > 0,
      'last': last,
    };
  }

  /// Normalizes a Spring Page object (may be nested under `data`) to list + meta.
  static Map<String, dynamic> normalizeSpringPage(Map<String, dynamic> page) {
    final content = page['content'];
    if (content is! List) {
      throw ServerFailure('Spring page content must be a list');
    }
    return {
      'data': content,
      'meta': normalizeSpringPageMeta(page),
      'success': page['success'] as bool? ?? true,
      'timestamp': (page['timestamp'] as num?)?.toInt() ?? 0,
    };
  }

  static String? readString(Map<String, dynamic> payload, List<String> keys) {
    for (final key in keys) {
      final value = payload[key];
      if (value is String && value.isNotEmpty) {
        return value;
      }
    }
    return null;
  }
}
