import '../models/app_settings.dart';
import '../models/time_summary.dart';
import 'budget_engine.dart';

enum WidgetRefreshReason { scheduleEvent, midnight, budgetCycle }

class WidgetRefreshPlan {
  const WidgetRefreshPlan({required this.at, required this.reason});

  final DateTime at;
  final WidgetRefreshReason reason;
}

class WidgetRefreshPlanner {
  const WidgetRefreshPlanner();

  WidgetRefreshPlan next({
    required DateTime now,
    required AppSettings settings,
    required TimeSummary time,
  }) {
    final midnight = DateTime(now.year, now.month, now.day + 1);
    final budgetCycle = const BudgetEngine().nextCycleStart(
      now: now,
      profile: settings.budget,
    );
    final candidates = [
      WidgetRefreshPlan(
        at: time.nextEventAt,
        reason: WidgetRefreshReason.scheduleEvent,
      ),
      WidgetRefreshPlan(
        at: midnight,
        reason: WidgetRefreshReason.midnight,
      ),
      WidgetRefreshPlan(
        at: budgetCycle,
        reason: WidgetRefreshReason.budgetCycle,
      ),
    ].where((plan) => plan.at.isAfter(now)).toList(growable: false)
      ..sort((a, b) => a.at.compareTo(b.at));

    return candidates.first;
  }
}
