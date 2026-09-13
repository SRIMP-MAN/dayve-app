import '../models/app_settings.dart';

class SleepNotificationPlan {
  const SleepNotificationPlan({
    required this.sleepReminderAt,
    required this.wakeAt,
  });

  final DateTime? sleepReminderAt;
  final DateTime? wakeAt;
}

class SleepNotificationPlanner {
  const SleepNotificationPlanner();

  SleepNotificationPlan plan({
    required DateTime now,
    required AppSettings settings,
  }) {
    return SleepNotificationPlan(
      sleepReminderAt: settings.sleepReminderEnabled
          ? _nextDaily(now, settings.sleepReminderMinutes)
          : null,
      wakeAt: settings.wakeNotificationEnabled
          ? _nextDaily(now, settings.schedule.wakeMinutes)
          : null,
    );
  }

  DateTime _nextDaily(DateTime now, int minutes) {
    final normalized = minutes % (24 * 60);
    var candidate = DateTime(
      now.year,
      now.month,
      now.day,
      normalized ~/ 60,
      normalized % 60,
    );
    if (!candidate.isAfter(now)) {
      candidate = candidate.add(const Duration(days: 1));
    }
    return candidate;
  }
}
