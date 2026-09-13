import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:haru_app/data/local/settings_store.dart';
import 'package:haru_app/domain/models/app_settings.dart';
import 'package:haru_app/domain/models/budget_profile.dart';
import 'package:haru_app/domain/models/live_update_snapshot.dart';
import 'package:haru_app/domain/models/live_update_diagnostic.dart';
import 'package:haru_app/domain/models/schedule_profile.dart';
import 'package:haru_app/domain/services/live_update_planner.dart';
import 'package:haru_app/services/live_update_service.dart';
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

  test('working live update is generated from TimeEngine output', () {
    final plan = const LiveUpdatePlanner().plan(
      now: DateTime(2026, 9, 11, 12),
      profile: profile,
      activeScheduleFor: (_) => null,
    );

    expect(plan.current.snapshot.visible, isTrue);
    expect(plan.current.snapshot.state, 'working');
    expect(plan.current.snapshot.title, 'DAYVE · 근무 중');
    expect(plan.current.snapshot.headline, '퇴근까지 06:00');
    expect(plan.current.snapshot.remainingMinutes, 360);
    expect(plan.current.snapshot.progress, closeTo(1 / 3, .001));
    expect(plan.current.snapshot.progressPercent, 33);
    expect(plan.current.snapshot.startTime, DateTime(2026, 9, 11, 9));
    expect(plan.current.snapshot.endsAt, DateTime(2026, 9, 11, 18));
    expect(plan.current.snapshot.endLabel, '18:00 퇴근');
    expect(plan.current.snapshot.updatedAt, DateTime(2026, 9, 11, 12));
  });

  test('after-work live update restarts progress toward sleep', () {
    final plan = const LiveUpdatePlanner().plan(
      now: DateTime(2026, 9, 11, 20),
      profile: profile,
      activeScheduleFor: (_) => null,
    );

    expect(plan.current.snapshot.visible, isTrue);
    expect(plan.current.snapshot.state, 'afterWork');
    expect(plan.current.snapshot.title, 'DAYVE · 내 시간');
    expect(plan.current.snapshot.headline, '취침까지 03:00');
    expect(plan.current.snapshot.progressPercent, 40);
    expect(plan.current.snapshot.endLabel, '23:00 취침');
  });

  test('before-work live notification is hidden', () {
    final snapshot = const LiveUpdatePlanner()
        .plan(
          now: DateTime(2026, 9, 11, 8),
          profile: profile,
          activeScheduleFor: (_) => null,
        )
        .current
        .snapshot;

    expect(snapshot.state, 'beforeWork');
    expect(snapshot.visible, isFalse);
  });

  test('day-off live notification is hidden', () {
    final snapshot = const LiveUpdatePlanner()
        .plan(
          now: DateTime(2026, 9, 12, 12),
          profile: profile,
          activeScheduleFor: (_) => null,
        )
        .current
        .snapshot;

    expect(snapshot.state, 'dayOff');
    expect(snapshot.visible, isFalse);
  });

  test('sleep-window live notification is hidden', () {
    final snapshot = const LiveUpdatePlanner()
        .plan(
          now: DateTime(2026, 9, 11, 6),
          profile: profile,
          activeScheduleFor: (_) => null,
        )
        .current
        .snapshot;

    expect(snapshot.state, 'sleepWindow');
    expect(snapshot.visible, isFalse);
  });

  test('state transition plan shows work then after-work and finally hides',
      () {
    final plan = const LiveUpdatePlanner().plan(
      now: DateTime(2026, 9, 11, 8),
      profile: profile,
      activeScheduleFor: (_) => null,
    );

    expect(plan.current.snapshot.visible, isFalse);
    final workStart = plan.transitions.firstWhere(
      (command) => command.executeAt == DateTime(2026, 9, 11, 9),
    );
    final checkout = plan.transitions.firstWhere(
      (command) => command.executeAt == DateTime(2026, 9, 11, 18),
    );
    final sleep = plan.transitions.firstWhere(
      (command) => command.executeAt == DateTime(2026, 9, 11, 23),
    );
    expect(workStart.snapshot.state, 'working');
    expect(workStart.snapshot.visible, isTrue);
    expect(checkout.snapshot.state, 'afterWork');
    expect(checkout.snapshot.showCheckoutActions, isTrue);
    expect(checkout.snapshot.scheduleDate, DateTime(2026, 9, 11));
    expect(sleep.snapshot.visible, isFalse);
  });

  test('progress uses three battery-friendly milestone refreshes per segment',
      () {
    final plan = const LiveUpdatePlanner().plan(
      now: DateTime(2026, 9, 11, 9),
      profile: profile,
      activeScheduleFor: (_) => null,
    );
    final workProgress = plan.transitions
        .where((command) => command.snapshot.state == 'working')
        .map((command) => command.snapshot.progressPercent)
        .toList();

    expect(workProgress, containsAllInOrder([25, 50, 75]));
  });

  test('standard working notification has expanded display data', () async {
    final platform = _FakeLiveUpdatePlatform(
      const LiveUpdatePlatformResult(
        delivery: LiveUpdateDelivery.standard,
        androidApi: 35,
        canPromote: false,
      ),
    );
    final result = await _syncWith(platform, DateTime(2026, 9, 11, 12));

    expect(result.delivery, LiveUpdateDelivery.standard);
    expect(result.canPromote, isFalse);
    expect(platform.lastPlan?.current.snapshot.state, 'working');
    expect(platform.lastPlan?.current.snapshot.stateLabel, '근무 중');
    expect(
      platform.lastPlan?.current.snapshot.progressLeadingLabel,
      '오전은 수고했어요',
    );
    expect(
      platform.lastPlan?.current.snapshot.progressTrailingLabel,
      '퇴근까지 06:00',
    );
  });

  test('standard afterWork notification has expanded display data', () async {
    final platform = _FakeLiveUpdatePlatform(
      const LiveUpdatePlatformResult(
        delivery: LiveUpdateDelivery.standard,
        androidApi: 35,
        canPromote: false,
      ),
    );
    final result = await _syncWith(platform, DateTime(2026, 9, 11, 19));

    expect(result.delivery, LiveUpdateDelivery.standard);
    expect(platform.lastPlan?.current.snapshot.state, 'afterWork');
    expect(platform.lastPlan?.current.snapshot.visible, isTrue);
    expect(platform.lastPlan?.current.snapshot.stateLabel, '내 시간');
    expect(
      platform.lastPlan?.current.snapshot.progressLeadingLabel,
      '오늘도 수고했어요',
    );
    expect(
      platform.lastPlan?.current.snapshot.progressTrailingLabel,
      '내 시간 보내는 중',
    );
  });

  test('saved Flutter plan restores after an app or device restart', () {
    final original = const LiveUpdatePlanner().plan(
      now: DateTime(2026, 9, 11, 12),
      profile: profile,
      activeScheduleFor: (_) => null,
    );
    final restored = LiveUpdatePlan.fromMap(original.toMap());

    expect(restored.current.snapshot.state, original.current.snapshot.state);
    expect(
      restored.current.snapshot.progressPercent,
      original.current.snapshot.progressPercent,
    );
    expect(restored.transitions.length, original.transitions.length);
    expect(restored.transitions.first.executeAt,
        original.transitions.first.executeAt);
  });

  test('notification permission denial reports unsupported without throwing',
      () async {
    final platform = _FakeLiveUpdatePlatform(
      const LiveUpdatePlatformResult(
        delivery: LiveUpdateDelivery.unsupported,
        androidApi: 36,
        canPromote: false,
      ),
    );

    final result = await _syncWith(platform, DateTime(2026, 9, 11, 12));

    expect(result.delivery, LiveUpdateDelivery.unsupported);
    expect(platform.lastPlan, isNotNull);
  });

  test('money stays hidden by default and is included only after opt-in',
      () async {
    final hiddenPlatform = _FakeLiveUpdatePlatform(
      const LiveUpdatePlatformResult(
        delivery: LiveUpdateDelivery.standard,
        androidApi: 35,
        canPromote: false,
      ),
    );
    await _syncWith(hiddenPlatform, DateTime(2026, 9, 11, 12));
    expect(hiddenPlatform.lastPlan?.current.snapshot.showMoney, isFalse);
    expect(hiddenPlatform.lastPlan?.current.snapshot.todaySpendable, isEmpty);
    expect(hiddenPlatform.lastPlan?.current.snapshot.todayBudgetLabel, isEmpty);

    final visiblePlatform = _FakeLiveUpdatePlatform(hiddenPlatform.result);
    await _syncWith(
      visiblePlatform,
      DateTime(2026, 9, 11, 12),
      showMoney: true,
    );
    expect(visiblePlatform.lastPlan?.current.snapshot.showMoney, isTrue);
    expect(
        visiblePlatform.lastPlan?.current.snapshot.todaySpendable, '30,000원');
    expect(visiblePlatform.lastPlan?.current.snapshot.monthlyRemaining,
        '600,000원');
    expect(visiblePlatform.lastPlan?.current.snapshot.monthlySpent, '0원');
    expect(
      visiblePlatform.lastPlan?.current.snapshot.todayBudgetLabel,
      contains('오늘'),
    );
    expect(
      visiblePlatform.lastPlan?.current.snapshot.remainingBudgetLabel,
      contains('이번 달'),
    );
  });

  test('custom notification layout data survives snapshot parsing', () {
    final snapshot = LiveUpdateSnapshot.fromMap({
      'visible': true,
      'state': 'working',
      'title': 'DAYVE · 근무 중',
      'headline': '퇴근까지 01:19',
      'progress': .9,
      'progressPercent': 90,
      'remainingMinutes': 79,
      'startTimeMillis': DateTime(2026, 9, 11, 9).millisecondsSinceEpoch,
      'endTimeMillis': DateTime(2026, 9, 11, 18).millisecondsSinceEpoch,
      'updatedAtMillis': DateTime(2026, 9, 11, 16, 41).millisecondsSinceEpoch,
      'showMoney': true,
      'stateLabel': '근무 중',
      'progressLeadingLabel': '오전은 수고했어요',
      'progressTrailingLabel': '퇴근까지 01:19',
      'endLabel': '18:00 퇴근',
      'todaySpendable': '31,578원',
      'monthlyRemaining': '600,000원',
      'monthlySpent': '0원',
    });
    final restored = LiveUpdateSnapshot.fromMap(snapshot.toMap());

    expect(restored.progressPercent, 90);
    expect(restored.stateLabel, '근무 중');
    expect(restored.endLabel, '18:00 퇴근');
    expect(restored.todaySpendable, '31,578원');
    expect(restored.monthlyRemaining, '600,000원');
    expect(restored.monthlySpent, '0원');
  });

  test('standard expanded notification excludes budget content', () {
    final layout = File(
      'android/app/src/main/res/layout/haru_notification_expanded.xml',
    ).readAsStringSync();

    expect(layout, contains('notification_expanded_progress'));
    expect(layout, contains('notification_expanded_end'));
    expect(layout, isNot(contains('notification_money_section')));
    expect(layout, isNot(contains('notification_today_spendable')));
  });

  test('promoted renderer remains ProgressStyle without custom views', () {
    final manager = File(
      'android/app/src/main/kotlin/com/haruapp/haru_app/'
      'HaruLiveUpdateManager.kt',
    ).readAsStringSync();

    expect(manager, contains('Notification.ProgressStyle()'));
    expect(
      manager,
      matches(
        RegExp(
          r'requestPromotion = true,\s+useCustomViews = false',
        ),
      ),
    );
    expect(
      manager,
      matches(
        RegExp(
          r'requestPromotion = false,\s+useCustomViews = true',
        ),
      ),
    );
  });
}

