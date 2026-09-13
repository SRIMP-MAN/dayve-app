import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/models/app_settings.dart';
import '../../domain/models/budget_profile.dart';
import '../../domain/models/daily_spend.dart';
import '../../domain/models/day_override.dart';
import '../../domain/models/schedule_profile.dart';
import '../../domain/models/schedule_entry.dart';

class SettingsStore {
  SettingsStore(this._preferences);

  static const _prefix = 'haru.v1.';
  static const _onboardingCompleteKey = '${_prefix}onboardingComplete';
  static const _workStartKey = '${_prefix}workStartMinutes';
  static const _workEndKey = '${_prefix}workEndMinutes';
  static const _wakeKey = '${_prefix}wakeMinutes';
  static const _sleepKey = '${_prefix}sleepMinutes';
  static const _cycleBudgetKey = '${_prefix}cycleBudget';
  static const _cycleStartDayKey = '${_prefix}cycleStartDay';
  static const _reminderKey = '${_prefix}dailyReminderMinutes';
  static const _sleepReminderEnabledKey = '${_prefix}sleepReminderEnabled';
  static const _sleepReminderMinutesKey = '${_prefix}sleepReminderMinutes';
  static const _wakeNotificationEnabledKey =
      '${_prefix}wakeNotificationEnabled';
  static const _lockScreenMoneyVisibleKey = '${_prefix}lockScreenMoneyVisible';
  static const _lockScreenLiveEnabledKey = '${_prefix}lockScreenLiveEnabled';
  static const _lockScreenLiveIntroSeenKey =
      '${_prefix}lockScreenLiveIntroSeen';
  static const _dailySpendsKey = '${_prefix}dailySpends';
  static const _dayOverridesKey = '${_prefix}dayOverrides';
  static const _scheduleEntriesKey = '${_prefix}scheduleEntries';
  static const _weekdaySchedulesKey = '${_prefix}weekdaySchedules';

  final SharedPreferences _preferences;

  AppSettings? loadSettings() {
    if (!(_preferences.getBool(_onboardingCompleteKey) ?? false)) {
      return null;
    }

    final workStart = _preferences.getInt(_workStartKey);
    final workEnd = _preferences.getInt(_workEndKey);
    final wake = _preferences.getInt(_wakeKey);
    final sleep = _preferences.getInt(_sleepKey);
    final cycleBudget = _preferences.getInt(_cycleBudgetKey);
    final cycleStartDay = _preferences.getInt(_cycleStartDayKey);
    final reminder = _preferences.getInt(_reminderKey);

    if ([
      workStart,
      workEnd,
      wake,
      sleep,
      cycleBudget,
      cycleStartDay,
      reminder,
    ].contains(null)) {
      return null;
    }

    final weekdaySchedules = _loadWeekdaySchedules(workStart!, workEnd!);
    return AppSettings(
      schedule: ScheduleProfile(
        workStartMinutes: workStart,
        workEndMinutes: workEnd,
        wakeMinutes: wake!,
        sleepMinutes: sleep!,
        workingWeekdays: {
          for (final entry in weekdaySchedules.entries)
            if (entry.value.isWorking) entry.key,
        },
        weekdaySchedules: weekdaySchedules,
      ),
      budget: BudgetProfile(
        cycleBudget: cycleBudget!,
        cycleStartDay: cycleStartDay!,
      ),
      dailyReminderMinutes: reminder!,
      sleepReminderEnabled:
          _preferences.getBool(_sleepReminderEnabledKey) ?? false,
      sleepReminderMinutes: _preferences.getInt(_sleepReminderMinutesKey) ??
          (sleep - 30) % (24 * 60),
      wakeNotificationEnabled:
          _preferences.getBool(_wakeNotificationEnabledKey) ?? false,
      lockScreenLiveEnabled:
          _preferences.getBool(_lockScreenLiveEnabledKey) ?? false,
      lockScreenLiveIntroSeen:
          _preferences.getBool(_lockScreenLiveIntroSeenKey) ?? false,
      lockScreenMoneyVisible:
          _preferences.getBool(_lockScreenMoneyVisibleKey) ?? false,
    );
  }

  Future<void> saveSettings(AppSettings settings) async {
    await _preferences.setInt(
      _workStartKey,
      settings.schedule.workStartMinutes,
    );
    await _preferences.setInt(_workEndKey, settings.schedule.workEndMinutes);
    await _preferences.setInt(_wakeKey, settings.schedule.wakeMinutes);
    await _preferences.setInt(_sleepKey, settings.schedule.sleepMinutes);
    await _preferences.setString(
      _weekdaySchedulesKey,
      jsonEncode([
        for (var day = DateTime.monday; day <= DateTime.sunday; day += 1)
          {
            'weekday': day,
            'isWorking': settings.schedule.isWorkingDay(day),
            'workStart': settings.schedule.workStartFor(day),
            'workEnd': settings.schedule.workEndFor(day),
          },
      ]),
    );
    await _preferences.setInt(_cycleBudgetKey, settings.budget.cycleBudget);
    await _preferences.setInt(
      _cycleStartDayKey,
      settings.budget.cycleStartDay,
    );
    await _preferences.setInt(
      _reminderKey,
      settings.dailyReminderMinutes,
    );
    await _preferences.setBool(
      _sleepReminderEnabledKey,
      settings.sleepReminderEnabled,
    );
    await _preferences.setInt(
      _sleepReminderMinutesKey,
      settings.sleepReminderMinutes,
    );
    await _preferences.setBool(
      _wakeNotificationEnabledKey,
      settings.wakeNotificationEnabled,
    );
    await _preferences.setBool(
      _lockScreenMoneyVisibleKey,
      settings.lockScreenMoneyVisible,
    );
    await _preferences.setBool(
      _lockScreenLiveEnabledKey,
      settings.lockScreenLiveEnabled,
    );
    await _preferences.setBool(
      _lockScreenLiveIntroSeenKey,
      settings.lockScreenLiveIntroSeen,
    );
    await _preferences.setBool(_onboardingCompleteKey, true);
  }

