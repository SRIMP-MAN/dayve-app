import 'package:flutter_test/flutter_test.dart';
import 'package:haru_app/domain/models/budget_profile.dart';
import 'package:haru_app/domain/models/daily_spend.dart';
import 'package:haru_app/domain/services/budget_engine.dart';

void main() {
  const engine = BudgetEngine();

  test('recommends daily budget from remaining amount', () {
    final result = engine.calculate(
      now: DateTime(2026, 9, 11),
      profile: const BudgetProfile(
        cycleBudget: 600000,
        cycleStartDay: 1,
      ),
      spends: [
        DailySpend(
          date: DateTime(2026, 9, 10),
          amount: 100000,
          updatedAt: DateTime(2026, 9, 10),
        ),
      ],
    );

    expect(result.remainingBudget, 500000);
    expect(result.recommendedDailyAmount, greaterThan(0));
  });

  test('month end rolls into a new monthly cycle', () {
    const profile = BudgetProfile(cycleBudget: 300000, cycleStartDay: 1);
    final spends = [
      DailySpend(
        date: DateTime(2026, 9, 30),
        amount: 50000,
        updatedAt: DateTime(2026, 9, 30),
      ),
      DailySpend(
        date: DateTime(2026, 10, 1),
        amount: 10000,
        updatedAt: DateTime(2026, 10, 1),
      ),
    ];

    final september = engine.calculate(
      now: DateTime(2026, 9, 30, 23, 59),
      profile: profile,
      spends: spends,
    );
    final october = engine.calculate(
      now: DateTime(2026, 10, 1),
      profile: profile,
      spends: spends,
    );

    expect(september.spentAmount, 50000);
    expect(october.spentAmount, 10000);
    expect(october.remainingBudget, 290000);
  });

  test('payday 1 uses the first day of each month', () {
    expect(
      engine.nextCycleStart(
        now: DateTime(2026, 9, 20),
        profile: const BudgetProfile(
          cycleBudget: 600000,
          cycleStartDay: 1,
        ),
      ),
      DateTime(2026, 10, 1),
    );
  });

  test('payday 25 creates a cycle through the next month day 24', () {
    final result = engine.calculate(
      now: DateTime(2026, 10, 24),
      profile: const BudgetProfile(
        cycleBudget: 600000,
        cycleStartDay: 25,
      ),
      spends: [
        DailySpend(
          date: DateTime(2026, 9, 24),
          amount: 10000,
          updatedAt: DateTime(2026, 9, 24),
        ),
        DailySpend(
          date: DateTime(2026, 9, 25),
          amount: 20000,
          updatedAt: DateTime(2026, 9, 25),
        ),
        DailySpend(
          date: DateTime(2026, 10, 24),
          amount: 30000,
          updatedAt: DateTime(2026, 10, 24),
        ),
      ],
    );

    expect(result.spentAmount, 50000);
    expect(
      engine.nextCycleStart(
        now: DateTime(2026, 10, 24),
        profile: const BudgetProfile(
          cycleBudget: 600000,
          cycleStartDay: 25,
        ),
      ),
      DateTime(2026, 10, 25),
    );
  });

  test('payday 31 falls back to the last day of a shorter month', () {
    final beforeFebruaryReset = engine.nextCycleStart(
      now: DateTime(2026, 2, 27),
      profile: const BudgetProfile(
        cycleBudget: 600000,
        cycleStartDay: 31,
      ),
    );
    final afterFebruaryReset = engine.nextCycleStart(
      now: DateTime(2026, 2, 28),
      profile: const BudgetProfile(
        cycleBudget: 600000,
        cycleStartDay: 31,
      ),
    );

    expect(beforeFebruaryReset, DateTime(2026, 2, 28));
    expect(afterFebruaryReset, DateTime(2026, 3, 31));
  });

  test('next reset date follows the configured payday', () {
    expect(
      engine.nextCycleStart(
        now: DateTime(2026, 9, 30),
        profile: const BudgetProfile(
          cycleBudget: 600000,
          cycleStartDay: 25,
        ),
      ),
      DateTime(2026, 10, 25),
    );
  });

  test('cycleStartDay selects the correct cross-month spending window', () {
    final result = engine.calculate(
      now: DateTime(2026, 9, 10),
      profile: const BudgetProfile(cycleBudget: 200000, cycleStartDay: 15),
      spends: [
        DailySpend(
          date: DateTime(2026, 8, 20),
          amount: 30000,
          updatedAt: DateTime(2026, 8, 20),
        ),
        DailySpend(
          date: DateTime(2026, 9, 14),
          amount: 20000,
          updatedAt: DateTime(2026, 9, 14),
        ),
        DailySpend(
          date: DateTime(2026, 9, 15),
          amount: 90000,
          updatedAt: DateTime(2026, 9, 15),
        ),
      ],
    );

    expect(result.spentAmount, 50000);
    expect(result.remainingBudget, 150000);
    expect(
      engine.nextCycleStart(
        now: DateTime(2026, 9, 10),
        profile: const BudgetProfile(cycleBudget: 200000, cycleStartDay: 15),
      ),
      DateTime(2026, 9, 15),
    );
  });
}
