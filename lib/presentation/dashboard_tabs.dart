import 'package:flutter/material.dart';

import '../domain/models/daily_spend.dart';
import 'haru_progress_gauge.dart';

class HaruTodayTab extends StatelessWidget {
  const HaruTodayTab({
    required this.dateLabel,
    required this.state,
    required this.timeValue,
    required this.timeCaption,
    required this.recommendedBudget,
    required this.onScheduleTap,
    required this.onSpendTap,
    this.nextEvent,
    this.progress,
    this.progressLabel,
    this.overrideLabel,
    super.key,
  });

  final String dateLabel;
  final String state;
  final String timeValue;
  final String timeCaption;
  final String recommendedBudget;
  final String? nextEvent;
  final double? progress;
  final String? progressLabel;
  final String? overrideLabel;
  final VoidCallback onScheduleTap;
  final VoidCallback onSpendTap;

  @override
  Widget build(BuildContext context) {
    return ListView(
      key: const Key('today_tab'),
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
      children: [
        Text(
          dateLabel,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: const Color(0xff777382),
              ),
        ),
        const SizedBox(height: 10),
        HaruTimeArea(
          state: state,
          value: timeValue,
          caption: timeCaption,
          nextEvent: nextEvent,
          progress: progress,
          progressLabel: progressLabel,
          overrideLabel: overrideLabel,
          onScheduleTap: onScheduleTap,
        ),
        const SizedBox(height: 12),
        _TodayBudgetCard(
          recommended: recommendedBudget,
          onSpendTap: onSpendTap,
        ),
      ],
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
    required this.state,
    required this.value,
    required this.caption,
    required this.onScheduleTap,
    this.nextEvent,
    this.progress,
    this.progressLabel,
    this.overrideLabel,
    super.key,
  });

  final String state;
  final String value;
  final String caption;
  final String? nextEvent;
  final double? progress;
  final String? progressLabel;
  final String? overrideLabel;
  final VoidCallback onScheduleTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xffe9e3fa),
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        key: const Key('dashboard_time_area'),
        onTap: onScheduleTap,
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'HARU · $state',
                    style: const TextStyle(
                      color: Color(0xff6657b5),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const Spacer(),
                  const Icon(
                    Icons.edit_calendar_outlined,
                    size: 20,
                    color: Color(0xff6657b5),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Text(
                caption,
                style: const TextStyle(
                  color: Color(0xff4f4a59),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 5),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  value,
                  style: const TextStyle(
                    color: Color(0xff24222d),
                    fontSize: 40,
                    height: 1,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -1.5,
                  ),
                ),
              ),
              if (progress != null) ...[
                const SizedBox(height: 14),
                HaruProgressGauge(
                  progress: progress!,
                  label: progressLabel!,
                ),
              ],
              const SizedBox(height: 10),
              Row(
                children: [
                  if (overrideLabel != null)
                    Expanded(
                      child: Text(
                        overrideLabel!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xff6657b5),
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    )
                  else
                    const Spacer(),
                  if (nextEvent != null)
                    Text(
                      nextEvent!,
                      style: const TextStyle(
                        color: Color(0xff777382),
                        fontSize: 12,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TodayBudgetCard extends StatelessWidget {
  const _TodayBudgetCard({
    required this.recommended,
    required this.onSpendTap,
  });

  final String recommended;
  final VoidCallback onSpendTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('dashboard_money_area'),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xffebe7f1)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '오늘 써도 되는 돈',
                  style: TextStyle(
                    color: Color(0xff6657b5),
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 5),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    recommended,
                    style: const TextStyle(
                      color: Color(0xff24222d),
                      fontSize: 27,
                      height: 1,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -1,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          FilledButton.tonalIcon(
            key: const Key('open_spend_sheet'),
            onPressed: onSpendTap,
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('지출 입력'),
            style: FilledButton.styleFrom(
              minimumSize: const Size(0, 40),
              padding: const EdgeInsets.symmetric(horizontal: 13),
              visualDensity: VisualDensity.compact,
            ),
          ),
        ],
      ),
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
