enum ScheduleEntryType { work, dayOff, nightShift, custom, overtime, checkout }

class ScheduleEntry {
  const ScheduleEntry({
    required this.date,
    required this.type,
    this.workStartMinutes,
    this.workEndMinutes,
    this.wakeMinutes,
    this.sleepMinutes,
  });

  final DateTime date;
  final ScheduleEntryType type;
  final int? workStartMinutes;
  final int? workEndMinutes;
  final int? wakeMinutes;
  final int? sleepMinutes;

  bool get isDayOff => type == ScheduleEntryType.dayOff;

  bool get hasWorkSchedule =>
      !isDayOff &&
      (type == ScheduleEntryType.work ||
          type == ScheduleEntryType.nightShift ||
          type == ScheduleEntryType.overtime ||
          type == ScheduleEntryType.checkout ||
          workStartMinutes != null ||
          workEndMinutes != null);
}
