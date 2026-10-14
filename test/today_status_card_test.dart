import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:haru_app/presentation/today_status_card.dart';

void main() {
  testWidgets('day off status card follows the reference hierarchy',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TodayStatusCard(
            state: '휴무',
            value: '휴무',
            caption: '오늘은 쉬어도 괜찮아요',
            now: DateTime(2026, 9, 15, 18),
          ),
        ),
      ),
    );

    expect(find.byKey(const Key('today_status_card')), findsOneWidget);
    expect(find.text('DAYVE · 휴무'), findsOneWidget);
    expect(find.text('오늘은 쉬어도 괜찮아요'), findsOneWidget);
    expect(find.byKey(const Key('dayve_status_pill')), findsOneWidget);
    expect(find.textContaining('좋은 하루가'), findsNothing);
    expect(
      find.byKey(
        const ValueKey('assets/day_backgrounds/evening.png'),
      ),
      findsOneWidget,
    );
    expect(find.byKey(const Key('dayve_pixel_cat')), findsNothing);
  });

  testWidgets('hero uses the supplied 16 by 9 composition without distortion',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TodayStatusCard(
            state: '근무 중',
            value: '03시간 55분',
            caption: '퇴근까지',
            now: DateTime(2026, 9, 15, 13),
          ),
        ),
      ),
    );

    final background = tester.widget<Image>(
      find.byKey(const ValueKey('assets/day_backgrounds/day.png')),
    );
    expect(background.fit, BoxFit.cover);
    expect(
      tester
          .widget<AspectRatio>(
            find.byKey(const Key('dayve_hero_aspect_ratio')),
          )
          .aspectRatio,
      16 / 9,
    );
  });

  testWidgets('working status makes remaining time the hero copy',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TodayStatusCard(
            state: '근무 중',
            value: '03시간 55분',
            caption: '퇴근까지',
            now: DateTime(2026, 9, 15, 13),
          ),
        ),
      ),
    );

    expect(find.text('DAYVE · 근무 중'), findsOneWidget);
    expect(find.text('퇴근까지 03시간 55분'), findsOneWidget);
    expect(find.text('지금도 충분히 잘하고 있어요 💜'), findsOneWidget);
    expect(find.text('근무 중'), findsNothing);
    final dailyMessage = tester.widget<Text>(
      find.byKey(const Key('dayve_daily_message')),
    );
    expect(dailyMessage.data, isNotNull);
    expect(dailyMessage.data!.trim(), isNotEmpty);
    expect(dailyMessage.maxLines, 1);
    expect(dailyMessage.softWrap, isFalse);
  });

  testWidgets('hero switches among the four fixed time assets', (tester) async {
    Future<void> pumpAt(DateTime now, String asset) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TodayStatusCard(
              state: '근무 중',
              value: '4시간 22분',
              caption: '퇴근까지',
              now: now,
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 1000));
      expect(find.byKey(ValueKey(asset)), findsOneWidget);
    }

    await pumpAt(
      DateTime(2026, 9, 15, 8),
      'assets/day_backgrounds/morning.png',
    );
    await pumpAt(
      DateTime(2026, 9, 15, 13),
      'assets/day_backgrounds/day.png',
    );
    await pumpAt(
      DateTime(2026, 9, 15, 18),
      'assets/day_backgrounds/evening.png',
    );
    await pumpAt(
      DateTime(2026, 9, 15, 22),
      'assets/day_backgrounds/night.png',
    );
  });
}
