import 'package:equatable/equatable.dart';

class Year extends Equatable {
  final int? id;
  final String? year;
  final int? stageId;

  const Year({this.id, this.year, this.stageId});

  factory Year.fromJson(Map<String, dynamic> json) => Year(
        id: json['id'] as int?,
        year: json['year'] as String?,
        stageId: json['stage_id'] as int?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'year': year,
        'stage_id': stageId,
      };

  @override
  List<Object?> get props => [id, year, stageId];
}
