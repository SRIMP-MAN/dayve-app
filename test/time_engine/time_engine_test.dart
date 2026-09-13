import 'package:flutter_test/flutter_test.dart';
import 'package:haru_app/domain/models/schedule_profile.dart';
import 'package:haru_app/domain/models/day_override.dart';
import 'package:haru_app/domain/models/time_summary.dart';
import 'package:haru_app/domain/services/time_engine.dart';

void main() {
  const engine = TimeEngine();

  const dayProfile = ScheduleProfile(
    workStartMinutes: 9 * 60,
    workEndMinutes: 18 * 60,
    wakeMinutes: 7 * 60,
    sleepMinutes: 24 * 60 + 30,
    workingWeekdays: {1, 2, 3, 4, 5},
  );

  test('weekday noon is working', () {
    final result = engine.calculate(
      now: DateTime(2026, 9, 11, 12),
      profile: dayProfile,
    );

    expect(result.state, HaruDayState.working);
    expect(result.remaining, const Duration(hours: 6));
    expect(result.progress, closeTo(1 / 3, 0.001));
  });

  test('after-work progress restarts at zero and fills until sleep', () {
    final atWorkEnd = engine.calculate(
      now: DateTime(2026, 9, 11, 18),
      profile: dayProfile,
    );
    final halfway = engine.calculate(
      now: DateTime(2026, 9, 11, 21, 15),
      profile: dayProfile,
    );

    expect(atWorkEnd.state, HaruDayState.afterWork);
    expect(atWorkEnd.progress, 0);
    expect(halfway.state, HaruDayState.afterWork);
    expect(halfway.progress, closeTo(0.5, 0.001));
  });

  test('before work is beforeWork', () {
    final result = engine.calculate(
      now: DateTime(2026, 9, 11, 8),
      profile: dayProfile,
    );

    expect(result.state, HaruDayState.beforeWork);
    expect(result.remaining, const Duration(hours: 1));
  });

  test('early morning is inside sleep window until wake time', () {
    final result = engine.calculate(
      now: DateTime(2026, 9, 11, 2),
      profile: dayProfile,
    );

    expect(result.state, HaruDayState.sleepWindow);
    expect(result.remaining, const Duration(hours: 5));
  });

  test('after sleep time is inside sleep window until next wake time', () {
    const eveningSleepProfile = ScheduleProfile(
      workStartMinutes: 9 * 60,
      workEndMinutes: 18 * 60,
      wakeMinutes: 7 * 60,
      sleepMinutes: 23 * 60 + 30,
      workingWeekdays: {1, 2, 3, 4, 5},
    );
    final result = engine.calculate(
      now: DateTime(2026, 9, 11, 23, 45),
      profile: eveningSleepProfile,
    );

    expect(result.state, HaruDayState.sleepWindow);
    expect(result.remaining, const Duration(hours: 7, minutes: 15));
  });

  test('weekend is dayOff', () {
    final result = engine.calculate(
      now: DateTime(2026, 9, 12, 12),
      profile: dayProfile,
    );

    expect(result.state, HaruDayState.dayOff);
  });

  test('overnight shift keeps early morning inside previous day shift', () {
    const nightProfile = ScheduleProfile(
      workStartMinutes: 20 * 60,
      workEndMinutes: 8 * 60,
      wakeMinutes: 15 * 60,
      sleepMinutes: 10 * 60,
      workingWeekdays: {1, 2, 3, 4, 5},
    );

    // Saturday 02:00 still belongs to Friday 20:00 -> Saturday 08:00 shift.
    final result = engine.calculate(
      now: DateTime(2026, 9, 12, 2),
      profile: nightProfile,
    );

    expect(result.state, HaruDayState.working);
    expect(result.remaining, const Duration(hours: 6));
  });

  test('overtime override extends the working window', () {
    final result = engine.calculate(
      now: DateTime(2026, 9, 11, 19),
      profile: dayProfile,
      override: DayOverride(
        date: DateTime(2026, 9, 11),
        type: DayOverrideType.overtime,
        customWorkEndMinutes: 21 * 60,
      ),
    );

    expect(result.state, HaruDayState.working);
    expect(result.remaining, const Duration(hours: 2));
  });

  test('day off override wins over a working weekday', () {
    final result = engine.calculate(
      now: DateTime(2026, 9, 11, 12),
      profile: dayProfile,
      override: DayOverride(
        date: DateTime(2026, 9, 11),
        type: DayOverrideType.dayOff,
        isDayOff: true,
      ),
    );

    expect(result.state, HaruDayState.dayOff);
  });

  test('late sleep override extends free time past midnight', () {
    final result = engine.calculate(
      now: DateTime(2026, 9, 11, 22),
      profile: dayProfile,
      override: DayOverride(
        date: DateTime(2026, 9, 11),
        type: DayOverrideType.lateSleep,
        customSleepMinutes: 90,
      ),
    );

    expect(result.state, HaruDayState.afterWork);
    expect(result.remaining, const Duration(hours: 3, minutes: 30));
  });

  test('overtime represented beyond 24 hours crosses midnight', () {
    final override = DayOverride(
      date: DateTime(2026, 9, 11),
      type: DayOverrideType.overtime,
      customWorkEndMinutes: 25 * 60 + 30,
    );
    final result = engine.calculate(
      now: DateTime(2026, 9, 12, 1),
      profile: dayProfile,
      override: override,
    );

    expect(result.state, HaruDayState.working);
    expect(result.remaining, const Duration(minutes: 30));
  });

  test('crossing midnight advances from free time into sleep window', () {
    final beforeMidnight = engine.calculate(
      now: DateTime(2026, 9, 14, 23, 59),
      profile: dayProfile,
    );
    final afterSleep = engine.calculate(
      now: DateTime(2026, 9, 15, 0, 31),
      profile: dayProfile,
    );

    expect(beforeMidnight.state, HaruDayState.afterWork);
    expect(beforeMidnight.progress, greaterThan(0.9));
    expect(beforeMidnight.progress, lessThan(1));
    expect(afterSleep.state, HaruDayState.sleepWindow);
  });
}
