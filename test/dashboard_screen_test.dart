import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:haru_app/app.dart';
import 'package:haru_app/data/local/settings_store.dart';
import 'package:haru_app/domain/models/app_settings.dart';
import 'package:haru_app/domain/models/budget_profile.dart';
import 'package:haru_app/domain/models/schedule_entry.dart';
import 'package:haru_app/domain/models/schedule_profile.dart';
import 'package:haru_app/presentation/haru_sheets.dart';
import 'package:haru_app/domain/services/schedule_entry_service.dart';
import 'package:haru_app/services/home_widget_service.dart';
import 'package:haru_app/services/notification_service.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await initializeDateFormatting('ko_KR');
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('dashboard switches between today and spending tabs',
      (tester) async {
    await _pumpDashboard(tester, now: DateTime(2026, 9, 11, 12));

    expect(find.byKey(const Key('today_tab')), findsOneWidget);
    expect(find.text('오늘의 여백'), findsOneWidget);
    expect(find.byKey(const Key('dashboard_time_area')), findsOneWidget);
    expect(find.text('오늘 써도 되는 돈'), findsOneWidget);

    await tester.tap(find.byKey(const Key('spending_tab_destination')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('spending_tab')), findsOneWidget);
    expect(find.text('소비'), findsWidgets);
    expect(find.text('이번 달 남은 생활비'), findsOneWidget);
    expect(find.text('날짜별 지출 내역'), findsOneWidget);
  });

  testWidgets('spending tab shows payday totals and budget settings',
      (tester) async {
    await _pumpDashboard(tester, now: DateTime(2026, 9, 11, 12));
    await tester.tap(find.byKey(const Key('spending_tab_destination')));
    await tester.pumpAndSettle();

    expect(find.text('누적 사용'), findsOneWidget);
    expect(find.text('월급날'), findsOneWidget);
    expect(find.text('매달 1일'), findsOneWidget);
    expect(find.byKey(const Key('open_budget_settings')), findsOneWidget);
    await tester.tap(find.byKey(const Key('open_budget_settings')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('budget_settings_sheet')), findsOneWidget);
  });

  testWidgets('top settings button opens settings without becoming a tab',
      (tester) async {
    await _pumpDashboard(tester);

    expect(find.byKey(const Key('open_settings')), findsOneWidget);
    expect(find.byTooltip('설정'), findsOneWidget);
    expect(find.text('설정', skipOffstage: false), findsNothing);
    await tester.tap(find.byKey(const Key('open_settings')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('schedule_settings_sheet')), findsOneWidget);
    expect(find.text('설정'), findsOneWidget);
    expect(find.text('알림 및 잠금화면'), findsOneWidget);
    expect(find.text('Live Update 진단'), findsOneWidget);
  });

  testWidgets('first lock screen enable shows guidance and requests permission',
      (tester) async {
    final harness = await _pumpDashboard(tester);
    await tester.tap(find.byKey(const Key('open_settings')));
    await tester.pumpAndSettle();

    final toggle = find.byKey(const Key('lock_screen_live_toggle'));
    await tester.scrollUntilVisible(
      toggle,
      180,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(toggle);
    await tester.pumpAndSettle();

    expect(find.text('잠금화면에서도 DAYVE를 볼까요?'), findsOneWidget);
    expect(find.text('사용하기'), findsOneWidget);
    await tester.tap(find.byKey(const Key('enable_lock_screen_live')));
    await tester.pumpAndSettle();

    final restored = harness.store.loadSettings()!;
    expect(restored.lockScreenLiveEnabled, isTrue);
    expect(restored.lockScreenLiveIntroSeen, isTrue);
    expect(harness.notification.permissionRequestCount, 1);
    expect(harness.notification.syncCount, greaterThan(0));
  });

  testWidgets('tab changes do not reschedule widget or notifications',
      (tester) async {
    final harness = await _pumpDashboard(tester);
    await tester.pumpAndSettle();
    final widgetRefreshes = harness.homeWidget.refreshCount;
    final notificationSyncs = harness.notification.syncCount;

    await tester.tap(find.byKey(const Key('spending_tab_destination')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('today_tab_destination')));
    await tester.pumpAndSettle();

    expect(harness.homeWidget.refreshCount, widgetRefreshes);
    expect(harness.notification.syncCount, notificationSyncs);
  });

  testWidgets('onboarding explicitly shows initial sleep and wake settings',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: OnboardingScreen(onComplete: (_) async {})),
    );
    await tester.tap(find.text('다음'));
    await tester.pumpAndSettle();

    expect(find.text('취침 시간'), findsOneWidget);
    expect(find.text('23:30'), findsOneWidget);
    expect(find.text('기상 시간'), findsOneWidget);
    expect(find.text('07:00'), findsOneWidget);
    expect(find.text('취침 준비 알림'), findsOneWidget);
    await tester.drag(find.byType(ListView), const Offset(0, -300));
    await tester.pumpAndSettle();
    expect(find.text('기상 알림'), findsOneWidget);
  });

  testWidgets('small screen schedule sheet scrolls without overflow',
      (tester) async {
    tester.view.physicalSize = const Size(320, 480);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await _pumpDashboard(tester);
    expect(find.text('오늘의 여백'), findsOneWidget);
    expect(find.byKey(const Key('dashboard_time_area')), findsOneWidget);
    expect(find.byKey(const Key('dashboard_money_area')), findsOneWidget);
    await tester.tap(find.byTooltip('설정').first);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('schedule_settings_sheet')), findsOneWidget);
    expect(find.text('요일별 기본 일정'), findsOneWidget);
    expect(find.text('오늘만 변경'), findsOneWidget);
    expect(find.text('오늘 휴무 처리'), findsOneWidget);
    expect(find.text('날짜 선택'), findsNothing);
    expect(find.text('휴대폰 Calendar에 추가'), findsNothing);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('오늘만 변경'));
    await tester.pumpAndSettle();

    expect(find.text('오늘 출근 시간'), findsOneWidget);
    expect(find.text('24시간제 · 5분 단위'), findsOneWidget);
    expect(find.text('시간'), findsOneWidget);
    expect(find.text('분'), findsOneWidget);
    expect(find.byType(CupertinoPicker), findsNWidgets(2));
    expect(find.byKey(const Key('haru_wheel_selection')), findsNWidgets(2));
    final selectedHour = find.descendant(
      of: find.byKey(const Key('haru_time_hour')),
      matching: find.text('09'),
    );
    expect(selectedHour, findsOneWidget);
    expect(
      (tester.getCenter(selectedHour).dy -
              tester.getCenter(find.byKey(const Key('haru_time_hour'))).dy)
          .abs(),
      lessThan(3),
    );
    expect(find.byType(DropdownButton<int>), findsNothing);
    expect(find.text('취소'), findsOneWidget);
    expect(find.text('적용'), findsOneWidget);
    expect(find.text('Cancel'), findsNothing);
    expect(find.text('OK'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('spend sheet uses a compact keypad without system keyboard',
      (tester) async {
    tester.view.physicalSize = const Size(320, 560);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await _pumpDashboard(tester);
    await tester.tap(find.byKey(const Key('open_spend_sheet')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('spend_amount_field')), findsOneWidget);
    expect(
      tester
          .widget<TextField>(find.byKey(const Key('spend_amount_field')))
          .readOnly,
      isTrue,
    );
    expect(find.byKey(const Key('spend_key_0')), findsOneWidget);
    expect(find.byKey(const Key('spend_key_9')), findsOneWidget);
    expect(find.byKey(const Key('spend_backspace')), findsOneWidget);
    expect(find.text('+1만원'), findsOneWidget);
    expect(find.text('+3만원'), findsOneWidget);
    expect(find.text('+5만원'), findsOneWidget);
    expect(find.text('초기화'), findsOneWidget);
    expect(find.text('취소'), findsOneWidget);
    expect(find.text('저장'), findsOneWidget);
    expect(
      tester.getSize(find.byKey(const Key('spend_sheet_scroll'))).height,
      lessThan(300),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('custom keypad handles digits quick amounts and backspace',
      (tester) async {
    await _pumpDashboard(tester);
    await tester.tap(find.byKey(const Key('open_spend_sheet')));
    await tester.pumpAndSettle();
    final field = find.byKey(const Key('spend_amount_field'));

    await tester.tap(find.byKey(const Key('spend_key_1')));
    await tester.tap(find.byKey(const Key('spend_key_2')));
    await tester.tap(find.byKey(const Key('spend_key_3')));
    await tester.tap(find.byKey(const Key('spend_backspace')));
    expect(tester.widget<TextField>(field).controller!.text, '12');

    await tester.tap(find.byKey(const Key('spend_clear')));
    await tester.tap(find.byKey(const Key('spend_quick_10000')));
    await tester.tap(find.byKey(const Key('spend_quick_30000')));
    await tester.tap(find.byKey(const Key('spend_quick_50000')));
    expect(tester.widget<TextField>(field).controller!.text, '90000');
  });

  testWidgets('working dashboard shows its progress gauge', (tester) async {
    await _pumpDashboard(tester, now: DateTime(2026, 9, 11, 12));

    expect(find.byKey(const Key('pixel_cat_progress_track')), findsOneWidget);
    expect(find.text('근무 진행'), findsOneWidget);
    expect(find.byKey(const Key('haru_pixel_pet')), findsOneWidget);
  });

  testWidgets('after-work dashboard shows a restarted progress gauge',
      (tester) async {
    await _pumpDashboard(tester, now: DateTime(2026, 9, 11, 20, 30));

    expect(find.byKey(const Key('pixel_cat_progress_track')), findsOneWidget);
    expect(find.text('자유시간 진행'), findsOneWidget);
    expect(find.text('50%'), findsOneWidget);
  });

  testWidgets('day-off dashboard hides the progress gauge', (tester) async {
    await _pumpDashboard(tester, now: DateTime(2026, 9, 12, 12));

    expect(find.byKey(const Key('pixel_cat_progress_track')), findsNothing);
    expect(find.byKey(const Key('haru_pixel_pet')), findsNothing);
  });

  testWidgets('weekday settings can turn Saturday into a workday',
      (tester) async {
    final harness = await _pumpDashboard(
      tester,
      now: DateTime(2026, 9, 12, 12),
    );

    await tester.tap(find.byTooltip('설정').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('요일별 기본 일정').last);
    await tester.pumpAndSettle();

    final saturday = find.byKey(const Key('weekday_schedule_6'));
    expect(saturday, findsOneWidget);
    final saturdaySwitch = find.descendant(
      of: saturday,
      matching: find.byType(Switch),
    );
    expect(tester.widget<Switch>(saturdaySwitch).value, isFalse);
    await tester.drag(
      find.byKey(const Key('weekday_schedule_sheet')),
      const Offset(0, -240),
    );
    await tester.pumpAndSettle();
    await tester.tap(saturdaySwitch);
    await tester.pumpAndSettle();

    expect(tester.widget<Switch>(saturdaySwitch).value, isTrue);
    expect(
      harness.store.loadSettings()!.schedule.isWorkingDay(DateTime.saturday),
      isTrue,
    );
  });

  testWidgets('overtime notification opens duration choices and refreshes',
      (tester) async {
    final harness = await _pumpDashboard(
      tester,
      now: DateTime(2026, 9, 11, 18),
    );
    final widgetRefreshes = harness.homeWidget.refreshCount;
    final notificationSyncs = harness.notification.syncCount;

    harness.notification.pushOvertime(DateTime(2026, 9, 11));
    await tester.pumpAndSettle();

    expect(find.text('+30분'), findsOneWidget);
    expect(find.text('+1시간'), findsOneWidget);
    expect(find.text('직접 설정'), findsOneWidget);
    await tester.tap(find.text('+30분'));
    await tester.pumpAndSettle();

    expect(
      ScheduleEntryService(harness.store)
          .entryForDate(DateTime(2026, 9, 11))
          ?.workEndMinutes,
      18 * 60 + 30,
    );
    expect(harness.homeWidget.refreshCount, widgetRefreshes + 1);
    expect(harness.notification.syncCount, notificationSyncs + 1);
  });

  testWidgets('sleep time change immediately refreshes dashboard and widget',
      (tester) async {
    final harness = await _pumpDashboard(
      tester,
      now: DateTime(2026, 9, 11, 20),
    );
    final widgetRefreshes = harness.homeWidget.refreshCount;
    final notificationSyncs = harness.notification.syncCount;
    expect(find.text('03시간 00분'), findsOneWidget);

    await tester.tap(find.byTooltip('설정').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('수면 및 알림').last);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('sleep_settings_sheet')), findsOneWidget);
    await tester.tap(find.byKey(const Key('sleep_time_setting')));
    await tester.pumpAndSettle();
    await tester.drag(
      find.byKey(const Key('haru_time_minute')),
      const Offset(0, -52),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('적용'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('save_sleep_settings')));
    await tester.pumpAndSettle();

    expect(find.text('03시간 05분'), findsOneWidget);
    expect(harness.store.loadSettings()!.schedule.sleepMinutes, 23 * 60 + 5);
    expect(harness.homeWidget.refreshCount, widgetRefreshes + 1);
    expect(harness.notification.syncCount, notificationSyncs + 1);
  });

  testWidgets('budget settings show payday amount and next reset date',
      (tester) async {
    await _pumpDashboard(
      tester,
      now: DateTime(2026, 9, 30, 12),
    );

    await tester.tap(find.byTooltip('설정').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('생활비 설정').last);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('budget_settings_sheet')), findsOneWidget);
    expect(find.text('매달 1일'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const Key('cycle_budget_setting')),
        matching: find.text('600,000원'),
      ),
      findsOneWidget,
    );
    expect(find.text('다음 초기화 날짜'), findsOneWidget);
    expect(find.text('2026년 10월 1일'), findsOneWidget);
  });

  testWidgets('scheduled work on a default day off shows the gauge',
      (tester) async {
    final now = DateTime(2026, 9, 12, 12);
    await _pumpDashboard(
      tester,
      now: now,
      scheduleEntry: ScheduleEntry(
        date: now,
        type: ScheduleEntryType.work,
        workStartMinutes: 9 * 60,
        workEndMinutes: 18 * 60,
      ),
    );

    expect(find.text('DAYVE · 근무 중'), findsOneWidget);
    expect(find.byKey(const Key('dayve_pixel_cat')), findsOneWidget);
  });

  testWidgets('override save refreshes dashboard, widget and live update sync',
      (tester) async {
    final harness = await _pumpDashboard(
      tester,
      now: DateTime(2026, 9, 11, 12),
    );
    final widgetRefreshes = harness.homeWidget.refreshCount;
    final notificationSyncs = harness.notification.syncCount;

    await tester.tap(find.byTooltip('설정').first);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('오늘 휴무 처리'));
    await tester.tap(find.text('오늘 휴무 처리'));
    await tester.pumpAndSettle();

    expect(find.text('DAYVE · 휴무'), findsOneWidget);
    expect(find.byKey(const Key('dayve_pixel_cat')), findsNothing);
    expect(harness.homeWidget.refreshCount, widgetRefreshes + 1);
    expect(harness.notification.syncCount, notificationSyncs + 1);
    expect(harness.notification.lastOverride?.isDayOff, isTrue);
  });

  testWidgets('spend save refreshes widget and live update simultaneously',
      (tester) async {
    final harness = await _pumpDashboard(
      tester,
      now: DateTime(2026, 9, 11, 12),
    );
    final widgetRefreshes = harness.homeWidget.refreshCount;
    final notificationSyncs = harness.notification.syncCount;

    await tester.tap(find.byKey(const Key('spending_tab_destination')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('spending_tab_add_spend')));
    await tester.pumpAndSettle();
    for (final digit in [1, 2, 0, 0, 0]) {
      await tester.tap(find.byKey(Key('spend_key_$digit')));
    }
    await tester.tap(find.byKey(const Key('spend_confirm')));
    await tester.pumpAndSettle();

    expect(find.text('12,000원'), findsWidgets);
    expect(find.text('9월 11일 금요일'), findsOneWidget);
    expect(harness.homeWidget.refreshCount, widgetRefreshes + 1);
    expect(harness.notification.syncCount, notificationSyncs + 1);
    expect(harness.homeWidget.lastRefreshAt, DateTime(2026, 9, 11, 12));
  });

  testWidgets('time wheels apply a 24-hour value in five-minute steps',
      (tester) async {
    TimeOfDay? selected;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              selected = await showHaruTimePicker(
                context: context,
                initialTime: const TimeOfDay(hour: 18, minute: 0),
                title: '퇴근 시간',
              );
            },
            child: const Text('시간 열기'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('시간 열기'));
    await tester.pumpAndSettle();
    await tester.drag(
      find.byKey(const Key('haru_time_minute')),
      const Offset(0, -52),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('적용'));
    await tester.pumpAndSettle();

    expect(selected, isNotNull);
    expect(selected!.hour, 18);
    expect(selected!.minute, 5);
    expect(selected!.minute % 5, 0);
  });

  testWidgets('queued listeners do not use context after dashboard disposal',
      (tester) async {
    final harness = await _pumpDashboard(tester);
    harness.homeWidget.push(WidgetQuickAction.schedule);

    await tester.pumpWidget(const MaterialApp(home: SizedBox.shrink()));
    harness.notification.emit();
    harness.homeWidget.emit();
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });
}

