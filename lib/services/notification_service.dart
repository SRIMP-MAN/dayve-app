import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../data/local/settings_store.dart';
import '../domain/models/app_settings.dart';
import '../domain/models/live_update_diagnostic.dart';
import '../domain/models/schedule_entry.dart';
import '../domain/services/daily_spend_service.dart';
import '../domain/services/schedule_entry_service.dart';
import '../domain/services/sleep_notification_planner.dart';
import '../domain/services/work_end_planner.dart';
import 'home_widget_service.dart';
import 'live_update_service.dart';

const clockOutNotificationActionId = 'haru_clock_out';
const overtimeNotificationActionId = 'haru_overtime';
const _quickSpendAction = 'haru_quick_spend';
const _workEndNotificationId = 1001;
const _spendReminderNotificationId = 1002;
const _sleepReminderNotificationId = 1003;
const _wakeNotificationId = 1004;

enum NotificationQuickAction { overtime }

class PendingNotificationAction {
  const PendingNotificationAction({required this.type, required this.date});

  final NotificationQuickAction type;
  final DateTime date;
}

@pragma('vm:entry-point')
Future<void> notificationTapBackground(NotificationResponse response) async {
  if (kIsWeb) return;
  final preferences = await SharedPreferences.getInstance();
  final store = SettingsStore(preferences);
  await handleNotificationAction(store, response);
  if (response.actionId == clockOutNotificationActionId) {
    final settings = store.loadSettings();
    if (settings != null) {
      final notificationService = HaruNotificationService(store);
      await notificationService.initialize(
        requestPermission: false,
        handleLaunchAction: false,
      );
      final now = DateTime.now();
      final active = ScheduleEntryService(store).activeFor(
        now,
        settings.schedule,
      );
      await notificationService.sync(settings, active);
    }
  }
}

Future<void> handleNotificationAction(
  SettingsStore store,
  NotificationResponse response, {
  DateTime? actionTime,
  Future<void> Function(SettingsStore store) widgetRefresher =
      refreshHomeWidgetSnapshot,
}) async {
  if (kIsWeb) return;
  final now = actionTime ?? DateTime.now();
  final payloadDate = _dateFromPayload(response.payload) ?? now;

  switch (response.actionId) {
    case clockOutNotificationActionId:
      await completeCheckout(
        store,
        scheduleDate: payloadDate,
        now: now,
        widgetRefresher: widgetRefresher,
      );
      return;
    case overtimeNotificationActionId:
      // This action opens the app so the user can choose +30m, +1h or a time.
      break;
    case _quickSpendAction:
      final input = response.input?.replaceAll(RegExp(r'[^0-9]'), '');
      final amount = input == null ? null : int.tryParse(input);
      if (amount != null && amount > 0) {
        await DailySpendService(store).add(now, amount);
      }
      break;
  }
  await widgetRefresher(store);
}

Future<ScheduleEntry?> recordCheckout(
  SettingsStore store, {
  required DateTime scheduleDate,
  DateTime? now,
}) async {
  final settings = store.loadSettings();
  if (settings == null) return null;
  final current = now ?? DateTime.now();
  final service = ScheduleEntryService(store);
  final existing = service.entryForDate(scheduleDate);
  final endMinutes = current.hour * 60 +
      current.minute +
      (_sameDay(current, scheduleDate) ? 0 : 24 * 60);
  return service.save(
    ScheduleEntry(
      date: DateTime(scheduleDate.year, scheduleDate.month, scheduleDate.day),
      type: ScheduleEntryType.checkout,
      workStartMinutes: existing?.workStartMinutes ??
          settings.schedule.workStartFor(scheduleDate.weekday),
      workEndMinutes: endMinutes,
      wakeMinutes: existing?.wakeMinutes,
      sleepMinutes: existing?.sleepMinutes,
    ),
  );
}

