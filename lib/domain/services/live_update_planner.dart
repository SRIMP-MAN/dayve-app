import '../models/live_update_snapshot.dart';
import '../models/schedule_entry.dart';
import '../models/schedule_profile.dart';
import '../models/time_summary.dart';
import 'time_engine.dart';

typedef ActiveScheduleResolver = ScheduleEntry? Function(DateTime at);
typedef LiveUpdateMoneyResolver = LiveUpdateMoneyLabels Function(DateTime at);

class LiveUpdateMoneyLabels {
  const LiveUpdateMoneyLabels({
    required this.today,
    required this.remaining,
    required this.spent,
  });

  final String today;
  final String remaining;
  final String spent;
}

class LiveUpdatePlanner {
  const LiveUpdatePlanner({
    this.horizon = const Duration(days: 8),
    this.maximumTransitions = 96,
  });

  final Duration horizon;
  final int maximumTransitions;

  LiveUpdatePlan plan({
    required DateTime now,
    required ScheduleProfile profile,
    required ActiveScheduleResolver activeScheduleFor,
    LiveUpdateMoneyResolver? moneyFor,
  }) {
    var cursor = now;
    var summary = _calculate(cursor, profile, activeScheduleFor);
    final current = LiveUpdateCommand(
      executeAt: now,
      snapshot: _snapshot(summary, updatedAt: now, moneyFor: moneyFor),
    );
    final transitions = <LiveUpdateCommand>[];
    final limit = now.add(horizon);
    var lastSnapshot = current.snapshot;

    for (var index = 0; index < maximumTransitions; index += 1) {
      final eventAt = summary.nextEventAt;
      if (!eventAt.isAfter(cursor) || eventAt.isAfter(limit)) break;

      final milestoneAt = _nextProgressMilestone(summary, cursor);
      if (milestoneAt != null &&
          milestoneAt.isBefore(eventAt) &&
          !milestoneAt.isAfter(limit)) {
        cursor = milestoneAt;
        summary = _calculate(cursor, profile, activeScheduleFor);
        final milestoneSnapshot = _snapshot(
          summary,
          updatedAt: cursor,
          moneyFor: moneyFor,
        );
        if (_meaningfullyDifferent(lastSnapshot, milestoneSnapshot)) {
          transitions.add(
            LiveUpdateCommand(
              executeAt: milestoneAt,
              snapshot: milestoneSnapshot,
            ),
          );
          lastSnapshot = milestoneSnapshot;
        }
        continue;
      }

      final previousSummary = summary;
      cursor = eventAt;
      summary = _calculate(cursor, profile, activeScheduleFor);
      final asksForCheckout = previousSummary.state == HaruDayState.working &&
          summary.state == HaruDayState.afterWork;
      final segmentStart = previousSummary.segmentStartAt;
      final nextSnapshot = _snapshot(
        summary,
        updatedAt: eventAt,
        moneyFor: moneyFor,
        showCheckoutActions: asksForCheckout,
        scheduleDate: asksForCheckout && segmentStart != null
            ? DateTime(
                segmentStart.year,
                segmentStart.month,
                segmentStart.day,
              )
            : null,
      );
      if (_meaningfullyDifferent(lastSnapshot, nextSnapshot)) {
        transitions.add(
          LiveUpdateCommand(executeAt: eventAt, snapshot: nextSnapshot),
        );
        lastSnapshot = nextSnapshot;
      }
    }

    return LiveUpdatePlan(current: current, transitions: transitions);
  }

  TimeSummary _calculate(
    DateTime at,
    ScheduleProfile profile,
    ActiveScheduleResolver activeScheduleFor,
  ) {
    return const TimeEngine().calculate(
      now: at,
      profile: profile,
      scheduleEntry: activeScheduleFor(at),
    );
  }

