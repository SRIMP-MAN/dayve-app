import 'dart:convert';

class WidgetSnapshot {
  const WidgetSnapshot({
    required this.state,
    required this.stateLabel,
    required this.headline,
    required this.remainingMinutes,
    required this.progress,
    required this.progressPercent,
    required this.progressLeadingLabel,
    required this.progressTrailingLabel,
    required this.remainingBudgetAmount,
    required this.remainingBudgetLabel,
    required this.monthlyBudgetAmount,
    required this.monthlyBudgetLabel,
    required this.monthlySpentAmount,
    required this.monthlySpentLabel,
    required this.monthlyUsagePercent,
    required this.monthlyUsageLabel,
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
  final int progressPercent;
  final String progressLeadingLabel;
  final String progressTrailingLabel;
  final int remainingBudgetAmount;
  final String remainingBudgetLabel;
  final int monthlyBudgetAmount;
  final String monthlyBudgetLabel;
  final int monthlySpentAmount;
  final String monthlySpentLabel;
  final int monthlyUsagePercent;
  final String monthlyUsageLabel;
  final DateTime updatedAt;
  final String updatedLabel;
  final String snapshotDate;
  final DateTime validUntil;

  Map<String, Object> toJson() => {
        'state': state,
        'workStatus': state,
        'stateLabel': stateLabel,
        'headline': headline,
        'remainingWorkTime': headline,
        'remainingMinutes': remainingMinutes,
        'progress': progress,
        'workProgress': progress,
        'progressPercent': progressPercent,
        'progressLeadingLabel': progressLeadingLabel,
        'progressTrailingLabel': progressTrailingLabel,
        'remainingBudgetAmount': remainingBudgetAmount,
        'remainingBudgetLabel': remainingBudgetLabel,
        'monthlyBudgetAmount': monthlyBudgetAmount,
        'monthlyBudget': monthlyBudgetAmount,
        'monthlyBudgetLabel': monthlyBudgetLabel,
        'monthlySpentAmount': monthlySpentAmount,
        'monthlySpent': monthlySpentAmount,
        'monthlySpentLabel': monthlySpentLabel,
        'monthlyRemainingAmount': remainingBudgetAmount,
        'monthlyRemaining': remainingBudgetAmount,
        'monthlyRemainingLabel': remainingBudgetLabel,
        'monthlyUsagePercent': monthlyUsagePercent,
        'monthlyUsageLabel': monthlyUsageLabel,
        'workEndTime': progressTrailingLabel,
        'updatedAt': updatedAt.toIso8601String(),
        'lastUpdatedAt': updatedAt.toIso8601String(),
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
      progressPercent: (json['progressPercent'] as num?)?.toInt() ??
          (((json['progress'] as num?)?.toDouble() ?? 0) * 100).round(),
      progressLeadingLabel:
          json['progressLeadingLabel'] as String? ?? '오늘도 조금씩',
      progressTrailingLabel: json['progressTrailingLabel'] as String? ?? '',
      remainingBudgetAmount:
          (json['monthlyRemainingAmount'] as num?)?.toInt() ??
              (json['remainingBudgetAmount'] as num?)?.toInt() ??
              0,
      remainingBudgetLabel: json['monthlyRemainingLabel'] as String? ??
          json['remainingBudgetLabel'] as String? ??
          '0원',
      monthlyBudgetAmount: (json['monthlyBudgetAmount'] as num?)?.toInt() ?? 0,
      monthlyBudgetLabel: json['monthlyBudgetLabel'] as String? ?? '0원',
      monthlySpentAmount: (json['monthlySpentAmount'] as num?)?.toInt() ?? 0,
      monthlySpentLabel: json['monthlySpentLabel'] as String? ?? '0원',
      monthlyUsagePercent: (json['monthlyUsagePercent'] as num?)?.toInt() ?? 0,
      monthlyUsageLabel: json['monthlyUsageLabel'] as String? ?? '이번 달 0% 사용 중',
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
