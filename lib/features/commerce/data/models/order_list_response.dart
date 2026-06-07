import 'package:equatable/equatable.dart';
import 'package:sooq_merchant/core/network/api_envelope.dart';
import 'package:sooq_merchant/features/product/data/models/product_meta.dart';

import 'order_summary.dart';

/// Paged list from `GET /customer/orders` (spec §5).
class OrderListResponse extends Equatable {
  const OrderListResponse({
    required this.success,
    this.message,
    required this.data,
    required this.meta,
    required this.timestamp,
  });

  final bool success;
  final String? message;
  final List<OrderSummary> data;
  final ProductMeta meta;
  final int timestamp;

  factory OrderListResponse.fromJson(Map<String, dynamic> json) {
    final normalized = ApiEnvelope.normalizePagedList(json);
    return OrderListResponse(
      success: normalized['success'] as bool? ?? false,
      message: normalized['message'] as String?,
      data: (normalized['data'] as List<dynamic>? ?? [])
          .whereType<Map>()
          .map((item) => OrderSummary.fromJson(Map<String, dynamic>.from(item)))
          .toList(),
      meta: ProductMeta.fromJson(
        Map<String, dynamic>.from(normalized['meta'] as Map? ?? {}),
      ),
      timestamp: (normalized['timestamp'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'success': success,
        if (message != null) 'message': message,
        'data': data.map((item) => item.toJson()).toList(),
        'meta': meta.toJson(),
        'timestamp': timestamp,
      };

  @override
  List<Object?> get props => [success, message, data, meta, timestamp];
}