Future<_DashboardHarness> _pumpDashboard(
  WidgetTester tester, {
  DateTime? now,
  ScheduleEntry? scheduleEntry,
}) async {
  final preferences = await SharedPreferences.getInstance();
  final store = SettingsStore(preferences);
  if (scheduleEntry != null) {
    await ScheduleEntryService(store).save(scheduleEntry);
  }
  const settings = AppSettings(
    schedule: ScheduleProfile(
      workStartMinutes: 9 * 60,
      workEndMinutes: 18 * 60,
      wakeMinutes: 7 * 60,
      sleepMinutes: 23 * 60,
      workingWeekdays: {1, 2, 3, 4, 5},
    ),
    budget: BudgetProfile(cycleBudget: 600000, cycleStartDay: 1),
    dailyReminderMinutes: 21 * 60,
  );
  final notification = _FakeNotificationService(store);
  final homeWidget = _FakeHomeWidgetService(store);
  await store.saveSettings(settings);

  await tester.pumpWidget(
    MaterialApp(
      home: DashboardScreen(
        settings: settings,
        settingsStore: store,
        notificationService: notification,
        homeWidgetService: homeWidget,
        nowProvider: now == null ? DateTime.now : () => now,
      ),
    ),
  );
  await tester.pump();
  return _DashboardHarness(notification, homeWidget, store);
}

