import '../models/budget_profile.dart';
import '../models/budget_summary.dart';
import '../models/daily_spend.dart';

class BudgetEngine {
  const BudgetEngine();

  BudgetSummary calculate({
    required DateTime now,
    required BudgetProfile profile,
    required List<DailySpend> spends,
  }) {
    final cycle = _cycleFor(now, profile.cycleStartDay);

    final spent = spends
        .where((e) =>
            !e.date.isBefore(cycle.start) &&
            e.date.isBefore(cycle.endExclusive))
        .fold<int>(0, (sum, e) => sum + e.amount);

    final remainingBudget = profile.cycleBudget - spent;

    final today = DateTime(now.year, now.month, now.day);
    final lastDay = cycle.endExclusive.subtract(const Duration(days: 1));
    final remainingDays = lastDay.difference(today).inDays + 1;
    final safeRemainingDays = remainingDays < 1 ? 1 : remainingDays;

    final recommended = remainingBudget <= 0
        ? 0
        : (remainingBudget / safeRemainingDays).floor();

    return BudgetSummary(
      cycleBudget: profile.cycleBudget,
      spentAmount: spent,
      remainingBudget: remainingBudget,
      remainingDays: safeRemainingDays,
      recommendedDailyAmount: recommended,
    );
  }

  DateTime nextCycleStart({
    required DateTime now,
    required BudgetProfile profile,
  }) {
    final cycle = _cycleFor(now, profile.cycleStartDay);
    return cycle.endExclusive;
  }

  ({DateTime start, DateTime endExclusive}) _cycleFor(
    DateTime now,
    int startDay,
  ) {
    final currentMonthStart = _safeDate(now.year, now.month, startDay);

    late final DateTime start;
    late final DateTime endExclusive;

    if (!now.isBefore(currentMonthStart)) {
      start = currentMonthStart;
      endExclusive = _safeDateForNextMonth(now.year, now.month, startDay);
    } else {
      final previousMonth = DateTime(now.year, now.month - 1, 1);
      start = _safeDate(previousMonth.year, previousMonth.month, startDay);
      endExclusive = currentMonthStart;
    }

    return (start: start, endExclusive: endExclusive);
  }

  DateTime _safeDate(int year, int month, int day) {
    final firstOfNext = DateTime(year, month + 1, 1);
    final lastOfMonth = firstOfNext.subtract(const Duration(days: 1)).day;
    return DateTime(year, month, day.clamp(1, lastOfMonth));
  }

  DateTime _safeDateForNextMonth(int year, int month, int day) {
    final next = DateTime(year, month + 1, 1);
    return _safeDate(next.year, next.month, day);
  }
}
