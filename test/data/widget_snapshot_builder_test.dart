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
    recommendedDailyAmount: 25000,
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
    expect(snapshot.headline, '2시간 · 퇴근까지');
    expect(snapshot.remainingMinutes, 120);
    expect(snapshot.progress, .75);
    expect(snapshot.budgetAmount, 25000);
    expect(snapshot.remainingBudgetAmount, 500000);
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

    expect(snapshot.headline, '3시간 30분 · 퇴근 후 자유');
    expect(snapshot.progress, .4);
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
    expect(restored.budgetAmountLabel, original.budgetAmountLabel);
    expect(restored.remainingBudgetLabel, original.remainingBudgetLabel);
    expect(restored.updatedAt, original.updatedAt);
    expect(restored.updatedLabel, '9/14 12:00 갱신');
    expect(restored.snapshotDate, '2026-09-14');
    expect(restored.validUntil, DateTime(2026, 9, 14, 18));
    expect(restored.progress, .5);
  });
}
