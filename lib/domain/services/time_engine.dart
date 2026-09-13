import '../models/day_override.dart';
import '../models/schedule_entry.dart';
import '../models/schedule_profile.dart';
import '../models/time_summary.dart';

class TimeEngine {
  const TimeEngine();

  TimeSummary calculate({
    required DateTime now,
    required ScheduleProfile profile,
    ScheduleEntry? scheduleEntry,
    DayOverride? override,
  }) {
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final entryIsForYesterday =
        scheduleEntry != null && _sameDay(scheduleEntry.date, yesterday);
    final entryIsForToday =
        scheduleEntry != null && _sameDay(scheduleEntry.date, today);
    final overrideIsForYesterday =
        override != null && _sameDay(override.date, yesterday);
    final overrideIsForToday =
        override != null && _sameDay(override.date, today);
    final legacyHasWork = overrideIsForToday &&
        !override.isDayOff &&
        (override.type == DayOverrideType.overtime ||
            override.customWorkStartMinutes != null ||
            override.customWorkEndMinutes != null);

    // Early-morning hours can still belong to yesterday's overnight shift.
    final previousStartMinutes = entryIsForYesterday
        ? scheduleEntry.workStartMinutes ??
            profile.workStartFor(yesterday.weekday)
        : overrideIsForYesterday
            ? override.customWorkStartMinutes ??
                profile.workStartFor(yesterday.weekday)
            : profile.workStartFor(yesterday.weekday);
    final previousEndMinutes = entryIsForYesterday
        ? scheduleEntry.workEndMinutes ?? profile.workEndFor(yesterday.weekday)
        : overrideIsForYesterday
            ? override.customWorkEndMinutes ??
                profile.workEndFor(yesterday.weekday)
            : profile.workEndFor(yesterday.weekday);
    final previousWasWorkday = entryIsForYesterday
        ? scheduleEntry.hasWorkSchedule
        : overrideIsForYesterday
            ? !override.isDayOff
            : profile.isWorkingDay(yesterday.weekday);
    final previousIsOvernight = previousEndMinutes <= previousStartMinutes ||
        previousEndMinutes >= 24 * 60;

    if (entryIsForToday && scheduleEntry.isDayOff ||
        overrideIsForToday && override.isDayOff) {
      return _dayOffSummary(now, today);
    }

    if (previousIsOvernight && previousWasWorkday) {
      final previousStart =
          yesterday.add(Duration(minutes: previousStartMinutes));
      final previousEnd = previousEndMinutes >= 24 * 60
          ? yesterday.add(Duration(minutes: previousEndMinutes))
          : today.add(Duration(minutes: previousEndMinutes));
      if (!now.isBefore(previousStart) && now.isBefore(previousEnd)) {
        return _workingSummary(now, previousStart, previousEnd);
      }
    }

    final workStartMinutes = entryIsForToday
        ? scheduleEntry.workStartMinutes ?? profile.workStartFor(today.weekday)
        : overrideIsForToday
            ? override.customWorkStartMinutes ??
                profile.workStartFor(today.weekday)
            : profile.workStartFor(today.weekday);
    final workEndMinutes = entryIsForToday
        ? scheduleEntry.workEndMinutes ?? profile.workEndFor(today.weekday)
        : overrideIsForToday
            ? override.customWorkEndMinutes ?? profile.workEndFor(today.weekday)
            : profile.workEndFor(today.weekday);
    final todayIsWorkday = entryIsForToday
        ? scheduleEntry.hasWorkSchedule
        : legacyHasWork || profile.isWorkingDay(today.weekday);

    if (!todayIsWorkday) {
      return _dayOffSummary(now, today);
    }

    final workStart = today.add(Duration(minutes: workStartMinutes));
    var workEnd = today.add(Duration(minutes: workEndMinutes));
    if (workEndMinutes <= workStartMinutes) {
      workEnd = workEnd.add(const Duration(days: 1));
    }

    if (now.isBefore(workStart)) {
      final wakeMinutes =
          (entryIsForToday ? scheduleEntry.wakeMinutes : null) ??
              (overrideIsForToday ? override.customWakeMinutes : null) ??
              profile.wakeMinutes;
      final wakeAt = today.add(Duration(minutes: wakeMinutes));
      if (now.isBefore(wakeAt) && !wakeAt.isAfter(workStart)) {
        return TimeSummary(
          state: HaruDayState.sleepWindow,
          nextEventAt: wakeAt,
          remaining: wakeAt.difference(now),
          progress: 0,
        );
      }

      return TimeSummary(
        state: HaruDayState.beforeWork,
        nextEventAt: workStart,
        remaining: workStart.difference(now),
        progress: 0,
      );
    }

    if (now.isBefore(workEnd)) {
      return _workingSummary(now, workStart, workEnd);
    }

    final sleepMinutes =
        (entryIsForToday ? scheduleEntry.sleepMinutes : null) ??
            (overrideIsForToday ? override.customSleepMinutes : null) ??
            profile.sleepMinutes;
    var sleepAt = today.add(Duration(minutes: sleepMinutes));
    while (!sleepAt.isAfter(workEnd)) {
      sleepAt = sleepAt.add(const Duration(days: 1));
    }

    if (!now.isBefore(sleepAt)) {
      final wakeMinutes =
          (entryIsForToday ? scheduleEntry.wakeMinutes : null) ??
              (overrideIsForToday ? override.customWakeMinutes : null) ??
              profile.wakeMinutes;
      var wakeAt = today.add(Duration(minutes: wakeMinutes));
      while (!wakeAt.isAfter(sleepAt)) {
        wakeAt = wakeAt.add(const Duration(days: 1));
      }
      return TimeSummary(
        state: HaruDayState.sleepWindow,
        nextEventAt: wakeAt,
        remaining: wakeAt.difference(now),
        progress: 0,
      );
    }

    return TimeSummary(
      state: HaruDayState.afterWork,
      nextEventAt: sleepAt,
      remaining: sleepAt.difference(now),
      progress: _segmentProgress(now, workEnd, sleepAt),
      segmentStartAt: workEnd,
      segmentEndAt: sleepAt,
    );
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  TimeSummary _workingSummary(
    DateTime now,
    DateTime workStart,
    DateTime workEnd,
  ) {
    return TimeSummary(
      state: HaruDayState.working,
      nextEventAt: workEnd,
      remaining: workEnd.difference(now),
      progress: _segmentProgress(now, workStart, workEnd),
      segmentStartAt: workStart,
      segmentEndAt: workEnd,
    );
  }

  double _segmentProgress(DateTime now, DateTime start, DateTime end) {
    final total = end.difference(start).inSeconds;
    if (total <= 0) return 1;
    final elapsed = now.difference(start).inSeconds.clamp(0, total);
    return (elapsed / total).clamp(0.0, 1.0);
  }

  TimeSummary _dayOffSummary(DateTime now, DateTime today) {
    final next = today.add(const Duration(days: 1));
    return TimeSummary(
      state: HaruDayState.dayOff,
      nextEventAt: next,
      remaining: next.difference(now),
      progress: 0,
    );
  }
}
