import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:haru_app/presentation/work_progress_card.dart';

void main() {
  Future<void> pumpCard(
    WidgetTester tester, {
    required String state,
    double? progress,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 360,
            child: WorkProgressCard(
              state: state,
              value: '2시간 14분',
              caption: state == '퇴근 후' ? '취침까지' : '퇴근까지',
              progress: progress,
              progressLabel: '오늘의 하루 진행률',
              nextEvent: '18:00 퇴근',
              onTap: () {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('working card shows the DAYVE progress signature',
      (tester) async {
    await pumpCard(tester, state: '근무 중', progress: .74);

    expect(find.text('DAYVE · 근무 중'), findsOneWidget);
    expect(find.byKey(const Key('pixel_cat_progress_track')), findsOneWidget);
    expect(find.byKey(const Key('dayve_pixel_cat')), findsOneWidget);
  });

  testWidgets('after-work card shows a fresh progress gauge', (tester) async {
    await pumpCard(tester, state: '퇴근 후', progress: .31);

    expect(find.text('DAYVE · 퇴근 후'), findsOneWidget);
    expect(find.text('31%'), findsOneWidget);
    expect(find.byKey(const Key('dayve_pixel_cat')), findsOneWidget);
  });

  testWidgets('day-off card hides progress and pixel cat', (tester) async {
    await pumpCard(tester, state: '휴무', progress: .5);

    expect(find.text('DAYVE · 휴무'), findsOneWidget);
    expect(find.text('휴무'), findsOneWidget);
    expect(find.byKey(const Key('pixel_cat_progress_track')), findsNothing);
    expect(find.byKey(const Key('dayve_pixel_cat')), findsNothing);
  });
}
