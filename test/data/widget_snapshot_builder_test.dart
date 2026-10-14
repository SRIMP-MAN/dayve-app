import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:haru_app/domain/models/budget_summary.dart';
import 'package:haru_app/domain/models/time_summary.dart';
import 'package:haru_app/domain/models/widget_snapshot.dart';
import 'package:haru_app/domain/services/widget_snapshot_builder.dart';

void main() {
  const builder = WidgetSnapshotBuilder();
  const budget = BudgetSummary(
    cycleBudget: 600000,
    spentAmount: 100000,
    remainingBudget: 500000,
    remainingDays: 20,
  );

  test('working snapshot displays time until clock-out', () {
    final now = DateTime(2026, 9, 14, 16);
    final snapshot = builder.build(
      now: now,
      validUntil: DateTime(2026, 9, 14, 18),
      time: TimeSummary(
        state: HaruDayState.working,
        nextEventAt: DateTime(2026, 9, 14, 18),
        remaining: const Duration(hours: 2),
        progress: 0.75,
      ),
      budget: budget,
    );

    expect(snapshot.state, 'working');
    expect(snapshot.stateLabel, 'DAYVE · 근무 중');
    expect(snapshot.headline, '퇴근까지 2시간');
    expect(snapshot.remainingMinutes, 120);
    expect(snapshot.progress, .75);
    expect(snapshot.progressPercent, 75);
    expect(snapshot.progressLeadingLabel, '오전은 수고했어요');
    expect(snapshot.progressTrailingLabel, '퇴근 18:00');
    expect(snapshot.remainingBudgetAmount, 500000);
    expect(snapshot.monthlyBudgetAmount, 600000);
    expect(snapshot.monthlySpentAmount, 100000);
    expect(snapshot.monthlyUsagePercent, 17);
    expect(snapshot.monthlyUsageLabel, '이번 달 17% 사용 중');
    expect(snapshot.toJson()['workStatus'], 'working');
    expect(snapshot.toJson()['remainingWorkTime'], '퇴근까지 2시간');
    expect(snapshot.toJson()['workProgress'], .75);
    expect(snapshot.toJson()['workEndTime'], '퇴근 18:00');
    expect(snapshot.toJson()['monthlyBudget'], 600000);
    expect(snapshot.toJson()['monthlySpent'], 100000);
    expect(snapshot.toJson()['monthlyRemaining'], 500000);
    expect(snapshot.toJson()['lastUpdatedAt'], now.toIso8601String());
    expect(snapshot.toJson(), isNot(contains('budgetAmount')));
    expect(snapshot.toJson(), isNot(contains('budgetAmountLabel')));
  });

  test('morning working snapshot uses morning progress copy', () {
    final now = DateTime(2026, 9, 16, 10, 14);
    final snapshot = builder.build(
      now: now,
      validUntil: DateTime(2026, 9, 16, 18),
      time: TimeSummary(
        state: HaruDayState.working,
        nextEventAt: DateTime(2026, 9, 16, 18),
        remaining: const Duration(hours: 7, minutes: 46),
        progress: .14,
      ),
      budget: budget,
    );

    expect(snapshot.progressLeadingLabel, '좋은 아침이에요');
  });

  test('after-work snapshot displays remaining free time', () {
    final snapshot = builder.build(
      now: DateTime(2026, 9, 14, 20),
      validUntil: DateTime(2026, 9, 14, 23, 30),
      time: TimeSummary(
        state: HaruDayState.afterWork,
        nextEventAt: DateTime(2026, 9, 14, 23, 30),
        remaining: const Duration(hours: 3, minutes: 30),
        progress: 0.4,
      ),
      budget: budget,
    );

    expect(snapshot.stateLabel, 'DAYVE · 자유시간');
    expect(snapshot.headline, '취침까지 3시간 30분');
    expect(snapshot.progress, .4);
    expect(snapshot.progressTrailingLabel, '취침 23:30');
  });

  test('day-off snapshot has a stable headline', () {
    final snapshot = builder.build(
      now: DateTime(2026, 9, 14, 12),
      validUntil: DateTime(2026, 9, 15),
      time: TimeSummary(
        state: HaruDayState.dayOff,
        nextEventAt: DateTime(2026, 9, 15),
        remaining: const Duration(hours: 12),
        progress: 0,
      ),
      budget: budget,
    );

    expect(snapshot.state, 'dayOff');
    expect(snapshot.stateLabel, 'DAYVE · 휴무');
    expect(snapshot.headline, '오늘은 쉬는 날');
  });

  test('snapshot JSON round-trip preserves display and numeric fields', () {
    final original = builder.build(
      now: DateTime(2026, 9, 14, 12),
      validUntil: DateTime(2026, 9, 14, 18),
      time: TimeSummary(
        state: HaruDayState.working,
        nextEventAt: DateTime(2026, 9, 14, 18),
        remaining: const Duration(hours: 6),
        progress: 0.5,
      ),
      budget: budget,
    );

    final restored = WidgetSnapshot.decode(original.encode());

    expect(restored.headline, original.headline);
    expect(restored.remainingBudgetLabel, original.remainingBudgetLabel);
    expect(restored.updatedAt, original.updatedAt);
    expect(restored.updatedLabel, '9/14 12:00 갱신');
    expect(restored.snapshotDate, '2026-09-14');
    expect(restored.validUntil, DateTime(2026, 9, 14, 18));
    expect(restored.progress, .5);
    expect(restored.progressPercent, 50);
    expect(restored.monthlyBudgetLabel, '600,000원');
    expect(restored.monthlySpentLabel, '100,000원');
    expect(restored.remainingBudgetLabel, '500,000원');
  });

  test('medium and large widgets share DAYVE continuous gauge language', () {
    final medium = File(
      'android/app/src/main/res/layout/haru_widget_medium.xml',
    ).readAsStringSync();
    final large = File(
      'android/app/src/main/res/layout/haru_widget_large.xml',
    ).readAsStringSync();
    final provider = File(
      'android/app/src/main/kotlin/com/dayve/app/'
      'HaruWidgetProvider.kt',
    ).readAsStringSync();
    final widgetInfo = File(
      'android/app/src/main/res/xml/haru_widget_info.xml',
    ).readAsStringSync();

    for (final layout in [medium, large]) {
      expect(layout, contains('오늘의 하루 진행률'));
      expect(layout, contains('이번 달 소비 현황'));
      expect(layout, contains('@drawable/dayve_notification_progress'));
      expect(layout, contains('@drawable/dayve_widget_monthly_progress'));
      expect(layout, contains('@drawable/dayve_pixel_cat'));
      expect(layout, contains('widget_section_divider'));
      expect(layout, isNot(contains('haru_pixel_cat')));
      expect(layout, isNot(contains('오늘 써도 되는 돈')));
    }
    expect(provider, contains('RemoteViews('));
    expect(provider, contains('SizeF(250f, MEDIUM_HEIGHT_DP.toFloat())'));
    expect(provider, contains('R.layout.haru_widget_large'));
    expect(provider, contains('haru://widget/home'));
    expect(widgetInfo, contains('android:minHeight="110dp"'));
    expect(widgetInfo, contains('android:minResizeHeight="110dp"'));
    expect(widgetInfo, contains('android:targetCellHeight="2"'));
  });
}
