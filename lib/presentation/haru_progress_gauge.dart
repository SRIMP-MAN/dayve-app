import 'package:flutter/material.dart';

import 'pixel_cat_progress_gauge.dart';

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
    return PixelCatProgressGauge(
      progress: progress,
      label: label,
    );
  }
}