Future<ScheduleEntry?> completeCheckout(
  SettingsStore store, {
  required DateTime scheduleDate,
  DateTime? now,
  Future<void> Function(SettingsStore store) widgetRefresher =
      refreshHomeWidgetSnapshot,
}) async {
  final entry =
      await recordCheckout(store, scheduleDate: scheduleDate, now: now);
  await widgetRefresher(store);
  return entry;
}

Future<ScheduleEntry?> extendOvertime(
  SettingsStore store, {
  required DateTime scheduleDate,
  required int additionalMinutes,
}) async {
  final settings = store.loadSettings();
  if (settings == null) return null;
  final service = ScheduleEntryService(store);
  final existing = service.entryForDate(scheduleDate);
  final weekday = scheduleDate.weekday;
  final priorEnd =
      existing?.workEndMinutes ?? settings.schedule.workEndFor(weekday);
  return service.save(
    ScheduleEntry(
      date: DateTime(scheduleDate.year, scheduleDate.month, scheduleDate.day),
      type: ScheduleEntryType.overtime,
      workStartMinutes:
          existing?.workStartMinutes ?? settings.schedule.workStartFor(weekday),
      workEndMinutes: priorEnd + additionalMinutes,
      wakeMinutes: existing?.wakeMinutes,
      sleepMinutes: existing?.sleepMinutes,
    ),
  );
}

Future<ScheduleEntry?> setOvertimeEnd(
  SettingsStore store, {
  required DateTime scheduleDate,
  required int workEndMinutes,
}) async {
  final settings = store.loadSettings();
  if (settings == null) return null;
  final service = ScheduleEntryService(store);
  final existing = service.entryForDate(scheduleDate);
  final weekday = scheduleDate.weekday;
  return service.save(
    ScheduleEntry(
      date: DateTime(scheduleDate.year, scheduleDate.month, scheduleDate.day),
      type: ScheduleEntryType.overtime,
      workStartMinutes:
          existing?.workStartMinutes ?? settings.schedule.workStartFor(weekday),
      workEndMinutes: workEndMinutes,
      wakeMinutes: existing?.wakeMinutes,
      sleepMinutes: existing?.sleepMinutes,
    ),
  );
}

class HaruNotificationService extends ChangeNotifier {
  HaruNotificationService(
    this._store, {
    HaruLiveUpdateService? liveUpdateService,
    Future<void> Function(SettingsStore store) widgetRefresher =
        refreshHomeWidgetSnapshot,
  })  : _liveUpdateService = liveUpdateService ?? HaruLiveUpdateService(_store),
        _widgetRefresher = widgetRefresher;

  final SettingsStore _store;
  final HaruLiveUpdateService _liveUpdateService;
  final Future<void> Function(SettingsStore store) _widgetRefresher;
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  var _initialized = false;
  PendingNotificationAction? _pendingAction;

  PendingNotificationAction? consumeAction() {
    final action = _pendingAction;
    _pendingAction = null;
    return action;
  }

  Future<bool> openLiveUpdateSettings() {
    return _liveUpdateService.openPromotionSettings();
  }

  Future<LiveUpdateDiagnostic> liveUpdateDiagnostics() {
    return _liveUpdateService.diagnose();
  }

  Future<bool> openNotificationSettings() {
    return _liveUpdateService.openNotificationSettings();
  }

  Future<bool> openLockScreenNotificationSettings() {
    return _liveUpdateService.openLockScreenSettings();
  }

  Future<bool> requestNotificationPermission() async {
    if (kIsWeb) return false;
    try {
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      if (android == null) return true;
      return await android.requestNotificationsPermission() ?? true;
    } on PlatformException catch (error) {
      debugPrint('Notification permission unavailable: $error');
      return false;
    } on MissingPluginException {
      return false;
    }
  }

