class BudgetSummary {
  const BudgetSummary({
    required this.cycleBudget,
    required this.spentAmount,
    required this.remainingBudget,
    required this.remainingDays,
    required this.recommendedDailyAmount,
  });

  final int cycleBudget;
  final int spentAmount;
  final int remainingBudget;
  final int remainingDays;
  final int recommendedDailyAmount;
}
