/// Actor on an order timeline entry.
enum TimelineActor {
  customer('CUSTOMER'),
  merchant('MERCHANT'),
  unknown('');

  const TimelineActor(this.wireValue);

  final String wireValue;

  static TimelineActor fromWire(String? value) {
    if (value == null || value.isEmpty) return unknown;
    for (final actor in TimelineActor.values) {
      if (actor.wireValue == value) return actor;
    }
    return unknown;
  }

  String toWire() => wireValue;
}
