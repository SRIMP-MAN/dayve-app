class WeekdaySchedule {
  const WeekdaySchedule({
    required this.isWorking,
    required this.workStartMinutes,
    required this.workEndMinutes,
  });

  final bool isWorking;
  final int workStartMinutes;
  final int workEndMinutes;

  WeekdaySchedule copyWith({
    bool? isWorking,
    int? workStartMinutes,
    int? workEndMinutes,
  }) {
    return WeekdaySchedule(
      isWorking: isWorking ?? this.isWorking,
      workStartMinutes: workStartMinutes ?? this.workStartMinutes,
      workEndMinutes: workEndMinutes ?? this.workEndMinutes,
    );
  }
}

class ScheduleProfile {
  const ScheduleProfile({
    required this.workStartMinutes,
    required this.workEndMinutes,
    required this.wakeMinutes,
    required this.sleepMinutes,
    required this.workingWeekdays,
    this.weekdaySchedules = const {},
  });

  /// Minutes from 00:00.
  final int workStartMinutes;
  final int workEndMinutes;
  final int wakeMinutes;
  final int sleepMinutes;

  /// Dart weekday values: Monday=1 ... Sunday=7.
  final Set<int> workingWeekdays;

  /// Per-weekday values override the legacy shared work time and weekday set.
  /// Keeping the legacy fields makes previously saved settings migrate safely.
  final Map<int, WeekdaySchedule> weekdaySchedules;

  bool isWorkingDay(int weekday) =>
      weekdaySchedules[weekday]?.isWorking ?? workingWeekdays.contains(weekday);

  int workStartFor(int weekday) =>
      weekdaySchedules[weekday]?.workStartMinutes ?? workStartMinutes;

  int workEndFor(int weekday) =>
      weekdaySchedules[weekday]?.workEndMinutes ?? workEndMinutes;

  ScheduleProfile copyWith({
    int? workStartMinutes,
    int? workEndMinutes,
    int? wakeMinutes,
    int? sleepMinutes,
    Set<int>? workingWeekdays,
    Map<int, WeekdaySchedule>? weekdaySchedules,
  }) {
    return ScheduleProfile(
      workStartMinutes: workStartMinutes ?? this.workStartMinutes,
      workEndMinutes: workEndMinutes ?? this.workEndMinutes,
      wakeMinutes: wakeMinutes ?? this.wakeMinutes,
      sleepMinutes: sleepMinutes ?? this.sleepMinutes,
      workingWeekdays: workingWeekdays ?? this.workingWeekdays,
      weekdaySchedules: weekdaySchedules ?? this.weekdaySchedules,
    );
  }

  ScheduleProfile withWeekday(int weekday, WeekdaySchedule value) {
    final updated = <int, WeekdaySchedule>{...weekdaySchedules, weekday: value};
    return ScheduleProfile(
      workStartMinutes: workStartMinutes,
      workEndMinutes: workEndMinutes,
      wakeMinutes: wakeMinutes,
      sleepMinutes: sleepMinutes,
      workingWeekdays: {
        for (var day = DateTime.monday; day <= DateTime.sunday; day += 1)
          if ((updated[day]?.isWorking ?? workingWeekdays.contains(day))) day,
      },
      weekdaySchedules: updated,
    );
  }
}
