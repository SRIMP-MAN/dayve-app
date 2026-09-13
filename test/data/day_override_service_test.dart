import 'package:flutter_test/flutter_test.dart';
import 'package:haru_app/data/local/settings_store.dart';
import 'package:haru_app/domain/models/schedule_profile.dart';
import 'package:haru_app/domain/services/day_override_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('previous day overtime remains active after midnight', () async {
    final preferences = await SharedPreferences.getInstance();
    final service = DayOverrideService(SettingsStore(preferences));
    const profile = ScheduleProfile(
      workStartMinutes: 9 * 60,
      workEndMinutes: 18 * 60,
      wakeMinutes: 7 * 60,
      sleepMinutes: 23 * 60,
      workingWeekdays: {1, 2, 3, 4, 5},
    );
    await service.setOvertime(DateTime(2026, 9, 11), 25 * 60 + 30);

    final active = service.activeFor(DateTime(2026, 9, 12, 1), profile);

    expect(active, isNotNull);
    expect(active!.customWorkEndMinutes, 25 * 60 + 30);
  });

  test('day override expires on the following normal day', () async {
    final preferences = await SharedPreferences.getInstance();
    final service = DayOverrideService(SettingsStore(preferences));
    const profile = ScheduleProfile(
      workStartMinutes: 9 * 60,
      workEndMinutes: 18 * 60,
      wakeMinutes: 7 * 60,
      sleepMinutes: 23 * 60,
      workingWeekdays: {1, 2, 3, 4, 5},
    );
    await service.setDayOff(DateTime(2026, 9, 14));

    final active = service.activeFor(DateTime(2026, 9, 15, 9), profile);

    expect(active, isNull);
  });
}
