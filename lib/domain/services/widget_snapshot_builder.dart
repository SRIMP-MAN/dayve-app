import 'package:intl/intl.dart';

import '../models/budget_summary.dart';
import '../models/time_summary.dart';
import '../models/widget_snapshot.dart';

class WidgetSnapshotBuilder {
  const WidgetSnapshotBuilder();

  WidgetSnapshot build({
    required DateTime now,
    required DateTime validUntil,
    required TimeSummary time,
    required BudgetSummary budget,
  }) {
    final currency = NumberFormat.decimalPattern('ko_KR');
    final remainingMinutes = time.remaining.inMinutes.clamp(0, 1 << 31).toInt();

    return WidgetSnapshot(
      state: time.state.name,
      stateLabel: _stateLabel(time.state),
      headline: _headline(time.state, remainingMinutes),
      remainingMinutes: remainingMinutes,
      progress: time.state == HaruDayState.working ||
              time.state == HaruDayState.afterWork
          ? time.progress.clamp(0.0, 1.0)
          : 0,
      budgetLabel: '오늘 권장 사용 가능',
      budgetAmount: budget.recommendedDailyAmount,
      budgetAmountLabel: '${currency.format(budget.recommendedDailyAmount)}원',
      remainingBudgetAmount: budget.remainingBudget,
      remainingBudgetLabel: '${currency.format(budget.remainingBudget)}원',
      updatedAt: now,
      updatedLabel:
          '${now.month}/${now.day} ${_twoDigits(now.hour)}:${_twoDigits(now.minute)} 갱신',
      snapshotDate:
          '${now.year}-${_twoDigits(now.month)}-${_twoDigits(now.day)}',
      validUntil: validUntil,
    );
  }

  String _headline(HaruDayState state, int remainingMinutes) {
    final duration = _durationLabel(remainingMinutes);
    return switch (state) {
      HaruDayState.beforeWork => '$duration · 출근까지',
      HaruDayState.working => '$duration · 퇴근까지',
      HaruDayState.afterWork => '$duration · 퇴근 후 자유',
      HaruDayState.sleepWindow => '$duration · 기상까지',
      HaruDayState.dayOff => '오늘은 쉬는 날',
      HaruDayState.exception => '$duration · 변경 일정',
    };
  }

  String _stateLabel(HaruDayState state) => switch (state) {
        HaruDayState.beforeWork => 'DAYVE · 출근 전',
        HaruDayState.working => 'DAYVE · 근무 중',
        HaruDayState.afterWork => 'DAYVE · 퇴근 후',
        HaruDayState.sleepWindow => 'DAYVE · 수면',
        HaruDayState.dayOff => 'DAYVE · 휴무',
        HaruDayState.exception => 'DAYVE · 일정 변경',
      };

  String _twoDigits(int value) => value.toString().padLeft(2, '0');

  String _durationLabel(int totalMinutes) {
    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;
    if (hours == 0) return '$minutes분';
    if (minutes == 0) return '$hours시간';
    return '$hours시간 $minutes분';
  }
}
