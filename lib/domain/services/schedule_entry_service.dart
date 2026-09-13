import '../../data/local/settings_store.dart';
import '../models/day_override.dart';
import '../models/schedule_entry.dart';
import '../models/schedule_profile.dart';

class ScheduleEntryService {
  ScheduleEntryService(this._store);

  final SettingsStore _store;

  List<ScheduleEntry> load() {
    final entries = [..._store.loadScheduleEntries()];
    for (final legacy in _store.loadDayOverrides()) {
      if (entries.any((entry) => _sameDay(entry.date, legacy.date))) continue;
      entries.add(_fromLegacy(legacy));
    }
    entries.sort((a, b) => a.date.compareTo(b.date));
    return entries;
  }

  ScheduleEntry? entryForDate(DateTime date) {
    for (final entry in load()) {
      if (_sameDay(entry.date, date)) return entry;
    }
    return null;
  }

  ScheduleEntry? activeFor(DateTime now, ScheduleProfile profile) {
    final today = entryForDate(now);
    final yesterday = entryForDate(now.subtract(const Duration(days: 1)));
    if (yesterday != null && !yesterday.isDayOff && yesterday.hasWorkSchedule) {
      final weekday = yesterday.date.weekday;
      final start = yesterday.workStartMinutes ?? profile.workStartFor(weekday);
      final end = yesterday.workEndMinutes ?? profile.workEndFor(weekday);
      final nowMinutes = now.hour * 60 + now.minute;
      if (end <= start && nowMinutes < end) return yesterday;
      if (end >= 24 * 60 && nowMinutes < end - 24 * 60) return yesterday;
    }
    return today;
  }

  Future<ScheduleEntry> save(ScheduleEntry entry) async {
    final normalized = ScheduleEntry(
      date: _dateOnly(entry.date),
      type: entry.type,
      workStartMinutes: entry.workStartMinutes,
      workEndMinutes: entry.workEndMinutes,
      wakeMinutes: entry.wakeMinutes,
      sleepMinutes: entry.sleepMinutes,
    );
    final entries = [..._store.loadScheduleEntries()];
    final index = entries.indexWhere(
      (value) => _sameDay(value.date, normalized.date),
    );
    if (index < 0) {
      entries.add(normalized);
    } else {
      entries[index] = normalized;
    }
    await _store.saveScheduleEntries(entries);
    await _removeLegacy(normalized.date);
    return normalized;
  }

  Future<void> delete(DateTime date) async {
    final entries = _store
        .loadScheduleEntries()
        .where((entry) => !_sameDay(entry.date, date))
        .toList(growable: false);
    await _store.saveScheduleEntries(entries);
    await _removeLegacy(date);
  }

  ScheduleEntry _fromLegacy(DayOverride legacy) {
    final type = legacy.isDayOff || legacy.type == DayOverrideType.dayOff
        ? ScheduleEntryType.dayOff
        : ScheduleEntryType.custom;
    return ScheduleEntry(
      date: _dateOnly(legacy.date),
      type: type,
      workStartMinutes: legacy.customWorkStartMinutes,
      workEndMinutes: legacy.customWorkEndMinutes,
      wakeMinutes: legacy.customWakeMinutes,
      sleepMinutes: legacy.customSleepMinutes,
    );
  }

  Future<void> _removeLegacy(DateTime date) async {
    final legacy = _store
        .loadDayOverrides()
        .where((entry) => !_sameDay(entry.date, date))
        .toList(growable: false);
    await _store.saveDayOverrides(legacy);
  }

  DateTime _dateOnly(DateTime value) =>
      DateTime(value.year, value.month, value.day);

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}
