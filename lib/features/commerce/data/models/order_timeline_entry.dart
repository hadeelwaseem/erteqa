import 'package:equatable/equatable.dart';

import 'commerce_json_helpers.dart';
import 'enums/timeline_actor.dart';

/// Audit entry on customer order detail (spec §6).
class OrderTimelineEntry extends Equatable {
  const OrderTimelineEntry({
    required this.timelineId,
    required this.action,
    required this.actor,
    this.details,
    required this.createdAt,
  });

  final String timelineId;
  final String action;
  final TimelineActor actor;
  final String? details;
  final String createdAt;

  factory OrderTimelineEntry.fromJson(Map<String, dynamic> json) {
    return OrderTimelineEntry(
      timelineId: readCommerceString(json['timelineId']) ?? '',
      action: readCommerceString(json['action']) ?? '',
      actor: TimelineActor.fromWire(json['actor'] as String?),
      details: readCommerceString(json['details']),
      createdAt: readCommerceString(json['createdAt']) ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'timelineId': timelineId,
        'action': action,
        'actor': actor.toWire(),
        if (details != null) 'details': details,
        'createdAt': createdAt,
      };

  @override
  List<Object?> get props => [
        timelineId,
        action,
        actor,
        details,
        createdAt,
      ];
}