Future<LiveUpdatePlatformResult> _syncWith(
  _FakeLiveUpdatePlatform platform,
  DateTime now, {
  bool showMoney = false,
}) async {
  SharedPreferences.setMockInitialValues({});
  final preferences = await SharedPreferences.getInstance();
  final store = SettingsStore(preferences);
  final settings = AppSettings(
    schedule: const ScheduleProfile(
      workStartMinutes: 9 * 60,
      workEndMinutes: 18 * 60,
      wakeMinutes: 7 * 60,
      sleepMinutes: 23 * 60,
      workingWeekdays: {1, 2, 3, 4, 5},
    ),
    budget: const BudgetProfile(cycleBudget: 600000, cycleStartDay: 1),
    dailyReminderMinutes: 21 * 60,
    lockScreenLiveEnabled: true,
    lockScreenMoneyVisible: showMoney,
  );
  await store.saveSettings(settings);
  return HaruLiveUpdateService(store, platform: platform).sync(
    settings,
    now: now,
  );
}

class _FakeLiveUpdatePlatform implements LiveUpdatePlatform {
  _FakeLiveUpdatePlatform(this.result);

  final LiveUpdatePlatformResult result;
  LiveUpdatePlan? lastPlan;

  @override
  Future<LiveUpdatePlatformResult> disable() async =>
      const LiveUpdatePlatformResult(
        delivery: LiveUpdateDelivery.hidden,
        androidApi: 35,
        canPromote: false,
      );

  @override
  Future<LiveUpdatePlatformResult> sync(LiveUpdatePlan plan) async {
    lastPlan = plan;
    return result;
  }

  @override
  Future<bool> openPromotionSettings() async => false;

  @override
  Future<LiveUpdateAction?> consumeAction() async => null;

  @override
  Future<LiveUpdateDiagnostic> diagnose() async =>
      LiveUpdateDiagnostic.unsupported();

  @override
  Future<bool> openNotificationSettings() async => false;

  @override
  Future<bool> openLockScreenSettings() async => false;
}
