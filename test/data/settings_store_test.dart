import 'package:flutter_test/flutter_test.dart';
import 'package:haru_app/data/local/settings_store.dart';
import 'package:haru_app/domain/models/app_settings.dart';
import 'package:haru_app/domain/models/budget_profile.dart';
import 'package:haru_app/domain/models/daily_spend.dart';
import 'package:haru_app/domain/models/schedule_profile.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('settings survive a new store instance', () async {
    final preferences = await SharedPreferences.getInstance();
    final store = SettingsStore(preferences);
    const settings = AppSettings(
      schedule: ScheduleProfile(
        workStartMinutes: 540,
        workEndMinutes: 1080,
        wakeMinutes: 420,
        sleepMinutes: 1410,
        workingWeekdays: {1, 2, 3, 4, 5},
      ),
      budget: BudgetProfile(cycleBudget: 700000, cycleStartDay: 1),
      dailyReminderMinutes: 1260,
      sleepReminderEnabled: true,
      sleepReminderMinutes: 1380,
      wakeNotificationEnabled: true,
      lockScreenLiveEnabled: true,
      lockScreenLiveIntroSeen: true,
      lockScreenMoneyVisible: true,
    );

    await store.saveSettings(settings);

    final restored = SettingsStore(preferences).loadSettings();
    expect(restored, isNotNull);
    expect(restored!.schedule.workStartMinutes, 540);
    expect(restored.schedule.sleepMinutes, 1410);
    expect(restored.budget.cycleBudget, 700000);
    expect(restored.dailyReminderMinutes, 1260);
    expect(restored.sleepReminderEnabled, isTrue);
    expect(restored.sleepReminderMinutes, 1380);
    expect(restored.wakeNotificationEnabled, isTrue);
    expect(restored.lockScreenLiveEnabled, isTrue);
    expect(restored.lockScreenLiveIntroSeen, isTrue);
    expect(restored.lockScreenMoneyVisible, isTrue);
  });

  test('weekday work toggles and individual hours survive restart', () async {
    final preferences = await SharedPreferences.getInstance();
    final store = SettingsStore(preferences);
    const settings = AppSettings(
      schedule: ScheduleProfile(
        workStartMinutes: 540,
        workEndMinutes: 1080,
        wakeMinutes: 420,
        sleepMinutes: 1410,
        workingWeekdays: {1, 2, 3, 4, 5, 6},
        weekdaySchedules: {
          6: WeekdaySchedule(
            isWorking: true,
            workStartMinutes: 540,
            workEndMinutes: 780,
          ),
          7: WeekdaySchedule(
            isWorking: false,
            workStartMinutes: 540,
            workEndMinutes: 1080,
          ),
        },
      ),
      budget: BudgetProfile(cycleBudget: 700000, cycleStartDay: 1),
      dailyReminderMinutes: 1260,
    );

    await store.saveSettings(settings);
    final restored = SettingsStore(preferences).loadSettings()!.schedule;

    expect(restored.isWorkingDay(DateTime.saturday), isTrue);
    expect(restored.workEndFor(DateTime.saturday), 13 * 60);
    expect(restored.isWorkingDay(DateTime.sunday), isFalse);
  });

  test('legacy settings migrate to weekday recommendation defaults', () async {
    SharedPreferences.setMockInitialValues({
      'haru.v1.onboardingComplete': true,
      'haru.v1.workStartMinutes': 540,
      'haru.v1.workEndMinutes': 1080,
      'haru.v1.wakeMinutes': 420,
      'haru.v1.sleepMinutes': 1410,
      'haru.v1.cycleBudget': 700000,
      'haru.v1.cycleStartDay': 1,
      'haru.v1.dailyReminderMinutes': 1260,
    });
    final preferences = await SharedPreferences.getInstance();
    final schedule = SettingsStore(preferences).loadSettings()!.schedule;

    expect(schedule.isWorkingDay(DateTime.monday), isTrue);
    expect(schedule.isWorkingDay(DateTime.friday), isTrue);
    expect(schedule.isWorkingDay(DateTime.saturday), isFalse);
    expect(schedule.isWorkingDay(DateTime.sunday), isFalse);
    final migrated = SettingsStore(preferences).loadSettings()!;
    expect(migrated.sleepReminderEnabled, isFalse);
    expect(migrated.sleepReminderMinutes, 23 * 60);
    expect(migrated.wakeNotificationEnabled, isFalse);
    expect(migrated.lockScreenLiveEnabled, isFalse);
    expect(migrated.lockScreenLiveIntroSeen, isFalse);
    expect(migrated.lockScreenMoneyVisible, isFalse);
  });

  test('daily spends survive a new store instance', () async {
    final preferences = await SharedPreferences.getInstance();
    final store = SettingsStore(preferences);
    final spends = [
      DailySpend(
        date: DateTime(2026, 9, 12),
        amount: 12500,
        updatedAt: DateTime(2026, 9, 12, 20),
      ),
    ];

    await store.saveDailySpends(spends);

    final restored = SettingsStore(preferences).loadDailySpends();
    expect(restored, hasLength(1));
    expect(restored.single.amount, 12500);
    expect(restored.single.date, DateTime(2026, 9, 12));
  });
}
