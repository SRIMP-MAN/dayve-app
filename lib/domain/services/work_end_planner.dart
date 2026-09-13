import '../models/schedule_entry.dart';
import '../models/schedule_profile.dart';

class WorkEndPlan {
  const WorkEndPlan({required this.scheduleDate, required this.at});

  final DateTime scheduleDate;
  final DateTime at;
}

class WorkEndPlanner {
  const WorkEndPlanner();

  WorkEndPlan? next({
    required DateTime now,
    required ScheduleProfile profile,
    required ScheduleEntry? todayEntry,
    required ScheduleEntry? Function(DateTime date) entryForDate,
    int searchDays = 370,
  }) {
    var day = DateTime(now.year, now.month, now.day);
    for (var offset = 0; offset < searchDays; offset += 1) {
      final entry =
          offset == 0 && todayEntry != null && _sameDay(todayEntry.date, day)
              ? todayEntry
              : entryForDate(day);
      final isWorkday = entry?.hasWorkSchedule == true ||
          entry == null && profile.isWorkingDay(day.weekday);
      if (isWorkday && entry?.isDayOff != true) {
        final startMinutes =
            entry?.workStartMinutes ?? profile.workStartFor(day.weekday);
        final endMinutes =
            entry?.workEndMinutes ?? profile.workEndFor(day.weekday);
        var candidate = day.add(Duration(minutes: endMinutes));
        if (endMinutes <= startMinutes) {
          candidate = candidate.add(const Duration(days: 1));
        }
        if (candidate.isAfter(now)) {
          return WorkEndPlan(scheduleDate: day, at: candidate);
        }
      }
      day = day.add(const Duration(days: 1));
    }
    return null;
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}
