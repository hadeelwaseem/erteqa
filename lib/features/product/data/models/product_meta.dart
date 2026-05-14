import 'package:equatable/equatable.dart';

class ProductMeta extends Equatable {
  final int page;
  final int size;
  final int total;
  final int totalPages;
  final bool hasNext;
  final bool hasPrev;
  final bool last;

  const ProductMeta({
    required this.page,
    required this.size,
    required this.total,
    required this.totalPages,
    required this.hasNext,
    required this.hasPrev,
    required this.last,
  });

  factory ProductMeta.fromJson(Map<String, dynamic> json) {
    final page = (json['page'] as num?)?.toInt() ?? 0;
    final size = (json['size'] as num?)?.toInt() ?? 20;
    final total =
        (json['total'] as num?)?.toInt() ??
        (json['totalElements'] as num?)?.toInt() ??
        0;
    final totalPages = (json['totalPages'] as num?)?.toInt() ?? 0;
    final last = json['last'] as bool? ?? false;
    final hasNext =
        json['hasNext'] as bool? ?? (!last && page < (totalPages - 1));
    final hasPrev = json['hasPrev'] as bool? ?? page > 0;

    return ProductMeta(
      page: page,
      size: size,
      total: total,
      totalPages: totalPages,
      hasNext: hasNext,
      hasPrev: hasPrev,
      last: last || !hasNext,
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
      'last': last,
    };
  }

  ProductMeta copyWith({
    int? page,
    int? size,
    int? total,
    int? totalPages,
    bool? hasNext,
    bool? hasPrev,
    bool? last,
  }) {
    return ProductMeta(
      page: page ?? this.page,
      size: size ?? this.size,
      total: total ?? this.total,
      totalPages: totalPages ?? this.totalPages,
      hasNext: hasNext ?? this.hasNext,
      hasPrev: hasPrev ?? this.hasPrev,
      last: last ?? this.last,
    );
  }

  @override
  List<Object?> get props => [
    page,
    size,
    total,
    totalPages,
    hasNext,
    hasPrev,
    last,
  ];
}
