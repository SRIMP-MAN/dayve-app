import 'package:flutter_test/flutter_test.dart';
import 'package:haru_app/domain/content/dayve_daily_messages.dart';
import 'package:haru_app/domain/services/day_background_resolver.dart';
import 'package:haru_app/domain/services/dayve_message_selector.dart';

void main() {
  const selector = DayveMessageSelector();
  const periods = DayPeriod.values;

  test('same date and period always select the same message', () {
    final date = DateTime(2026, 9, 15, 8, 30);

    for (final period in periods) {
      final first = selector.selectDailyMessage(date: date, period: period);
      final second = selector.selectDailyMessage(
        date: DateTime(2026, 9, 15, 23, 59),
        period: period,
      );
      expect(second, first);
    }
  });

  test('changing the date advances the selected index', () {
    final first = selector.selectDailyMessage(
      date: DateTime(2026, 1, 1),
      period: DayPeriod.morning,
    );
    final second = selector.selectDailyMessage(
      date: DateTime(2026, 1, 2),
      period: DayPeriod.morning,
    );

    expect(second, isNot(first));
  });

  test('each period owns a separate pool of twenty messages', () {
    expect(dayveMorningMessages, hasLength(20));
    expect(dayveDayMessages, hasLength(20));
    expect(dayveEveningMessages, hasLength(20));
    expect(dayveNightMessages, hasLength(20));

    for (final period in periods) {
      final current = dayveMessagesFor(period).toSet();
      for (final other in periods.where((value) => value != period)) {
        expect(current.intersection(dayveMessagesFor(other).toSet()), isEmpty);
      }
    }
  });

  test('selection always stays inside its non-empty period pool', () {
    for (final period in periods) {
      final pool = dayveMessagesFor(period);
      for (var day = 0; day < 370; day += 1) {
        final message = selector.selectDailyMessage(
          date: DateTime(2026, 1, 1).add(Duration(days: day)),
          period: period,
        );
        expect(pool, contains(message));
        expect(message.trim(), isNotEmpty);
      }
    }
  });

  test('year end and new year are handled without an invalid index', () {
    for (final date in [DateTime(2026, 12, 31), DateTime(2027, 1, 1)]) {
      for (final period in periods) {
        expect(
          () => selector.selectDailyMessage(date: date, period: period),
          returnsNormally,
        );
      }
    }
  });
}