  Future<void> initialize({
    bool requestPermission = true,
    bool handleLaunchAction = true,
  }) async {
    if (kIsWeb) return;
    tz_data.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Seoul'));

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    final darwin = DarwinInitializationSettings(
      notificationCategories: [
        DarwinNotificationCategory(
          'haru_work_end',
          actions: [
            DarwinNotificationAction.plain(
              clockOutNotificationActionId,
              '퇴근했어',
            ),
            DarwinNotificationAction.plain(
              overtimeNotificationActionId,
              '야근 중이야',
            ),
          ],
        ),
        DarwinNotificationCategory(
          'haru_spend',
          actions: [
            DarwinNotificationAction.text(
              _quickSpendAction,
              '빠른 지출 입력',
              buttonTitle: '저장',
              placeholder: '금액',
            ),
          ],
        ),
      ],
    );
    try {
      await _plugin.initialize(
        InitializationSettings(
          android: android,
          iOS: darwin,
          macOS: darwin,
        ),
        onDidReceiveNotificationResponse: _handleForegroundResponse,
        onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
      );
      _initialized = true;

      if (requestPermission) {
        await requestNotificationPermission();
      }

      if (handleLaunchAction) {
        final launch = await _plugin.getNotificationAppLaunchDetails();
        final response = launch?.notificationResponse;
        if (launch?.didNotificationLaunchApp == true && response != null) {
          await _handleForegroundResponse(response);
        }
        await consumePendingLiveUpdateAction();
      }
    } on PlatformException catch (error) {
      debugPrint('Notification initialization unavailable: $error');
    }
  }

  Future<void> consumePendingLiveUpdateAction() async {
    final action = await _liveUpdateService.consumeAction();
    if (action == null) return;

    switch (action.type) {
      case LiveUpdateActionType.checkout:
        await completeCheckout(
          _store,
          scheduleDate: action.scheduleDate,
          widgetRefresher: _widgetRefresher,
        );
        break;
      case LiveUpdateActionType.overtime30:
        await extendOvertime(
          _store,
          scheduleDate: action.scheduleDate,
          additionalMinutes: 30,
        );
        await _widgetRefresher(_store);
        break;
      case LiveUpdateActionType.overtime60:
        await extendOvertime(
          _store,
          scheduleDate: action.scheduleDate,
          additionalMinutes: 60,
        );
        await _widgetRefresher(_store);
        break;
      case LiveUpdateActionType.overtimeCustom:
        _pendingAction = PendingNotificationAction(
          type: NotificationQuickAction.overtime,
          date: action.scheduleDate,
        );
        notifyListeners();
        return;
    }

    final settings = _store.loadSettings();
    if (settings != null) {
      final now = DateTime.now();
      final active = ScheduleEntryService(_store).activeFor(
        now,
        settings.schedule,
      );
      await sync(settings, active);
    }
    notifyListeners();
  }

  Future<void> _handleForegroundResponse(NotificationResponse response) async {
    if (response.actionId == overtimeNotificationActionId) {
      _pendingAction = PendingNotificationAction(
        type: NotificationQuickAction.overtime,
        date: _dateFromPayload(response.payload) ?? DateTime.now(),
      );
      notifyListeners();
      return;
    }
    await handleNotificationAction(_store, response);
    notifyListeners();
  }

  Future<void> sync(AppSettings settings, ScheduleEntry? todaySchedule) async {
    if (kIsWeb || !_initialized) return;
    await _liveUpdateService.sync(settings);
    try {
      await _scheduleWorkEnd(settings, todaySchedule);
      await _scheduleSpendReminder(settings.dailyReminderMinutes);
      await _scheduleSleepNotifications(settings);
    } on PlatformException catch (error) {
      debugPrint('Notification scheduling unavailable: $error');
    }
  }

