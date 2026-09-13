import 'package:flutter_test/flutter_test.dart';
import 'package:haru_app/data/local/settings_store.dart';
import 'package:haru_app/domain/models/app_settings.dart';
import 'package:haru_app/domain/models/budget_profile.dart';
import 'package:haru_app/domain/models/daily_spend.dart';
import 'package:haru_app/domain/models/day_override.dart';
import 'package:haru_app/domain/models/schedule_profile.dart';
import 'package:haru_app/domain/services/daily_spend_service.dart';
import 'package:haru_app/domain/services/widget_refresh_planner.dart';
import 'package:haru_app/domain/services/widget_snapshot_calculator.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

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
  );

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('next meaningful schedule event is selected without polling', () {
    final calculation = const WidgetSnapshotCalculator().calculate(
      now: DateTime(2026, 9, 14, 16),
      settings: settings,
      spends: const [],
    );

    expect(calculation.nextRefresh.at, DateTime(2026, 9, 14, 18));
    expect(
      calculation.nextRefresh.reason,
      WidgetRefreshReason.scheduleEvent,
    );
    expect(calculation.snapshot.validUntil, calculation.nextRefresh.at);
  });

  test('working widget snapshot carries TimeEngine progress', () {
    final calculation = const WidgetSnapshotCalculator().calculate(
      now: DateTime(2026, 9, 14, 12),
      settings: settings,
      spends: const [],
    );

    expect(calculation.snapshot.state, 'working');
    expect(calculation.snapshot.progress, closeTo(1 / 3, .001));
  });

  test('after-work widget snapshot carries restarted free-time progress', () {
    final calculation = const WidgetSnapshotCalculator().calculate(
      now: DateTime(2026, 9, 14, 20, 45),
      settings: settings,
      spends: const [],
    );

    expect(calculation.snapshot.state, 'afterWork');
    expect(calculation.snapshot.progress, closeTo(.5, .001));
  });

  test('midnight refresh wins before an overnight overtime end', () {
    final calculation = const WidgetSnapshotCalculator().calculate(
      now: DateTime(2026, 9, 14, 23, 50),
      settings: settings,
      spends: const [],
      override: DayOverride(
        date: DateTime(2026, 9, 14),
        type: DayOverrideType.overtime,
        customWorkEndMinutes: 25 * 60 + 30,
      ),
    );

    expect(calculation.nextRefresh.at, DateTime(2026, 9, 15));
    expect(calculation.nextRefresh.reason, WidgetRefreshReason.midnight);
  });

  test('after midnight overnight work schedules its actual clock-out', () {
    final calculation = const WidgetSnapshotCalculator().calculate(
      now: DateTime(2026, 9, 15, 0, 1),
      settings: settings,
      spends: const [],
      override: DayOverride(
        date: DateTime(2026, 9, 14),
        type: DayOverrideType.overtime,
        customWorkEndMinutes: 25 * 60 + 30,
      ),
    );

    expect(calculation.time.state.name, 'working');
    expect(calculation.nextRefresh.at, DateTime(2026, 9, 15, 1, 30));
  });

  test('editing spend regenerates widget budget values', () async {
    final preferences = await SharedPreferences.getInstance();
    final spendService = DailySpendService(SettingsStore(preferences));
    final now = DateTime(2026, 9, 14, 12);
    const calculator = WidgetSnapshotCalculator();

    await spendService.update(now, 10000);
    final before = calculator.calculate(
      now: now,
      settings: settings,
      spends: spendService.load(),
    );
    await spendService.update(now, 40000);
    final after = calculator.calculate(
      now: now,
      settings: settings,
      spends: spendService.load(),
    );

    expect(
      after.snapshot.remainingBudgetAmount,
      before.snapshot.remainingBudgetAmount - 30000,
    );
    expect(after.snapshot.budgetAmount, lessThan(before.snapshot.budgetAmount));
  });

  test('cycle boundary is included as a meaningful refresh candidate', () {
    const midMonthSettings = AppSettings(
      schedule: ScheduleProfile(
        workStartMinutes: 9 * 60,
        workEndMinutes: 18 * 60,
        wakeMinutes: 7 * 60,
        sleepMinutes: 23 * 60,
        workingWeekdays: {},
      ),
      budget: BudgetProfile(cycleBudget: 600000, cycleStartDay: 15),
      dailyReminderMinutes: 21 * 60,
    );
    final calculation = const WidgetSnapshotCalculator().calculate(
      now: DateTime(2026, 9, 14, 23),
      settings: midMonthSettings,
      spends: const <DailySpend>[],
    );

    expect(calculation.nextRefresh.at, DateTime(2026, 9, 15));
  });
}
