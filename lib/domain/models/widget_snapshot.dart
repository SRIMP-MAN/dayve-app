import 'dart:convert';

class WidgetSnapshot {
  const WidgetSnapshot({
    required this.state,
    required this.stateLabel,
    required this.headline,
    required this.remainingMinutes,
    required this.progress,
    required this.budgetLabel,
    required this.budgetAmount,
    required this.budgetAmountLabel,
    required this.remainingBudgetAmount,
    required this.remainingBudgetLabel,
    required this.updatedAt,
    required this.updatedLabel,
    required this.snapshotDate,
    required this.validUntil,
  });

  final String state;
  final String stateLabel;
  final String headline;
  final int remainingMinutes;
  final double progress;
  final String budgetLabel;
  final int budgetAmount;
  final String budgetAmountLabel;
  final int remainingBudgetAmount;
  final String remainingBudgetLabel;
  final DateTime updatedAt;
  final String updatedLabel;
  final String snapshotDate;
  final DateTime validUntil;

  Map<String, Object> toJson() => {
        'state': state,
        'stateLabel': stateLabel,
        'headline': headline,
        'remainingMinutes': remainingMinutes,
        'progress': progress,
        'budgetLabel': budgetLabel,
        'budgetAmount': budgetAmount,
        'budgetAmountLabel': budgetAmountLabel,
        'remainingBudgetAmount': remainingBudgetAmount,
        'remainingBudgetLabel': remainingBudgetLabel,
        'updatedAt': updatedAt.toIso8601String(),
        'updatedLabel': updatedLabel,
        'snapshotDate': snapshotDate,
        'validUntil': validUntil.toIso8601String(),
        'validUntilEpochMillis': validUntil.millisecondsSinceEpoch,
      };

  String encode() => jsonEncode(toJson());

  factory WidgetSnapshot.fromJson(Map<String, dynamic> json) {
    return WidgetSnapshot(
      state: json['state'] as String,
      stateLabel: json['stateLabel'] as String,
      headline: json['headline'] as String,
      remainingMinutes: json['remainingMinutes'] as int,
      progress: (json['progress'] as num?)?.toDouble() ?? 0,
      budgetLabel: json['budgetLabel'] as String,
      budgetAmount: json['budgetAmount'] as int,
      budgetAmountLabel: json['budgetAmountLabel'] as String,
      remainingBudgetAmount: json['remainingBudgetAmount'] as int,
      remainingBudgetLabel: json['remainingBudgetLabel'] as String,
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      updatedLabel: json['updatedLabel'] as String,
      snapshotDate: json['snapshotDate'] as String,
      validUntil: DateTime.parse(json['validUntil'] as String),
    );
  }

  factory WidgetSnapshot.decode(String encoded) {
    return WidgetSnapshot.fromJson(
      jsonDecode(encoded) as Map<String, dynamic>,
    );
  }
}
