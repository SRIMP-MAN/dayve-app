import 'package:flutter_test/flutter_test.dart';
import 'package:haru_app/data/local/settings_store.dart';
import 'package:haru_app/domain/models/app_settings.dart';
import 'package:haru_app/domain/models/budget_profile.dart';
import 'package:haru_app/domain/models/schedule_entry.dart';
import 'package:haru_app/domain/models/schedule_profile.dart';
import 'package:haru_app/domain/models/time_summary.dart';
import 'package:haru_app/domain/services/schedule_entry_service.dart';
import 'package:haru_app/domain/services/time_engine.dart';
import 'package:haru_app/domain/services/work_end_planner.dart';
import 'package:haru_app/services/notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const settings = AppSettings(
    schedule: ScheduleProfile(
      workStartMinutes: 9 * 60,
      workEndMinutes: 18 * 60,
      wakeMinutes: 7 * 60,
      sleepMinutes: 23 * 60,
      workingWeekdays: {1, 2, 3, 4, 5},
    ),
    budget: BudgetProfile(cycleBudget: 600000, cycleStartDay: 1),
    dailyReminderMinutes: 21 * 60,
  );

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('weekday default work and weekend default day off', () {
    const engine = TimeEngine();
    final friday = engine.calculate(
      now: DateTime(2026, 9, 11, 12),
      profile: settings.schedule,
    );
    final saturday = engine.calculate(
      now: DateTime(2026, 9, 12, 12),
      profile: settings.schedule,
    );

    expect(friday.state, HaruDayState.working);
    expect(saturday.state, HaruDayState.dayOff);
  });

  test('Saturday and Sunday can each be changed to work', () {
    final saturdayWork = settings.schedule.withWeekday(
      DateTime.saturday,
      const WeekdaySchedule(
        isWorking: true,
        workStartMinutes: 9 * 60,
        workEndMinutes: 13 * 60,
      ),
    );
    final weekendWork = saturdayWork.withWeekday(
      DateTime.sunday,
      const WeekdaySchedule(
        isWorking: true,
        workStartMinutes: 10 * 60,
        workEndMinutes: 14 * 60,
      ),
    );

    expect(
      const TimeEngine()
          .calculate(now: DateTime(2026, 9, 12, 11), profile: weekendWork)
          .state,
      HaruDayState.working,
    );
    expect(
      const TimeEngine()
          .calculate(now: DateTime(2026, 9, 13, 11), profile: weekendWork)
          .state,
      HaruDayState.working,
    );
  });

  test('different work hours are selected by weekday', () {
    final profile = settings.schedule.withWeekday(
      DateTime.saturday,
      const WeekdaySchedule(
        isWorking: true,
        workStartMinutes: 9 * 60,
        workEndMinutes: 13 * 60,
      ),
    );
    final result = const TimeEngine().calculate(
      now: DateTime(2026, 9, 12, 12),
      profile: profile,
    );

    expect(result.state, HaruDayState.working);
    expect(result.remaining, const Duration(hours: 1));
    expect(result.progress, .75);
  });

  test('checkout action transitions gauge to afterWork and refreshes widget',
      () async {
    final store = await _savedStore(settings);
    var widgetRefreshes = 0;
    final date = DateTime(2026, 9, 11);
    final entry = await completeCheckout(
      store,
      scheduleDate: date,
      now: DateTime(2026, 9, 11, 18),
      widgetRefresher: (_) async => widgetRefreshes += 1,
    );
    final summary = const TimeEngine().calculate(
      now: DateTime(2026, 9, 11, 18),
      profile: settings.schedule,
      scheduleEntry: entry,
    );

    expect(entry?.type, ScheduleEntryType.checkout);
    expect(summary.state, HaruDayState.afterWork);
    expect(summary.progress, 0);
    expect(widgetRefreshes, 1);
  });

  test('overtime supports +30 minutes, +1 hour and a custom end', () async {
    final store = await _savedStore(settings);
    final service = ScheduleEntryService(store);
    final date = DateTime(2026, 9, 11);

    final plusThirty = await extendOvertime(
      store,
      scheduleDate: date,
      additionalMinutes: 30,
    );
    expect(plusThirty?.workEndMinutes, 18 * 60 + 30);

    await service.delete(date);
    final plusHour = await extendOvertime(
      store,
      scheduleDate: date,
      additionalMinutes: 60,
    );
    expect(plusHour?.workEndMinutes, 19 * 60);

    final custom = await setOvertimeEnd(
      store,
      scheduleDate: date,
      workEndMinutes: 20 * 60 + 15,
    );
    expect(custom?.type, ScheduleEntryType.overtime);
    expect(custom?.workEndMinutes, 20 * 60 + 15);
  });

  test('extended end time becomes the second checkout notification time',
      () async {
    final store = await _savedStore(settings);
    final date = DateTime(2026, 9, 11);
    final overtime = await extendOvertime(
      store,
      scheduleDate: date,
      additionalMinutes: 60,
    );
    final plan = const WorkEndPlanner().next(
      now: DateTime(2026, 9, 11, 18, 1),
      profile: settings.schedule,
      todayEntry: overtime,
      entryForDate: ScheduleEntryService(store).entryForDate,
    );

    expect(plan?.scheduleDate, date);
    expect(plan?.at, DateTime(2026, 9, 11, 19));
  });

  test('today manual schedule replaces a prior overtime override', () async {
    final store = await _savedStore(settings);
    final service = ScheduleEntryService(store);
    final date = DateTime(2026, 9, 11);
    await extendOvertime(
      store,
      scheduleDate: date,
      additionalMinutes: 60,
    );
    await service.save(
      ScheduleEntry(
        date: date,
        type: ScheduleEntryType.custom,
        workStartMinutes: 10 * 60,
        workEndMinutes: 20 * 60,
      ),
    );

    final active = service.entryForDate(date);
    final summary = const TimeEngine().calculate(
      now: DateTime(2026, 9, 11, 19, 30),
      profile: settings.schedule,
      scheduleEntry: active,
    );
    expect(active?.type, ScheduleEntryType.custom);
    expect(summary.state, HaruDayState.working);
    expect(summary.remaining, const Duration(minutes: 30));
  });
}

Future<SettingsStore> _savedStore(AppSettings settings) async {
  final preferences = await SharedPreferences.getInstance();
  final store = SettingsStore(preferences);
  await store.saveSettings(settings);
  return store;
}
