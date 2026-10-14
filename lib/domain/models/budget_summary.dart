class BudgetSummary {
  const BudgetSummary({
    required this.cycleBudget,
    required this.spentAmount,
    required this.remainingBudget,
    required this.remainingDays,
  });

  final int cycleBudget;
  final int spentAmount;
  final int remainingBudget;
  final int remainingDays;

  double get usageRatio =>
      cycleBudget <= 0 ? 0 : (spentAmount / cycleBudget).clamp(0.0, 1.0);

  double get usagePercent => usageRatio * 100;
}
