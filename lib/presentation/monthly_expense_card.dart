import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'dayve_design_tokens.dart';
import 'monthly_expense_progress_bar.dart';

class MonthlyExpenseCard extends StatelessWidget {
  const MonthlyExpenseCard({
    required this.monthlyBudget,
    required this.monthlySpent,
    required this.monthlyRemaining,
    required this.usageRatio,
    required this.remainingDays,
    required this.onSpendTap,
    required this.onDetailsTap,
    super.key,
  });

  final int monthlyBudget;
  final int monthlySpent;
  final int monthlyRemaining;
  final double usageRatio;
  final int remainingDays;
  final VoidCallback onSpendTap;
  final VoidCallback onDetailsTap;

  String _amount(int value) =>
      '${NumberFormat.decimalPattern('ko_KR').format(value)}원';

  @override
  Widget build(BuildContext context) {
    final normalized = usageRatio.clamp(0.0, 1.0);
    final usagePercent = (normalized * 100).round();

    return Container(
      key: const Key('dashboard_money_area'),
      padding: const EdgeInsets.fromLTRB(19, 19, 19, 19),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: DayveColors.border),
        boxShadow: [
          BoxShadow(
            color: const Color(0xff6450a0).withValues(alpha: .055),
            blurRadius: 24,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.account_balance_wallet_outlined,
                size: 20,
                color: DayveColors.primaryPurple,
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  '이번 달 소비 현황',
                  style: TextStyle(
                    color: DayveColors.primaryPurple,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -.35,
                  ),
                ),
              ),
              Container(
                key: const Key('monthly_usage_badge'),
                padding:
                    const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
                decoration: BoxDecoration(
                  color: const Color(0xfff1edff),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '이번 달 $usagePercent% 사용 중',
                  style: const TextStyle(
                    color: DayveColors.primaryPurple,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              _amount(monthlySpent),
              style: const TextStyle(
                color: DayveColors.primaryText,
                fontSize: 34,
                height: .96,
                fontWeight: FontWeight.w700,
                letterSpacing: -1.5,
              ),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '이번 달 예산 대비 사용량',
            style: TextStyle(
              color: DayveColors.secondaryText,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          MonthlyExpenseProgressBar(progress: normalized),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: MetricBlock(
                  label: '이번 달 예산',
                  value: _amount(monthlyBudget),
                ),
              ),
              Container(
                width: 1,
                height: 39,
                margin: const EdgeInsets.symmetric(horizontal: 18),
                color: DayveColors.divider,
              ),
              Expanded(
                child: MetricBlock(
                  label: '남은 예산',
                  value: _amount(monthlyRemaining),
                ),
              ),
            ],
          ),
          const SizedBox(height: 17),
          SoftPillButton(onPressed: onSpendTap),
          const SizedBox(height: 14),
          Row(
            children: [
              Text(
                '$remainingDays일 남음',
                style: const TextStyle(
                  color: DayveColors.secondaryText,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              GestureDetector(
                key: const Key('monthly_details_action'),
                behavior: HitTestBehavior.opaque,
                onTap: onDetailsTap,
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '이번 달 상세보기',
                        style: TextStyle(
                          color: DayveColors.secondaryText,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(width: 3),
                      Icon(
                        Icons.chevron_right_rounded,
                        size: 17,
                        color: DayveColors.secondaryText,
                      ),
                    ],
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

class MetricBlock extends StatelessWidget {
  const MetricBlock({
    required this.label,
    required this.value,
    super.key,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: DayveColors.secondaryText,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 4),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            value,
            style: const TextStyle(
              color: DayveColors.primaryText,
              fontSize: 18,
              height: 1,
              fontWeight: FontWeight.w800,
              letterSpacing: -.6,
            ),
          ),
        ),
      ],
    );
  }
}

class SoftPillButton extends StatelessWidget {
  const SoftPillButton({required this.onPressed, super.key});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '지출 입력 수정',
      child: GestureDetector(
        key: const Key('open_spend_sheet'),
        behavior: HitTestBehavior.opaque,
        onTap: onPressed,
        child: Container(
          height: 50,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xffeee8ff), Color(0xffdccfff)],
            ),
            borderRadius: BorderRadius.circular(999),
          ),
          child: const Text(
            '+  지출 입력 · 수정',
            style: TextStyle(
              color: Color(0xff5d4bcb),
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}
