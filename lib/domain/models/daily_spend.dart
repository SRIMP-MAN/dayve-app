class DailySpend {
  const DailySpend({
    required this.date,
    required this.amount,
    required this.updatedAt,
  });

  final DateTime date;
  final int amount;
  final DateTime updatedAt;
}
