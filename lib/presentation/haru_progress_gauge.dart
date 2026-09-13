import 'package:flutter/material.dart';

class HaruProgressGauge extends StatelessWidget {
  const HaruProgressGauge({
    required this.progress,
    required this.label,
    super.key,
  });

  final double progress;
  final String label;

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
                height: 40,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    const petSize = 30.0;
                    final fillWidth = constraints.maxWidth * value;
                    final petTravel = (constraints.maxWidth - petSize).clamp(
                      0.0,
                      double.infinity,
                    );
                    final petLeft = (fillWidth - petSize / 2).clamp(
                      0.0,
                      petTravel,
                    );

                    return Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Positioned(
                          top: 22,
                          left: 0,
                          right: 0,
                          child: Container(
                            height: 12,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: .72),
                              borderRadius: BorderRadius.circular(99),
                            ),
                          ),
                        ),
                        Positioned(
                          top: 22,
                          left: 0,
                          child: Container(
                            height: 12,
                            width: fillWidth,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xff8e7cdc), Color(0xff6555b6)],
                              ),
                              borderRadius: BorderRadius.circular(99),
                            ),
                          ),
                        ),
                        Positioned(
                          key: const Key('haru_pixel_pet'),
                          top: 0,
                          left: petLeft,
                          child: child!,
                        ),
                      ],
                    );
                  },
                ),
              );
            },
            child: const CustomPaint(
              size: Size(30, 30),
              painter: _PixelCatPainter(),
            ),
          ),
          Row(
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: Color(0xff6657b5),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Text(
                '$percentage%',
                style: const TextStyle(
                  color: Color(0xff4f4a59),
                  fontSize: 12,
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

class _PixelCatPainter extends CustomPainter {
  const _PixelCatPainter();

  static const _pixel = 3.0;

  @override
  void paint(Canvas canvas, Size size) {
    const body = Color(0xff6657b5);
    const light = Color(0xffad9fe2);
    const dark = Color(0xff302a4c);

    void pixels(Color color, List<Rect> blocks) {
      final paint = Paint()..color = color;
      for (final block in blocks) {
        canvas.drawRect(
          Rect.fromLTWH(
            block.left * _pixel,
            block.top * _pixel,
            block.width * _pixel,
            block.height * _pixel,
          ),
          paint,
        );
      }
    }

    pixels(body, const [
      Rect.fromLTWH(1, 4, 1, 3),
      Rect.fromLTWH(0, 3, 1, 2),
      Rect.fromLTWH(2, 4, 5, 4),
      Rect.fromLTWH(5, 2, 4, 5),
      Rect.fromLTWH(5, 1, 1, 2),
      Rect.fromLTWH(8, 1, 1, 2),
      Rect.fromLTWH(3, 8, 1, 1),
      Rect.fromLTWH(6, 8, 1, 1),
      Rect.fromLTWH(9, 6, 1, 2),
    ]);
    pixels(light, const [
      Rect.fromLTWH(3, 5, 2, 2),
      Rect.fromLTWH(6, 3, 2, 2),
    ]);
    pixels(dark, const [
      Rect.fromLTWH(8, 3, 1, 1),
      Rect.fromLTWH(9, 5, 1, 1),
    ]);
  }

  @override
  bool shouldRepaint(covariant _PixelCatPainter oldDelegate) => false;
}
