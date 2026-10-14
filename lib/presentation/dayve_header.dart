import 'package:flutter/material.dart';

import 'dayve_design_tokens.dart';

class DayveHeader extends StatelessWidget {
  const DayveHeader({
    required this.dateLabel,
    required this.onSettingsTap,
    super.key,
  });

  final String dateLabel;
  final VoidCallback onSettingsTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 92,
      child: Stack(
        children: [
          Positioned.fill(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'DAYVE',
                  style: TextStyle(
                    color: DayveColors.primaryText,
                    fontSize: 28,
                    height: 1,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -1.15,
                  ),
                ),
                const SizedBox(height: 7),
                const Text(
                  '오늘도, 충분한 하루',
                  style: TextStyle(
                    color: DayveColors.lightText,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 1.7,
                  ),
                ),
                const Spacer(),
                Text(
                  dateLabel,
                  style: const TextStyle(
                    color: DayveColors.secondaryText,
                    fontSize: 16,
                    height: 1,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -.3,
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            right: -7,
            top: -7,
            child: IconButton(
              key: const Key('open_settings'),
              onPressed: onSettingsTap,
              tooltip: '설정',
              visualDensity: VisualDensity.compact,
              icon: const Icon(
                Icons.edit_calendar_outlined,
                size: 28,
                color: DayveColors.primaryText,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