  Map<int, WeekdaySchedule> _loadWeekdaySchedules(
    int legacyWorkStart,
    int legacyWorkEnd,
  ) {
    final fallback = {
      for (var day = DateTime.monday; day <= DateTime.sunday; day += 1)
        day: WeekdaySchedule(
          isWorking: day <= DateTime.friday,
          workStartMinutes: legacyWorkStart,
          workEndMinutes: legacyWorkEnd,
        ),
    };
    final encoded = _preferences.getString(_weekdaySchedulesKey);
    if (encoded == null || encoded.isEmpty) return fallback;

    try {
      final values = jsonDecode(encoded) as List<dynamic>;
      final restored = <int, WeekdaySchedule>{...fallback};
      for (final value in values) {
        final map = value as Map<String, dynamic>;
        final weekday = map['weekday'] as int;
        if (weekday < DateTime.monday || weekday > DateTime.sunday) continue;
        restored[weekday] = WeekdaySchedule(
          isWorking: map['isWorking'] as bool,
          workStartMinutes: map['workStart'] as int,
          workEndMinutes: map['workEnd'] as int,
        );
      }
      return restored;
    } on FormatException {
      return fallback;
    } on TypeError {
      return fallback;
    }
  }

  List<DailySpend> loadDailySpends() {
    final encoded = _preferences.getString(_dailySpendsKey);
    if (encoded == null || encoded.isEmpty) {
      return const [];
    }

    try {
      final values = jsonDecode(encoded) as List<dynamic>;
      return values.map((value) {
        final map = value as Map<String, dynamic>;
        return DailySpend(
          date: DateTime.parse(map['date'] as String),
          amount: map['amount'] as int,
          updatedAt: DateTime.parse(map['updatedAt'] as String),
        );
      }).toList(growable: false);
    } on FormatException {
      return const [];
    } on TypeError {
      return const [];
    }
  }

  Future<void> saveDailySpends(List<DailySpend> spends) async {
    final encoded = jsonEncode(
      spends
          .map(
            (spend) => {
              'date': spend.date.toIso8601String(),
              'amount': spend.amount,
              'updatedAt': spend.updatedAt.toIso8601String(),
            },
          )
          .toList(growable: false),
    );
    await _preferences.setString(_dailySpendsKey, encoded);
  }

  List<ScheduleEntry> loadScheduleEntries() {
    final encoded = _preferences.getString(_scheduleEntriesKey);
    if (encoded == null || encoded.isEmpty) return const [];

    try {
      final values = jsonDecode(encoded) as List<dynamic>;
      return values.map((value) {
        final map = value as Map<String, dynamic>;
        return ScheduleEntry(
          date: DateTime.parse(map['date'] as String),
          type: ScheduleEntryType.values.byName(map['type'] as String),
          workStartMinutes: map['workStart'] as int?,
          workEndMinutes: map['workEnd'] as int?,
          wakeMinutes: map['wake'] as int?,
          sleepMinutes: map['sleep'] as int?,
        );
      }).toList(growable: false);
    } on FormatException {
      return const [];
    } on ArgumentError {
      return const [];
    } on TypeError {
      return const [];
    }
  }

  Future<void> saveScheduleEntries(List<ScheduleEntry> entries) async {
    final encoded = jsonEncode(
      entries
          .map(
            (entry) => {
              'date': entry.date.toIso8601String(),
              'type': entry.type.name,
              'workStart': entry.workStartMinutes,
              'workEnd': entry.workEndMinutes,
              'wake': entry.wakeMinutes,
              'sleep': entry.sleepMinutes,
            },
          )
          .toList(growable: false),
    );
    await _preferences.setString(_scheduleEntriesKey, encoded);
  }

  List<DayOverride> loadDayOverrides() {
    final encoded = _preferences.getString(_dayOverridesKey);
    if (encoded == null || encoded.isEmpty) return const [];

    try {
      final values = jsonDecode(encoded) as List<dynamic>;
      return values.map((value) {
        final map = value as Map<String, dynamic>;
        return DayOverride(
          date: DateTime.parse(map['date'] as String),
          type: _legacyOverrideType(map['type'] as String),
          customWorkStartMinutes: map['workStart'] as int?,
          customWorkEndMinutes: map['workEnd'] as int?,
          customWakeMinutes: map['wake'] as int?,
          customSleepMinutes: map['sleep'] as int?,
          isDayOff: map['isDayOff'] as bool? ?? false,
        );
      }).toList(growable: false);
    } on FormatException {
      return const [];
    } on ArgumentError {
      return const [];
    } on TypeError {
      return const [];
    }
  }

  Future<void> saveDayOverrides(List<DayOverride> overrides) async {
    final encoded = jsonEncode(
      overrides
          .map(
            (override) => {
              'date': override.date.toIso8601String(),
              'type': override.type.name,
              'workStart': override.customWorkStartMinutes,
              'workEnd': override.customWorkEndMinutes,
              'wake': override.customWakeMinutes,
              'sleep': override.customSleepMinutes,
              'isDayOff': override.isDayOff,
            },
          )
          .toList(growable: false),
    );
    await _preferences.setString(_dayOverridesKey, encoded);
  }
}

DayOverrideType _legacyOverrideType(String name) {
  if (name == 'dinner') return DayOverrideType.appointment;
  return DayOverrideType.values.byName(name);
}