  Future<void> _scheduleWorkEnd(
    AppSettings settings,
    ScheduleEntry? todaySchedule,
  ) async {
    await _plugin.cancel(_workEndNotificationId);
    final now = DateTime.now();
    final plan = const WorkEndPlanner().next(
      now: now,
      profile: settings.schedule,
      todayEntry: todaySchedule,
      entryForDate: ScheduleEntryService(_store).entryForDate,
    );
    if (plan == null) return;

    await _plugin.zonedSchedule(
      _workEndNotificationId,
      '퇴근하셨나요?',
      '퇴근했거나, 오늘만 근무 시간을 늘릴 수 있어요.',
      tz.TZDateTime.from(plan.at, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'haru_work_end',
          '퇴근 알림',
          channelDescription: '퇴근 시간과 야근 여부를 확인합니다.',
          importance: Importance.high,
          priority: Priority.high,
          actions: [
            AndroidNotificationAction(
              clockOutNotificationActionId,
              '퇴근했어',
            ),
            AndroidNotificationAction(
              overtimeNotificationActionId,
              '야근 중이야',
              showsUserInterface: true,
            ),
          ],
        ),
        iOS: DarwinNotificationDetails(categoryIdentifier: 'haru_work_end'),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      payload: 'work_end|${_dateKey(plan.scheduleDate)}',
    );
  }

  Future<void> _scheduleSpendReminder(int reminderMinutes) async {
    await _plugin.cancel(_spendReminderNotificationId);
    final now = DateTime.now();
    var scheduled = DateTime(
      now.year,
      now.month,
      now.day,
      reminderMinutes ~/ 60,
      reminderMinutes % 60,
    );
    if (!scheduled.isAfter(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    await _plugin.zonedSchedule(
      _spendReminderNotificationId,
      '오늘 지출을 확인해 볼까요?',
      '알림에서 바로 금액을 입력할 수 있어요.',
      tz.TZDateTime.from(scheduled, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'haru_spend',
          '지출 확인 알림',
          channelDescription: '매일 정한 시간에 오늘 지출을 확인합니다.',
          importance: Importance.high,
          priority: Priority.high,
          actions: [
            AndroidNotificationAction(
              _quickSpendAction,
              '빠른 지출 입력',
              inputs: [AndroidNotificationActionInput(label: '금액')],
            ),
          ],
        ),
        iOS: DarwinNotificationDetails(categoryIdentifier: 'haru_spend'),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: 'spend',
    );
  }

  Future<void> _scheduleSleepNotifications(AppSettings settings) async {
    await _plugin.cancel(_sleepReminderNotificationId);
    await _plugin.cancel(_wakeNotificationId);
    final plan = const SleepNotificationPlanner().plan(
      now: DateTime.now(),
      settings: settings,
    );

    if (plan.sleepReminderAt != null) {
      await _plugin.zonedSchedule(
        _sleepReminderNotificationId,
        '이제 하루를 천천히 마무리해요',
        '취침 준비 시간이에요.',
        tz.TZDateTime.from(plan.sleepReminderAt!, tz.local),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'haru_sleep',
            '수면 알림',
            channelDescription: '취침 준비와 기상 시간을 알려드립니다.',
            importance: Importance.defaultImportance,
            priority: Priority.defaultPriority,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
        payload: 'sleep_reminder',
      );
    }

    if (plan.wakeAt != null) {
      await _plugin.zonedSchedule(
        _wakeNotificationId,
        '좋은 아침이에요',
        'HARU와 오늘의 여백을 확인해 보세요.',
        tz.TZDateTime.from(plan.wakeAt!, tz.local),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'haru_wake',
            '기상 알림',
            channelDescription: '설정한 기상 시간에 알려드립니다.',
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
        payload: 'wake',
      );
    }
  }
}

DateTime? _dateFromPayload(String? payload) {
  if (payload == null || !payload.startsWith('work_end|')) return null;
  return DateTime.tryParse(payload.substring('work_end|'.length));
}

String _dateKey(DateTime date) => '${date.year.toString().padLeft(4, '0')}-'
    '${date.month.toString().padLeft(2, '0')}-'
    '${date.day.toString().padLeft(2, '0')}';

bool _sameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;
