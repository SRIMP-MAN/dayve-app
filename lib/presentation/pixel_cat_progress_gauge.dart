import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'dayve_design_tokens.dart';

double pixelCatLeftFor({
  required double width,
  required double catWidth,
  required double progress,
  double pawAnchor = .84,
  double earlyOffset = 12,
}) {
  final normalized = progress.clamp(0.0, 1.0);
  final travel = math.max(0.0, width - catWidth);
  final fillEnd = width * normalized;
  final anchoredLeft = (fillEnd - catWidth * pawAnchor).clamp(0.0, travel);

  // At the very start the normal left clamp makes the cat's paw appear ahead
  // of the short fill. Ease a small correction out over the first 10% only.
  final earlyProgress = (normalized / .10).clamp(0.0, 1.0);
  final correction = earlyOffset * (1 - earlyProgress);
  return (anchoredLeft - correction).clamp(-earlyOffset, travel);
}

class PixelCatProgressGauge extends StatelessWidget {
  const PixelCatProgressGauge({
    required this.progress,
    required this.label,
    this.catAsset = 'assets/images/dayve_pixel_cat.png',
    this.segmentCount = 10,
    this.activeGradient = const LinearGradient(
      colors: [
        Color(0xffa586f3),
        Color(0xffb798f6),
        Color(0xffa9bdf8),
        Color(0xff8bcdf2),
      ],
    ),
    this.inactiveColor = DayveColors.inactiveTrack,
    this.leadingLabel,
    this.trailingLabel,
    this.topTrailingLabel,
    super.key,
  });

  final double progress;
  final String label;
  final String catAsset;
  final int segmentCount;
  final LinearGradient activeGradient;
  final Color inactiveColor;
  final String? leadingLabel;
  final String? trailingLabel;
  final String? topTrailingLabel;

  @override
  Widget build(BuildContext context) {
    final normalized = progress.clamp(0.0, 1.0);
    final percentage = (normalized * 100).round();

    return Semantics(
      label: label,
      value: '$percentage%',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(
                Icons.schedule_rounded,
                size: 18,
                color: DayveColors.primaryPurple,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Row(
                  children: [
                    Flexible(
                      child: Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: DayveColors.primaryPurple,
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(width: 5),
                    const Icon(
                      Icons.info_outline_rounded,
                      size: 16,
                      color: DayveColors.lightPurple,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: DayveSpacing.xs),
              Container(
                key: const Key('dayve_progress_badge'),
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: DayveColors.lightPurple.withValues(alpha: .28),
                  borderRadius: BorderRadius.circular(DayveRadii.progress),
                  border: Border.all(
                    color: DayveColors.lightPurple.withValues(alpha: .55),
                  ),
                ),
                child: Text(
                  '$percentage%',
                  style: const TextStyle(
                    color: DayveColors.primaryPurple,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (topTrailingLabel != null) ...[
                const SizedBox(width: 7),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xfff8f6ff),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    topTrailingLabel!,
                    style: const TextStyle(
                      color: DayveColors.secondaryText,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 4),
          TweenAnimationBuilder<double>(
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeOutCubic,
            tween: Tween<double>(end: normalized),
            builder: (context, value, child) {
              return SizedBox(
                key: const Key('pixel_cat_progress_track'),
                height: 66,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    // The supplied PNG includes transparent breathing room.
                    // A 74x64 canvas renders the visible cat at about 46px high.
                    const catCanvasWidth = 74.0;
                    final catLeft = pixelCatLeftFor(
                      width: constraints.maxWidth,
                      catWidth: catCanvasWidth,
                      progress: value,
                    );

                    return Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: 2,
                          height: 26,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: .9),
                              borderRadius: BorderRadius.circular(
                                DayveRadii.progress,
                              ),
                              border: Border.all(
                                color: const Color(0xffcbc3ee),
                                width: 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: DayveColors.primaryPurple
                                      .withValues(alpha: .13),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(3),
                              child: CustomPaint(
                                key: const Key('dayve_segmented_pill'),
                                painter: _SegmentedProgressPainter(
                                  progress: value,
                                  segmentCount: segmentCount,
                                  activeGradient: activeGradient,
                                  inactiveColor: inactiveColor,
                                ),
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          key: const Key('haru_pixel_pet'),
                          left: catLeft,
                          top: 0,
                          child: RepaintBoundary(
                            key: const Key('dayve_pixel_cat'),
                            child: child!,
                          ),
                        ),
                        if (value >= .999)
                          const Positioned(
                            right: 0,
                            top: 1,
                            child: _CompletionSpark(),
                          ),
                      ],
                    );
                  },
                ),
              );
            },
            child: Image.asset(
              catAsset,
              key: const Key('dayve_pixel_cat_image'),
              width: 74,
              height: 64,
              fit: BoxFit.contain,
              alignment: Alignment.bottomCenter,
              filterQuality: FilterQuality.none,
              isAntiAlias: false,
              gaplessPlayback: true,
            ),
          ),
          Row(
            children: [
              Expanded(
                child: Text(
                  leadingLabel ?? '오늘도 한 칸씩 가고 있어요',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: DayveColors.secondaryText,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: DayveSpacing.xs),
              Expanded(
                child: Text(
                  trailingLabel ?? '좋은 하루가 될 거예요',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.end,
                  style: const TextStyle(
                    color: DayveColors.secondaryText,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w500,
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

class _SegmentedProgressPainter extends CustomPainter {
  const _SegmentedProgressPainter({
    required this.progress,
    required this.segmentCount,
    required this.activeGradient,
    required this.inactiveColor,
  });

  final double progress;
  final int segmentCount;
  final LinearGradient activeGradient;
  final Color inactiveColor;

  @override
  void paint(Canvas canvas, Size size) {
    final safeSegmentCount = math.max(1, segmentCount);
    final activeWidth = size.width * progress.clamp(0.0, 1.0);
    final shader = activeGradient.createShader(Offset.zero & size);

    final track = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(size.height / 2),
    );
    canvas.drawRRect(track, Paint()..color = inactiveColor);

    if (activeWidth > 0) {
      canvas.save();
      canvas.clipRRect(track);
      canvas.drawRect(
        Rect.fromLTWH(0, 0, activeWidth, size.height),
        Paint()..shader = shader,
      );
      canvas.restore();
    }

    final dividerPaint = Paint()
      ..color = Colors.white.withValues(alpha: .82)
      ..strokeWidth = 2;
    for (var index = 1; index < safeSegmentCount; index += 1) {
      final x = size.width * index / safeSegmentCount;
      canvas.drawLine(
        Offset(x, 2),
        Offset(x, size.height - 2),
        dividerPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _SegmentedProgressPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.segmentCount != segmentCount ||
      oldDelegate.activeGradient != activeGradient ||
      oldDelegate.inactiveColor != inactiveColor;
}

class _CompletionSpark extends StatelessWidget {
  const _CompletionSpark();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 12,
      height: 14,
      child: Stack(
        children: [
          Positioned(
            left: 0,
            top: 5,
            child: ColoredBox(
              color: DayveColors.progressStart,
              child: SizedBox.square(dimension: 3),
            ),
          ),
          Positioned(
            right: 0,
            top: 0,
            child: ColoredBox(
              color: DayveColors.progressEnd,
              child: SizedBox.square(dimension: 3),
            ),
          ),
          Positioned(
            right: 2,
            bottom: 0,
            child: ColoredBox(
              color: DayveColors.lightPurple,
              child: SizedBox.square(dimension: 2),
            ),
          ),
        ],
      ),
    );
  }
}
