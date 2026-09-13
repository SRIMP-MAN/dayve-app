import 'package:flutter_test/flutter_test.dart';
import 'package:haru_app/domain/models/app_settings.dart';
import 'package:haru_app/domain/models/budget_profile.dart';
import 'package:haru_app/domain/models/schedule_profile.dart';
import 'package:haru_app/domain/services/sleep_notification_planner.dart';

void main() {
  const settings = AppSettings(
    schedule: ScheduleProfile(
      workStartMinutes: 9 * 60,
      workEndMinutes: 18 * 60,
      wakeMinutes: 7 * 60,
      sleepMinutes: 23 * 60 + 30,
      workingWeekdays: {1, 2, 3, 4, 5},
    ),
    budget: BudgetProfile(cycleBudget: 600000, cycleStartDay: 1),
    dailyReminderMinutes: 21 * 60,
    sleepReminderEnabled: true,
    sleepReminderMinutes: 23 * 60,
    wakeNotificationEnabled: true,
  );

  test('sleep reminder schedules at the configured daily time', () {
    final plan = const SleepNotificationPlanner().plan(
      now: DateTime(2026, 9, 14, 22),
      settings: settings,
    );

    expect(plan.sleepReminderAt, DateTime(2026, 9, 14, 23));
  });

  test('wake notification schedules for the next configured wake time', () {
    final plan = const SleepNotificationPlanner().plan(
      now: DateTime(2026, 9, 14, 22),
      settings: settings,
    );

    expect(plan.wakeAt, DateTime(2026, 9, 15, 7));
  });

  test('disabled sleep notifications produce no schedules', () {
    final disabled = settings.copyWith(
      sleepReminderEnabled: false,
      wakeNotificationEnabled: false,
    );
    final plan = const SleepNotificationPlanner().plan(
      now: DateTime(2026, 9, 14, 22),
      settings: disabled,
    );

    expect(plan.sleepReminderAt, isNull);
    expect(plan.wakeAt, isNull);
  });
}
