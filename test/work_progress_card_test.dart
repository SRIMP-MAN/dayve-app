import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:haru_app/presentation/work_progress_card.dart';

void main() {
  Future<void> pumpCard(
    WidgetTester tester, {
    required String state,
    required double progress,
    DateTime? now,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 360,
            child: WorkProgressCard(
              now: now ?? DateTime(2026, 9, 16, 10, 14),
              state: state,
              value: '2시간 14분',
              caption: state == '퇴근 후' ? '취침까지' : '퇴근까지',
              progress: progress,
              progressLabel: '오늘의 하루 진행률',
              nextEvent: '18:00 퇴근',
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

    expect(find.text('오늘의 하루 진행률'), findsOneWidget);
    expect(find.text('좋은 아침이에요!'), findsOneWidget);
    expect(find.text('오전도 화이팅!'), findsOneWidget);
    expect(find.byKey(const Key('pixel_cat_progress_track')), findsOneWidget);
    expect(find.byKey(const Key('dayve_pixel_cat')), findsOneWidget);
  });

  testWidgets('working card switches to afternoon copy after noon',
      (tester) async {
    await pumpCard(
      tester,
      state: '근무 중',
      progress: .5,
      now: DateTime(2026, 9, 16, 14),
    );

    expect(find.text('오전은 수고했어요!'), findsOneWidget);
    expect(find.text('오후도 화이팅!'), findsOneWidget);
  });

  testWidgets('after-work card shows a fresh progress gauge', (tester) async {
    await pumpCard(tester, state: '퇴근 후', progress: .31);

    expect(find.text('31%'), findsOneWidget);
    expect(find.byKey(const Key('dayve_pixel_cat')), findsOneWidget);
  });
}
