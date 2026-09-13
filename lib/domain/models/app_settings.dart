import 'budget_profile.dart';
import 'schedule_profile.dart';

class AppSettings {
  const AppSettings({
    required this.schedule,
    required this.budget,
    required this.dailyReminderMinutes,
    this.sleepReminderEnabled = false,
    this.sleepReminderMinutes = 23 * 60,
    this.wakeNotificationEnabled = false,
    this.lockScreenLiveEnabled = false,
    this.lockScreenLiveIntroSeen = false,
    this.lockScreenMoneyVisible = false,
  });

  final ScheduleProfile schedule;
  final BudgetProfile budget;

  /// Minutes from 00:00.
  final int dailyReminderMinutes;

  final bool sleepReminderEnabled;

  /// Clock time for the daily bedtime preparation reminder.
  final int sleepReminderMinutes;

  final bool wakeNotificationEnabled;

  final bool lockScreenLiveEnabled;

  final bool lockScreenLiveIntroSeen;

  /// Whether budget values may be shown on the public lock screen surface.
  /// Privacy-first default keeps them hidden until the user opts in.
  final bool lockScreenMoneyVisible;

  AppSettings copyWith({
    ScheduleProfile? schedule,
    BudgetProfile? budget,
    int? dailyReminderMinutes,
    bool? sleepReminderEnabled,
    int? sleepReminderMinutes,
    bool? wakeNotificationEnabled,
    bool? lockScreenLiveEnabled,
    bool? lockScreenLiveIntroSeen,
    bool? lockScreenMoneyVisible,
  }) {
    return AppSettings(
      schedule: schedule ?? this.schedule,
      budget: budget ?? this.budget,
      dailyReminderMinutes: dailyReminderMinutes ?? this.dailyReminderMinutes,
      sleepReminderEnabled: sleepReminderEnabled ?? this.sleepReminderEnabled,
      sleepReminderMinutes: sleepReminderMinutes ?? this.sleepReminderMinutes,
      wakeNotificationEnabled:
          wakeNotificationEnabled ?? this.wakeNotificationEnabled,
      lockScreenLiveEnabled:
          lockScreenLiveEnabled ?? this.lockScreenLiveEnabled,
      lockScreenLiveIntroSeen:
          lockScreenLiveIntroSeen ?? this.lockScreenLiveIntroSeen,
      lockScreenMoneyVisible:
          lockScreenMoneyVisible ?? this.lockScreenMoneyVisible,
    );
  }
}
