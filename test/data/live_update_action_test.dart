import 'package:flutter_test/flutter_test.dart';
import 'package:haru_app/data/local/settings_store.dart';
import 'package:haru_app/domain/models/app_settings.dart';
import 'package:haru_app/domain/models/budget_profile.dart';
import 'package:haru_app/domain/models/live_update_snapshot.dart';
import 'package:haru_app/domain/models/live_update_diagnostic.dart';
import 'package:haru_app/domain/models/schedule_entry.dart';
import 'package:haru_app/domain/models/schedule_profile.dart';
import 'package:haru_app/domain/services/schedule_entry_service.dart';
import 'package:haru_app/services/live_update_service.dart';
import 'package:haru_app/services/notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('lock-screen checkout action is handled by the Flutter schedule service',
      () async {
    final store = await _savedStore();
    final date = _today();
    final service = _serviceWithAction(
      store,
      LiveUpdateAction(type: LiveUpdateActionType.checkout, scheduleDate: date),
    );

    await service.consumePendingLiveUpdateAction();

    expect(
      ScheduleEntryService(store).entryForDate(date)?.type,
      ScheduleEntryType.checkout,
    );
  });

  test('lock-screen overtime +30 action extends the Flutter schedule',
      () async {
    final store = await _savedStore();
    final date = _today();
    final service = _serviceWithAction(
      store,
      LiveUpdateAction(
        type: LiveUpdateActionType.overtime30,
        scheduleDate: date,
      ),
    );

    await service.consumePendingLiveUpdateAction();

    expect(
      ScheduleEntryService(store).entryForDate(date)?.workEndMinutes,
      18 * 60 + 30,
    );
  });

  test('lock-screen overtime +1h action extends the Flutter schedule',
      () async {
    final store = await _savedStore();
    final date = _today();
    final service = _serviceWithAction(
      store,
      LiveUpdateAction(
        type: LiveUpdateActionType.overtime60,
        scheduleDate: date,
      ),
    );

    await service.consumePendingLiveUpdateAction();

    expect(
      ScheduleEntryService(store).entryForDate(date)?.workEndMinutes,
      19 * 60,
    );
  });
}

DateTime _today() {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day);
}

HaruNotificationService _serviceWithAction(
  SettingsStore store,
  LiveUpdateAction action,
) {
  return HaruNotificationService(
    store,
    widgetRefresher: (_) async {},
    liveUpdateService: HaruLiveUpdateService(
      store,
      platform: _ActionPlatform(action),
    ),
  );
}

Future<SettingsStore> _savedStore() async {
  final preferences = await SharedPreferences.getInstance();
  final store = SettingsStore(preferences);
  await store.saveSettings(
    const AppSettings(
      schedule: ScheduleProfile(
        workStartMinutes: 9 * 60,
        workEndMinutes: 18 * 60,
        wakeMinutes: 7 * 60,
        sleepMinutes: 23 * 60,
        workingWeekdays: {1, 2, 3, 4, 5, 6, 7},
      ),
      budget: BudgetProfile(cycleBudget: 600000, cycleStartDay: 25),
      dailyReminderMinutes: 21 * 60,
    ),
  );
  return store;
}

class _ActionPlatform implements LiveUpdatePlatform {
  _ActionPlatform(this._action);

  LiveUpdateAction? _action;

  @override
  Future<LiveUpdatePlatformResult> disable() async =>
      const LiveUpdatePlatformResult(
        delivery: LiveUpdateDelivery.hidden,
        androidApi: 35,
        canPromote: false,
      );

  @override
  Future<LiveUpdateAction?> consumeAction() async {
    final action = _action;
    _action = null;
    return action;
  }

  @override
  Future<bool> openPromotionSettings() async => false;

  @override
  Future<LiveUpdatePlatformResult> sync(LiveUpdatePlan plan) async {
    return const LiveUpdatePlatformResult(
      delivery: LiveUpdateDelivery.standard,
      androidApi: 35,
      canPromote: false,
    );
  }

  @override
  Future<LiveUpdateDiagnostic> diagnose() async =>
      LiveUpdateDiagnostic.unsupported();

  @override
  Future<bool> openNotificationSettings() async => false;

  @override
  Future<bool> openLockScreenSettings() async => false;
}
