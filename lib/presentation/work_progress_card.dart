import 'package:flutter/material.dart';

import '../domain/content/dayve_progress_copy.dart';
import 'dayve_design_tokens.dart';
import 'pixel_cat_progress_gauge.dart';

class WorkProgressCard extends StatelessWidget {
  const WorkProgressCard({
    required this.state,
    required this.value,
    required this.caption,
    required this.progress,
    required this.now,
    this.nextEvent,
    this.progressLabel,
    super.key,
  });

  final String state;
  final String value;
  final String caption;
  final String? nextEvent;
  final double progress;
  final DateTime now;
  final String? progressLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      key: const Key('day_progress_card'),
      label: '$state $caption $value',
      child: Container(
        key: const Key('work_progress_card'),
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 13),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(27),
          border: Border.all(color: DayveColors.border),
          boxShadow: [
            BoxShadow(
              color: const Color(0xff6450a0).withValues(alpha: .055),
              blurRadius: 22,
              offset: const Offset(0, 7),
            ),
          ],
        ),
        child: PixelCatProgressGauge(
          progress: progress,
          label: progressLabel ?? '오늘의 하루 진행률',
          topTrailingLabel: state == '퇴근 후'
              ? '내 시간 보내는 중'
              : DayveProgressCopy.workingTrailing(now),
          leadingLabel: state == '퇴근 후'
              ? '오늘도 수고했어요!'
              : DayveProgressCopy.workingLeading(now),
          trailingLabel:
              state == '퇴근 후' ? '$caption $value' : '오늘도 좋은 하루가 될 거예요 ♥',
        ),
      ),
    );
  }
}
