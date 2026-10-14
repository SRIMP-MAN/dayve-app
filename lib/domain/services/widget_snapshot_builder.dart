import 'package:intl/intl.dart';

import '../content/dayve_progress_copy.dart';
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
    final progress = time.state == HaruDayState.working ||
            time.state == HaruDayState.afterWork
        ? time.progress.clamp(0.0, 1.0)
        : 0.0;
    final progressPercent = (progress * 100).round().clamp(0, 100).toInt();
    final monthlyUsagePercent =
        budget.usagePercent.round().clamp(0, 100).toInt();

    return WidgetSnapshot(
      state: time.state.name,
      stateLabel: _stateLabel(time.state),
      headline: _headline(time.state, remainingMinutes),
      remainingMinutes: remainingMinutes,
      progress: progress,
      progressPercent: progressPercent,
      progressLeadingLabel: _progressLeadingLabel(time.state, now),
      progressTrailingLabel: _progressTrailingLabel(time),
      remainingBudgetAmount: budget.remainingBudget,
      remainingBudgetLabel: '${currency.format(budget.remainingBudget)}원',
      monthlyBudgetAmount: budget.cycleBudget,
      monthlyBudgetLabel: '${currency.format(budget.cycleBudget)}원',
      monthlySpentAmount: budget.spentAmount,
      monthlySpentLabel: '${currency.format(budget.spentAmount)}원',
      monthlyUsagePercent: monthlyUsagePercent,
      monthlyUsageLabel: '이번 달 $monthlyUsagePercent% 사용 중',
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
      HaruDayState.beforeWork => '출근까지 $duration',
      HaruDayState.working => '퇴근까지 $duration',
      HaruDayState.afterWork => '취침까지 $duration',
      HaruDayState.sleepWindow => '기상까지 $duration',
      HaruDayState.dayOff => '오늘은 쉬는 날',
      HaruDayState.exception => '다음 일정까지 $duration',
    };
  }

  String _stateLabel(HaruDayState state) => switch (state) {
        HaruDayState.beforeWork => 'DAYVE · 출근 전',
        HaruDayState.working => 'DAYVE · 근무 중',
        HaruDayState.afterWork => 'DAYVE · 자유시간',
        HaruDayState.sleepWindow => 'DAYVE · 수면',
        HaruDayState.dayOff => 'DAYVE · 휴무',
        HaruDayState.exception => 'DAYVE · 일정 변경',
      };

  String _progressLeadingLabel(HaruDayState state, DateTime now) =>
      switch (state) {
        HaruDayState.working =>
          DayveProgressCopy.workingLeading(now).replaceFirst('!', ''),
        HaruDayState.afterWork => '오늘도 수고했어요',
        _ => '',
      };

  String _progressTrailingLabel(TimeSummary time) {
    final end = time.segmentEndAt ?? time.nextEventAt;
    final timeLabel = '${_twoDigits(end.hour)}:${_twoDigits(end.minute)}';
    return switch (time.state) {
      HaruDayState.working => '퇴근 $timeLabel',
      HaruDayState.afterWork => '취침 $timeLabel',
      _ => '',
    };
  }

  String _twoDigits(int value) => value.toString().padLeft(2, '0');

  String _durationLabel(int totalMinutes) {
    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;
    if (hours == 0) return '$minutes분';
    if (minutes == 0) return '$hours시간';
    return '$hours시간 $minutes분';
  }
}
