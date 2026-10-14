import 'package:flutter/material.dart';

import '../domain/models/daily_spend.dart';
import 'dayve_design_tokens.dart';
import 'dayve_header.dart';
import 'monthly_expense_card.dart';
import 'today_status_card.dart';
import 'work_progress_card.dart';

class HaruTodayTab extends StatelessWidget {
  const HaruTodayTab({
    required this.now,
    required this.dateLabel,
    required this.state,
    required this.timeValue,
    required this.timeCaption,
    required this.monthlyBudget,
    required this.monthlyRemaining,
    required this.monthlySpent,
    required this.monthlyUsageRatio,
    required this.remainingDays,
    required this.onScheduleTap,
    required this.onSpendTap,
    required this.onMonthlyDetailsTap,
    this.nextEvent,
    this.progress,
    this.progressLabel,
    this.overrideLabel,
    super.key,
  });

  final DateTime now;
  final String dateLabel;
  final String state;
  final String timeValue;
  final String timeCaption;
  final int monthlyBudget;
  final int monthlyRemaining;
  final int monthlySpent;
  final double monthlyUsageRatio;
  final int remainingDays;
  final String? nextEvent;
  final double? progress;
  final String? progressLabel;
  final String? overrideLabel;
  final VoidCallback onScheduleTap;
  final VoidCallback onSpendTap;
  final VoidCallback onMonthlyDetailsTap;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: DayveColors.background,
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [DayveColors.background, Color(0xfffbf9ff), Colors.white],
          stops: [0, .52, 1],
        ),
      ),
      child: ListView(
        key: const Key('today_tab'),
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 18),
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 430),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  DayveHeader(
                    dateLabel: dateLabel,
                    onSettingsTap: onScheduleTap,
                  ),
                  TodayStatusCard(
                    state: state,
                    value: timeValue,
                    caption: timeCaption,
                    now: now,
                    overrideLabel: overrideLabel,
                  ),
                  if (progress != null) ...[
                    const SizedBox(height: 9),
                    HaruTimeArea(
                      now: now,
                      state: state,
                      value: timeValue,
                      caption: timeCaption,
                      nextEvent: nextEvent,
                      progress: progress!,
                      progressLabel: progressLabel,
                    ),
                  ],
                  const SizedBox(height: 9),
                  MonthlyExpenseCard(
                    monthlyBudget: monthlyBudget,
                    monthlyRemaining: monthlyRemaining,
                    monthlySpent: monthlySpent,
                    usageRatio: monthlyUsageRatio,
                    remainingDays: remainingDays,
                    onSpendTap: onSpendTap,
                    onDetailsTap: onMonthlyDetailsTap,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class HaruSpendingTab extends StatelessWidget {
  const HaruSpendingTab({
    required this.remainingBudget,
    required this.spentAmount,
    required this.payday,
    required this.remainingDays,
    required this.reminder,
    required this.spends,
    required this.formatAmount,
    required this.formatDate,
    required this.onSpendTap,
    required this.onBudgetSettingsTap,
    super.key,
  });

  final String remainingBudget;
  final String spentAmount;
  final int payday;
  final int remainingDays;
  final String reminder;
  final List<DailySpend> spends;
  final String Function(int amount) formatAmount;
  final String Function(DateTime date) formatDate;
  final VoidCallback onSpendTap;
  final VoidCallback onBudgetSettingsTap;

  @override
  Widget build(BuildContext context) {
    final recentSpends = [...spends]..sort((a, b) => b.date.compareTo(a.date));

    return ListView(
      key: const Key('spending_tab'),
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
      children: [
        _SpendingSummaryCard(
          remainingBudget: remainingBudget,
          spentAmount: spentAmount,
          payday: payday,
          remainingDays: remainingDays,
          reminder: reminder,
          onSpendTap: onSpendTap,
          onBudgetSettingsTap: onBudgetSettingsTap,
        ),
        const SizedBox(height: 12),
        Container(
          key: const Key('spending_history'),
          padding: const EdgeInsets.fromLTRB(16, 15, 16, 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xffebe7f1)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '날짜별 지출 내역',
                style: TextStyle(
                  color: Color(0xff24222d),
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              if (recentSpends.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: Text(
                      '아직 기록된 지출이 없어요',
                      style: TextStyle(color: Color(0xff777382), fontSize: 13),
                    ),
                  ),
                )
              else
                for (final spend in recentSpends)
                  ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    visualDensity: const VisualDensity(vertical: -2),
                    title: Text(
                      formatDate(spend.date),
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    trailing: Text(
                      formatAmount(spend.amount),
                      style: const TextStyle(
                        color: Color(0xff24222d),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
            ],
          ),
        ),
      ],
    );
  }
}

class HaruTimeArea extends StatelessWidget {
  const HaruTimeArea({
    required this.now,
    required this.state,
    required this.value,
    required this.caption,
    this.nextEvent,
    required this.progress,
    this.progressLabel,
    super.key,
  });

  final DateTime now;
  final String state;
  final String value;
  final String caption;
  final String? nextEvent;
  final double progress;
  final String? progressLabel;

  @override
  Widget build(BuildContext context) {
    return WorkProgressCard(
      now: now,
      state: state,
      value: value,
      caption: caption,
      nextEvent: nextEvent,
      progress: progress,
      progressLabel: progressLabel,
    );
  }
}

class _SpendingSummaryCard extends StatelessWidget {
  const _SpendingSummaryCard({
    required this.remainingBudget,
    required this.spentAmount,
    required this.payday,
    required this.remainingDays,
    required this.reminder,
    required this.onSpendTap,
    required this.onBudgetSettingsTap,
  });

  final String remainingBudget;
  final String spentAmount;
  final int payday;
  final int remainingDays;
  final String reminder;
  final VoidCallback onSpendTap;
  final VoidCallback onBudgetSettingsTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('spending_summary'),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xffeeeafa),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '이번 달 남은 생활비',
            style: TextStyle(
              color: Color(0xff6657b5),
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              remainingBudget,
              style: const TextStyle(
                color: Color(0xff24222d),
                fontSize: 36,
                height: 1,
                fontWeight: FontWeight.w800,
                letterSpacing: -1.5,
              ),
            ),
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              Expanded(child: _MoneyFact(label: '누적 사용', value: spentAmount)),
              Expanded(child: _MoneyFact(label: '월급날', value: '매달 $payday일')),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '다음 월급날까지 $remainingDays일 · 지출 확인 $reminder',
            style: const TextStyle(color: Color(0xff777382), fontSize: 12),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: FilledButton.tonalIcon(
                  key: const Key('spending_tab_add_spend'),
                  onPressed: onSpendTap,
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('지출 입력'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(40),
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  key: const Key('open_budget_settings'),
                  onPressed: onBudgetSettingsTap,
                  icon: const Icon(Icons.tune_rounded, size: 17),
                  label: const Text('생활비 설정'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(40),
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MoneyFact extends StatelessWidget {
  const _MoneyFact({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: Color(0xff777382), fontSize: 12),
        ),
        const SizedBox(height: 4),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            value,
            style: const TextStyle(
              color: Color(0xff24222d),
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}