class _DashboardHarness {
  const _DashboardHarness(this.notification, this.homeWidget, this.store);

  final _FakeNotificationService notification;
  final _FakeHomeWidgetService homeWidget;
  final SettingsStore store;
}

class _FakeNotificationService extends HaruNotificationService {
  _FakeNotificationService(super.store);

  int syncCount = 0;
  int permissionRequestCount = 0;
  ScheduleEntry? lastOverride;
  PendingNotificationAction? _nextAction;

  @override
  Future<void> sync(AppSettings settings, ScheduleEntry? todayOverride) async {
    syncCount += 1;
    lastOverride = todayOverride;
  }

  @override
  Future<bool> requestNotificationPermission() async {
    permissionRequestCount += 1;
    return true;
  }

  void emit() => notifyListeners();

  @override
  PendingNotificationAction? consumeAction() {
    final action = _nextAction;
    _nextAction = null;
    return action;
  }

  void pushOvertime(DateTime date) {
    _nextAction = PendingNotificationAction(
      type: NotificationQuickAction.overtime,
      date: date,
    );
    notifyListeners();
  }
}

class _FakeHomeWidgetService extends HaruHomeWidgetService {
  _FakeHomeWidgetService(super.store);

  WidgetQuickAction? _nextAction;
  int refreshCount = 0;
  DateTime? lastRefreshAt;

  @override
  Future<void> refresh({DateTime? now}) async {
    refreshCount += 1;
    lastRefreshAt = now;
  }

  @override
  WidgetQuickAction? consumeAction() {
    final action = _nextAction;
    _nextAction = null;
    return action;
  }

  void push(WidgetQuickAction action) {
    _nextAction = action;
    notifyListeners();
  }

  void emit() => notifyListeners();
}
