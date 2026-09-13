import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:haru_app/data/local/settings_store.dart';
import 'package:haru_app/domain/models/schedule_entry.dart';
import 'package:haru_app/domain/models/schedule_profile.dart';
import 'package:haru_app/domain/models/time_summary.dart';
import 'package:haru_app/domain/services/schedule_entry_service.dart';
import 'package:haru_app/domain/services/time_engine.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const profile = ScheduleProfile(
    workStartMinutes: 9 * 60,
    workEndMinutes: 18 * 60,
    wakeMinutes: 7 * 60,
    sleepMinutes: 23 * 60,
    workingWeekdays: {1, 2, 3, 4, 5},
  );
  const engine = TimeEngine();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('date-specific work overrides a default day off', () async {
    final service = await _service();
    final date = DateTime(2026, 9, 12);
    await service.save(
      ScheduleEntry(
        date: date,
        type: ScheduleEntryType.work,
        workStartMinutes: 9 * 60,
        workEndMinutes: 18 * 60,
      ),
    );

    final entry = service.activeFor(DateTime(2026, 9, 12, 12), profile);
    final result = engine.calculate(
      now: DateTime(2026, 9, 12, 12),
      profile: profile,
      scheduleEntry: entry,
    );

    expect(result.state, HaruDayState.working);
  });

  test('night shift on a default day off stays working after midnight',
      () async {
    final service = await _service();
    await service.save(
      ScheduleEntry(
        date: DateTime(2026, 9, 12),
        type: ScheduleEntryType.nightShift,
        workStartMinutes: 20 * 60,
        workEndMinutes: 8 * 60,
      ),
    );

    final now = DateTime(2026, 9, 13, 2);
    final entry = service.activeFor(now, profile);
    final result = engine.calculate(
      now: now,
      profile: profile,
      scheduleEntry: entry,
    );

    expect(entry?.date, DateTime(2026, 9, 12));
    expect(result.state, HaruDayState.working);
    expect(result.remaining, const Duration(hours: 6));
  });

  test('future entry applies only when its date arrives', () async {
    final service = await _service();
    final future = DateTime(2026, 9, 15);
    await service.save(
      ScheduleEntry(
        date: future,
        type: ScheduleEntryType.work,
        workStartMinutes: 10 * 60,
        workEndMinutes: 19 * 60,
      ),
    );

    expect(service.activeFor(DateTime(2026, 9, 14, 12), profile), isNull);
    expect(service.activeFor(DateTime(2026, 9, 15, 12), profile), isNotNull);
  });

  test('date change selects the matching entry', () async {
    final service = await _service();
    await service.save(
      ScheduleEntry(
        date: DateTime(2026, 9, 14),
        type: ScheduleEntryType.dayOff,
      ),
    );
    await service.save(
      ScheduleEntry(
        date: DateTime(2026, 9, 15),
        type: ScheduleEntryType.work,
        workStartMinutes: 9 * 60,
        workEndMinutes: 18 * 60,
      ),
    );

    expect(
      service.activeFor(DateTime(2026, 9, 14, 12), profile)?.type,
      ScheduleEntryType.dayOff,
    );
    expect(
      service.activeFor(DateTime(2026, 9, 15, 12), profile)?.type,
      ScheduleEntryType.work,
    );
  });

  test('deletion falls back to the default weekday schedule', () async {
    final service = await _service();
    final date = DateTime(2026, 9, 11);
    await service.save(
      ScheduleEntry(date: date, type: ScheduleEntryType.dayOff),
    );
    await service.delete(date);

    final result = engine.calculate(
      now: DateTime(2026, 9, 11, 12),
      profile: profile,
      scheduleEntry: service.activeFor(date, profile),
    );

    expect(result.state, HaruDayState.working);
  });

  test('legacy dinner data is defensively migrated without failing', () async {
    SharedPreferences.setMockInitialValues({
      'haru.v1.dayOverrides': jsonEncode([
        {
          'date': '2026-09-11T00:00:00.000',
          'type': 'dinner',
          'sleep': 90,
          'isDayOff': false,
        },
      ]),
    });
    final service = await _service();

    final entry = service.entryForDate(DateTime(2026, 9, 11));
    expect(entry, isNotNull);
    expect(entry!.type, ScheduleEntryType.custom);
    expect(entry.sleepMinutes, 90);
  });
}

Future<ScheduleEntryService> _service() async {
  final preferences = await SharedPreferences.getInstance();
  return ScheduleEntryService(SettingsStore(preferences));
}
