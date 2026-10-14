import '../content/dayve_daily_messages.dart';
import 'day_background_resolver.dart';

class DayveMessageSelector {
  const DayveMessageSelector();

  String selectDailyMessage({
    required DateTime date,
    required DayPeriod period,
  }) {
    final messages = dayveMessagesFor(period);
    final localDate = DateTime(date.year, date.month, date.day);
    final firstDayOfYear = DateTime(date.year);
    final dayIndex = localDate.difference(firstDayOfYear).inDays;
    return messages[dayIndex % messages.length];
  }
}

String selectDailyMessage({
  required DateTime date,
  required DayPeriod period,
}) =>
    const DayveMessageSelector().selectDailyMessage(
      date: date,
      period: period,
    );