  LiveUpdateSnapshot _snapshot(
    TimeSummary summary, {
    required DateTime updatedAt,
    required LiveUpdateMoneyResolver? moneyFor,
    bool showCheckoutActions = false,
    DateTime? scheduleDate,
  }) {
    final visible = summary.state == HaruDayState.working ||
        summary.state == HaruDayState.afterWork;
    final normalizedProgress = summary.progress.clamp(0.0, 1.0);
    final progress = (normalizedProgress * 100).round();
    final remainingMinutes =
        summary.remaining.inMinutes.clamp(0, 1 << 31).toInt();
    final remaining = _durationLabel(summary.remaining);
    final activityLabel = switch (summary.state) {
      HaruDayState.working => '퇴근까지',
      HaruDayState.afterWork => '취침까지',
      _ => '',
    };
    final stateLabel = switch (summary.state) {
      HaruDayState.working => '근무 중',
      HaruDayState.afterWork => '내 시간',
      _ => '',
    };
    final headline = visible
        ? '$activityLabel ${_clockDurationLabel(remainingMinutes)}'
        : '';
    final progressLeadingLabel = switch (summary.state) {
      HaruDayState.working => '오전은 수고했어요',
      HaruDayState.afterWork => '오늘도 수고했어요',
      _ => '',
    };
    final progressTrailingLabel = switch (summary.state) {
      HaruDayState.working => headline,
      HaruDayState.afterWork => '내 시간 보내는 중',
      _ => '',
    };
    final money = visible ? moneyFor?.call(updatedAt) : null;

    return LiveUpdateSnapshot(
      visible: visible,
      state: summary.state.name,
      title: stateLabel.isEmpty ? 'HARU' : 'HARU · $stateLabel',
      body: visible ? '$headline · 진행률 $progress%' : '',
      headline: headline,
      remainingMinutes: remainingMinutes,
      progress: normalizedProgress,
      remainingLabel: remaining,
      progressPercent: progress,
      startTime: summary.segmentStartAt,
      endsAt: summary.segmentEndAt ?? summary.nextEventAt,
      updatedAt: updatedAt,
      showCheckoutActions: showCheckoutActions,
      scheduleDate: scheduleDate,
      showMoney: money != null,
      todayBudgetLabel: money == null ? '' : '오늘 ${money.today}',
      remainingBudgetLabel: money == null ? '' : '이번 달 ${money.remaining}',
      stateLabel: stateLabel,
      progressLeadingLabel: progressLeadingLabel,
      progressTrailingLabel: progressTrailingLabel,
      todaySpendable: money?.today ?? '',
      monthlyRemaining: money?.remaining ?? '',
      monthlySpent: money?.spent ?? '',
    );
  }

  DateTime? _nextProgressMilestone(TimeSummary summary, DateTime after) {
    final start = summary.segmentStartAt;
    final end = summary.segmentEndAt;
    if (start == null || end == null || !end.isAfter(start)) return null;
    final totalMillis = end.difference(start).inMilliseconds;
    for (final fraction in const [0.25, 0.5, 0.75]) {
      final at = start.add(
        Duration(milliseconds: (totalMillis * fraction).round()),
      );
      if (at.isAfter(after) && at.isBefore(end)) return at;
    }
    return null;
  }

  bool _meaningfullyDifferent(
    LiveUpdateSnapshot previous,
    LiveUpdateSnapshot next,
  ) {
    if (!previous.visible && !next.visible) return false;
    if (previous.visible != next.visible || previous.state != next.state) {
      return true;
    }
    return next.visible &&
        (previous.endsAt != next.endsAt ||
            previous.progressPercent != next.progressPercent ||
            previous.showCheckoutActions != next.showCheckoutActions ||
            previous.todayBudgetLabel != next.todayBudgetLabel ||
            previous.remainingBudgetLabel != next.remainingBudgetLabel ||
            previous.monthlySpent != next.monthlySpent);
  }

  String _durationLabel(Duration duration) {
    final minutes = duration.inMinutes.clamp(0, 1 << 31);
    final hours = minutes ~/ 60;
    final rest = minutes % 60;
    if (hours == 0) return '$rest분';
    if (rest == 0) return '$hours시간';
    return '$hours시간 $rest분';
  }

  String _clockDurationLabel(int minutes) {
    final hours = minutes ~/ 60;
    final rest = minutes % 60;
    return '${hours.toString().padLeft(2, '0')}:'
        '${rest.toString().padLeft(2, '0')}';
  }
}
