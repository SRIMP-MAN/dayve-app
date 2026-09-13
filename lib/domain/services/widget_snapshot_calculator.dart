import '../models/app_settings.dart';
import '../models/budget_summary.dart';
import '../models/daily_spend.dart';
import '../models/day_override.dart';
import '../models/schedule_entry.dart';
import '../models/time_summary.dart';
import '../models/widget_snapshot.dart';
import 'budget_engine.dart';
import 'time_engine.dart';
import 'widget_refresh_planner.dart';
import 'widget_snapshot_builder.dart';

class WidgetSnapshotCalculation {
  const WidgetSnapshotCalculation({
    required this.snapshot,
    required this.nextRefresh,
    required this.time,
    required this.budget,
  });

  final WidgetSnapshot snapshot;
  final WidgetRefreshPlan nextRefresh;
  final TimeSummary time;
  final BudgetSummary budget;
}

class WidgetSnapshotCalculator {
  const WidgetSnapshotCalculator();

  WidgetSnapshotCalculation calculate({
    required DateTime now,
    required AppSettings settings,
    required List<DailySpend> spends,
    ScheduleEntry? scheduleEntry,
    DayOverride? override,
  }) {
    final time = const TimeEngine().calculate(
      now: now,
      profile: settings.schedule,
      scheduleEntry: scheduleEntry,
      override: override,
    );
    final budget = const BudgetEngine().calculate(
      now: now,
      profile: settings.budget,
      spends: spends,
    );
    final nextRefresh = const WidgetRefreshPlanner().next(
      now: now,
      settings: settings,
      time: time,
    );
    final snapshot = const WidgetSnapshotBuilder().build(
      now: now,
      validUntil: nextRefresh.at,
      time: time,
      budget: budget,
    );

    return WidgetSnapshotCalculation(
      snapshot: snapshot,
      nextRefresh: nextRefresh,
      time: time,
      budget: budget,
    );
  }
}
