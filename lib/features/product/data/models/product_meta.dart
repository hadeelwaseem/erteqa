import 'package:equatable/equatable.dart';

class ProductMeta extends Equatable {
  final int page;
  final int size;
  final int total;
  final int totalPages;
  final bool hasNext;
  final bool hasPrev;

  const ProductMeta({
    required this.page,
    required this.size,
    required this.total,
    required this.totalPages,
    required this.hasNext,
    required this.hasPrev,
  });

  factory ProductMeta.fromJson(Map<String, dynamic> json) {
    return ProductMeta(
      page: json['page'] as int? ?? 0,
      size: json['size'] as int? ?? 20,
      total: json['total'] as int? ?? 0,
      totalPages: json['totalPages'] as int? ?? 0,
      hasNext: json['hasNext'] as bool? ?? false,
      hasPrev: json['hasPrev'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'page': page,
      'size': size,
      'total': total,
      'totalPages': totalPages,
      'hasNext': hasNext,
      'hasPrev': hasPrev,
    };
  }

  ProductMeta copyWith({
    int? page,
    int? size,
    int? total,
    int? totalPages,
    bool? hasNext,
    bool? hasPrev,
  }) {
    return ProductMeta(
      page: page ?? this.page,
      size: size ?? this.size,
      total: total ?? this.total,
      totalPages: totalPages ?? this.totalPages,
      hasNext: hasNext ?? this.hasNext,
      hasPrev: hasPrev ?? this.hasPrev,
    );
  }

  @override
  List<Object?> get props => [page, size, total, totalPages, hasNext, hasPrev];
}
