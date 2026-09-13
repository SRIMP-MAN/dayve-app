import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'dayve_design_tokens.dart';

double pixelCatLeftFor({
  required double width,
  required double catWidth,
  required double progress,
  double pawAnchor = .84,
}) {
  final travel = math.max(0.0, width - catWidth);
  final fillEnd = width * progress.clamp(0.0, 1.0);
  return (fillEnd - catWidth * pawAnchor).clamp(0.0, travel);
}

class PixelCatProgressGauge extends StatelessWidget {
  const PixelCatProgressGauge({
    required this.progress,
    required this.label,
    this.leadingLabel,
    this.trailingLabel,
    super.key,
  });

  final double progress;
  final String label;
  final String? leadingLabel;
  final String? trailingLabel;

  @override
  Widget build(BuildContext context) {
    final normalized = progress.clamp(0.0, 1.0);
    final percentage = (normalized * 100).round();

    return Semantics(
      label: label,
      value: '$percentage%',
      child: Column(
        children: [
          TweenAnimationBuilder<double>(
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeOutCubic,
            tween: Tween<double>(end: normalized),
            builder: (context, value, child) {
              return SizedBox(
                key: const Key('pixel_cat_progress_track'),
                height: 70,
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
                          bottom: 7,
                          height: 20,
                          child: CustomPaint(
                            painter: _SegmentedProgressPainter(value),
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
              'assets/images/dayve_pixel_cat.png',
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
                  leadingLabel ?? label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: DayveColors.secondaryText,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: DayveSpacing.xs),
              Text(
                trailingLabel ?? '$percentage%',
                style: const TextStyle(
                  color: DayveColors.primaryPurple,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
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
  const _SegmentedProgressPainter(this.progress);

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    const segmentCount = 16;
    const gap = 3.0;
    final segmentWidth = (size.width - gap * (segmentCount - 1)) / segmentCount;
    final activeWidth = size.width * progress.clamp(0.0, 1.0);
    final shader = const LinearGradient(
      colors: [DayveColors.progressStart, DayveColors.progressEnd],
    ).createShader(Offset.zero & size);

    for (var index = 0; index < segmentCount; index += 1) {
      final left = index * (segmentWidth + gap);
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(left, 0, segmentWidth, size.height),
        const Radius.circular(5),
      );
      canvas.drawRRect(rect, Paint()..color = DayveColors.border);
      final filled = (activeWidth - left).clamp(0.0, segmentWidth);
      if (filled > 0) {
        canvas.save();
        canvas.clipRRect(rect);
        canvas.drawRect(
          Rect.fromLTWH(left, 0, filled, size.height),
          Paint()..shader = shader,
        );
        canvas.restore();
      }
    }
  }

  @override
  bool shouldRepaint(covariant _SegmentedProgressPainter oldDelegate) =>
      oldDelegate.progress != progress;
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
