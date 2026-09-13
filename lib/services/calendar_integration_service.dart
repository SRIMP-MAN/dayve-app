import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../domain/models/schedule_entry.dart';

class DeviceCalendar {
  const DeviceCalendar({required this.id, required this.name});

  final String id;
  final String name;
}

abstract interface class CalendarAdapter {
  bool get isSupported;

  Future<bool> requestPermission();

  Future<List<DeviceCalendar>> writableCalendars();

  Future<bool> addEvent({
    required String calendarId,
    required String title,
    required DateTime start,
    required DateTime end,
  });
}

class CalendarIntegrationService {
  CalendarIntegrationService({CalendarAdapter? adapter})
      : _adapter = adapter ?? MethodChannelCalendarAdapter();

  final CalendarAdapter _adapter;

  bool get isSupported => _adapter.isSupported;

  Future<bool> requestPermission() => _adapter.requestPermission();

  Future<List<DeviceCalendar>> writableCalendars() =>
      _adapter.writableCalendars();

  Future<bool> export(ScheduleEntry entry, DeviceCalendar calendar) async {
    if (!entry.hasWorkSchedule) return false;
    final startMinutes = entry.workStartMinutes;
    final endMinutes = entry.workEndMinutes;
    if (startMinutes == null || endMinutes == null) return false;

    final date = DateTime(entry.date.year, entry.date.month, entry.date.day);
    final start = date.add(Duration(minutes: startMinutes));
    var end = date.add(Duration(minutes: endMinutes));
    if (!end.isAfter(start)) end = end.add(const Duration(days: 1));

    return _adapter.addEvent(
      calendarId: calendar.id,
      title:
          entry.type == ScheduleEntryType.nightShift ? 'HARU 야간근무' : 'HARU 근무',
      start: start,
      end: end,
    );
  }
}

class MethodChannelCalendarAdapter implements CalendarAdapter {
  static const _channel = MethodChannel('haru/calendar');

  @override
  bool get isSupported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  @override
  Future<bool> requestPermission() async {
    if (!isSupported) return false;
    return await _channel.invokeMethod<bool>('requestPermission') ?? false;
  }

  @override
  Future<List<DeviceCalendar>> writableCalendars() async {
    if (!isSupported) return const [];
    final values = await _channel.invokeListMethod<Map<dynamic, dynamic>>(
          'writableCalendars',
        ) ??
        const [];
    return values
        .map(
          (value) => DeviceCalendar(
            id: '${value['id']}',
            name: '${value['name']}',
          ),
        )
        .toList(growable: false);
  }

  @override
  Future<bool> addEvent({
    required String calendarId,
    required String title,
    required DateTime start,
    required DateTime end,
  }) async {
    if (!isSupported) return false;
    return await _channel.invokeMethod<bool>('addEvent', {
          'calendarId': calendarId,
          'title': title,
          'startMillis': start.millisecondsSinceEpoch,
          'endMillis': end.millisecondsSinceEpoch,
        }) ??
        false;
  }
}
