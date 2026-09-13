enum DayOverrideType {
  overtime,
  appointment,
  lateSleep,
  dayOff,
  custom,
}

class DayOverride {
  const DayOverride({
    required this.date,
    required this.type,
    this.customWorkStartMinutes,
    this.customWorkEndMinutes,
    this.customWakeMinutes,
    this.customSleepMinutes,
    this.isDayOff = false,
  });

  final DateTime date;
  final DayOverrideType type;
  final int? customWorkStartMinutes;
  final int? customWorkEndMinutes;
  final int? customWakeMinutes;
  final int? customSleepMinutes;
  final bool isDayOff;
}
