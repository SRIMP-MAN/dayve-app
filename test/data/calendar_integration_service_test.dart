import 'package:flutter_test/flutter_test.dart';
import 'package:haru_app/domain/models/schedule_entry.dart';
import 'package:haru_app/services/calendar_integration_service.dart';

void main() {
  test('calendar adapter receives an overnight event calculated in Dart',
      () async {
    final adapter = _FakeCalendarAdapter();
    final service = CalendarIntegrationService(adapter: adapter);
    final entry = ScheduleEntry(
      date: DateTime(2026, 9, 15),
      type: ScheduleEntryType.nightShift,
      workStartMinutes: 20 * 60,
      workEndMinutes: 8 * 60,
    );

    final saved = await service.export(
      entry,
      const DeviceCalendar(id: '7', name: '개인'),
    );

    expect(saved, isTrue);
    expect(adapter.calendarId, '7');
    expect(adapter.title, 'HARU 야간근무');
    expect(adapter.start, DateTime(2026, 9, 15, 20));
    expect(adapter.end, DateTime(2026, 9, 16, 8));
  });

  test('calendar export ignores entries without a work schedule', () async {
    final adapter = _FakeCalendarAdapter();
    final service = CalendarIntegrationService(adapter: adapter);

    final saved = await service.export(
      ScheduleEntry(
        date: DateTime(2026, 9, 15),
        type: ScheduleEntryType.dayOff,
      ),
      const DeviceCalendar(id: '7', name: '개인'),
    );

    expect(saved, isFalse);
    expect(adapter.start, isNull);
  });
}

class _FakeCalendarAdapter implements CalendarAdapter {
  String? calendarId;
  String? title;
  DateTime? start;
  DateTime? end;

  @override
  bool get isSupported => true;

  @override
  Future<bool> requestPermission() async => true;

  @override
  Future<List<DeviceCalendar>> writableCalendars() async => const [
        DeviceCalendar(id: '7', name: '개인'),
      ];

  @override
  Future<bool> addEvent({
    required String calendarId,
    required String title,
    required DateTime start,
    required DateTime end,
  }) async {
    this.calendarId = calendarId;
    this.title = title;
    this.start = start;
    this.end = end;
    return true;
  }
}
