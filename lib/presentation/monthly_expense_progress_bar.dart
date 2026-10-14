import 'dart:math' as math;

import 'package:flutter/material.dart';

class MonthlyExpenseProgressBar extends StatelessWidget {
  const MonthlyExpenseProgressBar({
    required this.progress,
    this.segmentCount = 10,
    super.key,
  });

  final double progress;
  final int segmentCount;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      key: const Key('monthly_expense_progress'),
      height: 21,
      child: CustomPaint(
        painter: _MonthlyExpensePainter(
          progress: progress.clamp(0.0, 1.0),
          segmentCount: segmentCount,
        ),
      ),
    );
  }
}

class _MonthlyExpensePainter extends CustomPainter {
  const _MonthlyExpensePainter({
    required this.progress,
    required this.segmentCount,
  });

  final double progress;
  final int segmentCount;

  @override
  void paint(Canvas canvas, Size size) {
    final count = math.max(1, segmentCount);
    final track = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(size.height / 2),
    );
    canvas.drawRRect(track, Paint()..color = const Color(0xffe9e5f1));

    if (progress > 0) {
      canvas.save();
      canvas.clipRRect(track);
      canvas.drawRect(
        Rect.fromLTWH(0, 0, size.width * progress, size.height),
        Paint()
          ..shader = const LinearGradient(
            colors: [
              Color(0xffb08cff),
              Color(0xffc9a5ff),
              Color(0xfff1b4d0),
            ],
          ).createShader(Offset.zero & size),
      );
      canvas.restore();
    }

    final divider = Paint()
      ..color = Colors.white.withValues(alpha: .68)
      ..strokeWidth = 1.5;
    for (var index = 1; index < count; index += 1) {
      final x = size.width * index / count;
      canvas.drawLine(Offset(x, 2), Offset(x, size.height - 2), divider);
    }

    canvas.drawRRect(
      track,
      Paint()
        ..color = const Color(0xffd7d0f1)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.3,
    );
  }

  @override
  bool shouldRepaint(covariant _MonthlyExpensePainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.segmentCount != segmentCount;
}
