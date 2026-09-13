import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:haru_app/presentation/haru_progress_gauge.dart';
import 'package:haru_app/presentation/pixel_cat_progress_gauge.dart';

void main() {
  testWidgets('progress gauge shows percentage and pixel pet', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 300,
              child: HaruProgressGauge(
                progress: 0.5,
                label: '근무 진행',
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('근무 진행'), findsOneWidget);
    expect(find.text('50%'), findsOneWidget);
    expect(find.byKey(const Key('haru_pixel_pet')), findsOneWidget);
    final image = tester.widget<Image>(
      find.byKey(const Key('dayve_pixel_cat_image')),
    );
    expect(image.image, isA<AssetImage>());
    expect(image.filterQuality, FilterQuality.none);
    expect(tester.takeException(), isNull);
  });

  testWidgets('progress gauge clamps values to its visible range',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: HaruProgressGauge(progress: 2, label: '자유시간 진행'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('100%'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  test('pixel cat position stays inside both ends of the gauge', () {
    expect(pixelCatLeftFor(width: 300, catWidth: 46, progress: -1), 0);
    expect(
      pixelCatLeftFor(width: 300, catWidth: 46, progress: 0.5),
      closeTo(111.36, .001),
    );
    expect(pixelCatLeftFor(width: 300, catWidth: 46, progress: 2), 254);
  });
}
