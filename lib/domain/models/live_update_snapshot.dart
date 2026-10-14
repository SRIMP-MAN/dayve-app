class LiveUpdateSnapshot {
  const LiveUpdateSnapshot({
    required this.visible,
    required this.state,
    required this.title,
    required this.body,
    required this.headline,
    required this.remainingMinutes,
    required this.progress,
    required this.remainingLabel,
    required this.progressPercent,
    required this.startTime,
    required this.endsAt,
    required this.updatedAt,
    this.showCheckoutActions = false,
    this.scheduleDate,
    this.showMoney = false,
    this.remainingBudgetLabel = '',
    this.stateLabel = '',
    this.progressLeadingLabel = '',
    this.progressTrailingLabel = '',
    this.endLabel = '',
    this.monthlyBudget = '',
    this.monthlyRemaining = '',
    this.monthlySpent = '',
    this.monthlyUsagePercent = 0,
  });

  final bool visible;
  final String state;
  final String title;
  final String body;
  final String headline;
  final int remainingMinutes;
  final double progress;
  final String remainingLabel;
  final int progressPercent;
  final DateTime? startTime;
  final DateTime endsAt;
  DateTime get endTime => endsAt;
  final DateTime updatedAt;
  final bool showCheckoutActions;
  final DateTime? scheduleDate;
  final bool showMoney;
  final String remainingBudgetLabel;
  final String stateLabel;
  final String progressLeadingLabel;
  final String progressTrailingLabel;
  final String endLabel;
  final String monthlyBudget;
  final String monthlyRemaining;
  final String monthlySpent;
  final int monthlyUsagePercent;

  Map<String, Object?> toMap() => {
        'visible': visible,
        'state': state,
        'title': title,
        'body': body,
        'headline': headline,
        'remainingMinutes': remainingMinutes,
        'progress': progress,
        'remainingLabel': remainingLabel,
        'progressPercent': progressPercent,
        'startTimeMillis': startTime?.millisecondsSinceEpoch,
        'endTimeMillis': endsAt.millisecondsSinceEpoch,
        'endsAtMillis': endsAt.millisecondsSinceEpoch,
        'updatedAtMillis': updatedAt.millisecondsSinceEpoch,
        'showCheckoutActions': showCheckoutActions,
        'scheduleDate': scheduleDate?.toIso8601String(),
        'showMoney': showMoney,
        'remainingBudgetLabel': remainingBudgetLabel,
        'moneyVisible': showMoney,
        'stateLabel': stateLabel,
        'progressLeadingLabel': progressLeadingLabel,
        'progressTrailingLabel': progressTrailingLabel,
        'endLabel': endLabel,
        'monthlyBudget': monthlyBudget,
        'monthlyRemaining': monthlyRemaining,
        'monthlySpent': monthlySpent,
        'monthlyUsagePercent': monthlyUsagePercent,
      };

  factory LiveUpdateSnapshot.fromMap(Map<Object?, Object?> map) {
    return LiveUpdateSnapshot(
      visible: map['visible'] as bool? ?? false,
      state: map['state'] as String? ?? 'hidden',
      title: map['title'] as String? ?? 'DAYVE',
      body: map['body'] as String? ?? '',
      headline: map['headline'] as String? ?? map['body'] as String? ?? '',
      remainingMinutes: (map['remainingMinutes'] as num? ?? 0).toInt(),
      progress: (map['progress'] as num? ?? 0).toDouble().clamp(0.0, 1.0),
      remainingLabel: map['remainingLabel'] as String? ?? '',
      progressPercent: (map['progressPercent'] as num? ?? 0).toInt(),
      startTime: _dateFromMillis(map['startTimeMillis']),
      endsAt: DateTime.fromMillisecondsSinceEpoch(
        (map['endTimeMillis'] as num? ?? map['endsAtMillis'] as num? ?? 0)
            .toInt(),
      ),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(
        (map['updatedAtMillis'] as num? ?? 0).toInt(),
      ),
      showCheckoutActions: map['showCheckoutActions'] as bool? ?? false,
      scheduleDate: _dateFromIso(map['scheduleDate']),
      showMoney:
          map['moneyVisible'] as bool? ?? map['showMoney'] as bool? ?? false,
      remainingBudgetLabel: map['remainingBudgetLabel'] as String? ?? '',
      stateLabel: map['stateLabel'] as String? ?? '',
      progressLeadingLabel: map['progressLeadingLabel'] as String? ?? '',
      progressTrailingLabel: map['progressTrailingLabel'] as String? ?? '',
      endLabel: map['endLabel'] as String? ?? '',
      monthlyBudget: map['monthlyBudget'] as String? ?? '',
      monthlyRemaining: map['monthlyRemaining'] as String? ?? '',
      monthlySpent: map['monthlySpent'] as String? ?? '',
      monthlyUsagePercent: (map['monthlyUsagePercent'] as num? ?? 0)
          .toInt()
          .clamp(0, 100)
          .toInt(),
    );
  }
}

DateTime? _dateFromMillis(Object? value) {
  final millis = (value as num?)?.toInt();
  return millis == null ? null : DateTime.fromMillisecondsSinceEpoch(millis);
}

DateTime? _dateFromIso(Object? value) {
  final text = value as String?;
  return text == null ? null : DateTime.tryParse(text);
}

class LiveUpdateCommand {
  const LiveUpdateCommand({
    required this.executeAt,
    required this.snapshot,
  });

  final DateTime executeAt;
  final LiveUpdateSnapshot snapshot;

  Map<String, Object?> toMap() => {
        'executeAtMillis': executeAt.millisecondsSinceEpoch,
        'snapshot': snapshot.toMap(),
      };

  factory LiveUpdateCommand.fromMap(Map<Object?, Object?> map) {
    return LiveUpdateCommand(
      executeAt: DateTime.fromMillisecondsSinceEpoch(
        (map['executeAtMillis'] as num? ?? 0).toInt(),
      ),
      snapshot: LiveUpdateSnapshot.fromMap(
        (map['snapshot'] as Map<Object?, Object?>?) ?? const {},
      ),
    );
  }
}

class LiveUpdatePlan {
  const LiveUpdatePlan({
    required this.current,
    required this.transitions,
  });

  final LiveUpdateCommand current;
  final List<LiveUpdateCommand> transitions;

  Map<String, Object?> toMap() => {
        'current': current.toMap(),
        'transitions': transitions.map((item) => item.toMap()).toList(),
      };

  factory LiveUpdatePlan.fromMap(Map<Object?, Object?> map) {
    final values = map['transitions'] as List<Object?>? ?? const [];
    return LiveUpdatePlan(
      current: LiveUpdateCommand.fromMap(
        (map['current'] as Map<Object?, Object?>?) ?? const {},
      ),
      transitions: values
          .whereType<Map<Object?, Object?>>()
          .map(LiveUpdateCommand.fromMap)
          .toList(growable: false),
    );
  }
}
