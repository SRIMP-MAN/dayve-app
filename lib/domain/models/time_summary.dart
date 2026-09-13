enum HaruDayState {
  beforeWork,
  working,
  afterWork,
  sleepWindow,
  dayOff,
  exception,
}

class TimeSummary {
  const TimeSummary({
    required this.state,
    required this.nextEventAt,
    required this.remaining,
    required this.progress,
    this.segmentStartAt,
    this.segmentEndAt,
  });

  final HaruDayState state;
  final DateTime nextEventAt;
  final Duration remaining;

  /// 0.0 ~ 1.0
  final double progress;

  /// Start and end of the active progress segment. These are populated only
  /// for working and after-work states so presentation layers never need to
  /// reconstruct the schedule.
  final DateTime? segmentStartAt;
  final DateTime? segmentEndAt;
}
