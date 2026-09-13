import 'package:flutter/material.dart';

import 'dayve_design_tokens.dart';
import 'pixel_cat_progress_gauge.dart';

class WorkProgressCard extends StatelessWidget {
  const WorkProgressCard({
    required this.state,
    required this.value,
    required this.caption,
    required this.onTap,
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
  final VoidCallback onTap;

  bool get _isDayOff => state == '휴무';

  @override
  Widget build(BuildContext context) {
    final activeProgress = _isDayOff ? null : progress;

    return Container(
      key: const Key('work_progress_card'),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(DayveRadii.large),
        boxShadow: _isDayOff
            ? const []
            : [
                BoxShadow(
                  color: const Color(0xff4b3c82).withValues(alpha: .08),
                  blurRadius: 30,
                  offset: const Offset(0, 8),
                ),
              ],
      ),
      child: Material(
        color: _isDayOff ? DayveColors.backgroundSoft : DayveColors.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DayveRadii.large),
          side: BorderSide(
            color: _isDayOff
                ? DayveColors.lightPurple.withValues(alpha: .45)
                : DayveColors.border,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          key: const Key('dashboard_time_area'),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              DayveSpacing.lg,
              DayveSpacing.lg,
              DayveSpacing.lg,
              DayveSpacing.md,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'DAYVE · $state',
                      style: const TextStyle(
                        color: DayveColors.primaryPurple,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        letterSpacing: .15,
                      ),
                    ),
                    const Spacer(),
                    const Icon(
                      Icons.edit_calendar_outlined,
                      size: 19,
                      color: DayveColors.primaryPurple,
                    ),
                  ],
                ),
                const SizedBox(height: DayveSpacing.lg),
                if (!_isDayOff) ...[
                  const Text(
                    '오늘의 일과',
                    style: TextStyle(
                      color: DayveColors.primaryText,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: DayveSpacing.sm),
                  Text(
                    caption,
                    style: const TextStyle(
                      color: DayveColors.secondaryText,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: DayveSpacing.xs),
                ],
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    _isDayOff ? '휴무' : value,
                    style: const TextStyle(
                      color: DayveColors.primaryText,
                      fontSize: 42,
                      height: .98,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -1.8,
                    ),
                  ),
                ),
                if (_isDayOff) ...[
                  const SizedBox(height: DayveSpacing.xs),
                  const Text(
                    '오늘은 쉬어도 괜찮아요',
                    style: TextStyle(
                      color: DayveColors.secondaryText,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
                if (activeProgress != null) ...[
                  const SizedBox(height: DayveSpacing.md),
                  PixelCatProgressGauge(
                    progress: activeProgress,
                    label: progressLabel ?? caption,
                  ),
                ],
                if (overrideLabel != null || nextEvent != null) ...[
                  const SizedBox(height: DayveSpacing.sm),
                  Row(
                    children: [
                      if (overrideLabel != null)
                        Expanded(
                          child: Text(
                            overrideLabel!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: DayveColors.primaryPurple,
                              fontSize: 11,
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
                            color: DayveColors.secondaryText,
                            fontSize: 11,
                          ),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
