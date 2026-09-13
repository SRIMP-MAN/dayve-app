import '../../data/local/settings_store.dart';
import '../models/day_override.dart';
import '../models/schedule_profile.dart';

class DayOverrideService {
  DayOverrideService(this._store);

  final SettingsStore _store;

  DayOverride? forDate(DateTime date) {
    for (final override in _store.loadDayOverrides()) {
      if (_sameDay(override.date, date)) return override;
    }
    return null;
  }

  DayOverride? activeFor(DateTime now, ScheduleProfile profile) {
    final today = forDate(now);
    if (today != null) return today;

    final yesterday = forDate(now.subtract(const Duration(days: 1)));
    if (yesterday == null || yesterday.isDayOff) return null;
    final weekday = yesterday.date.weekday;
    final start =
        yesterday.customWorkStartMinutes ?? profile.workStartFor(weekday);
    final end = yesterday.customWorkEndMinutes ?? profile.workEndFor(weekday);
    final nowMinutes = now.hour * 60 + now.minute;
    if (end <= start && nowMinutes < end) return yesterday;
    if (end >= 24 * 60 && nowMinutes < end - 24 * 60) return yesterday;
    return null;
  }

  Future<DayOverride> setOvertime(DateTime date, int workEndMinutes) {
    return save(
      DayOverride(
        date: _dateOnly(date),
        type: DayOverrideType.overtime,
        customWorkEndMinutes: workEndMinutes,
      ),
    );
  }

  Future<DayOverride> setEvent(
    DateTime date,
    DayOverrideType type,
    int sleepMinutes,
  ) {
    assert(type == DayOverrideType.appointment);
    return save(
      DayOverride(
        date: _dateOnly(date),
        type: type,
        customSleepMinutes: sleepMinutes,
      ),
    );
  }

  Future<DayOverride> setLateSleep(DateTime date, int sleepMinutes) {
    return save(
      DayOverride(
        date: _dateOnly(date),
        type: DayOverrideType.lateSleep,
        customSleepMinutes: sleepMinutes,
      ),
    );
  }

  Future<DayOverride> setDayOff(DateTime date) {
    return save(
      DayOverride(
        date: _dateOnly(date),
        type: DayOverrideType.dayOff,
        isDayOff: true,
      ),
    );
  }

  Future<DayOverride> setCustom({
    required DateTime date,
    required int workStartMinutes,
    required int workEndMinutes,
    required int wakeMinutes,
    required int sleepMinutes,
  }) {
    return save(
      DayOverride(
        date: _dateOnly(date),
        type: DayOverrideType.custom,
        customWorkStartMinutes: workStartMinutes,
        customWorkEndMinutes: workEndMinutes,
        customWakeMinutes: wakeMinutes,
        customSleepMinutes: sleepMinutes,
      ),
    );
  }

  Future<DayOverride> save(DayOverride value) async {
    final values = [..._store.loadDayOverrides()];
    final index = values.indexWhere((item) => _sameDay(item.date, value.date));
    if (index < 0) {
      values.add(value);
    } else {
      values[index] = value;
    }
    await _store.saveDayOverrides(values);
    return value;
  }

  Future<void> clear(DateTime date) async {
    final values = _store
        .loadDayOverrides()
        .where((item) => !_sameDay(item.date, date))
        .toList(growable: false);
    await _store.saveDayOverrides(values);
  }

  DateTime _dateOnly(DateTime value) =>
      DateTime(value.year, value.month, value.day);

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}
