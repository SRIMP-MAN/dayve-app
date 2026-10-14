class DayveProgressCopy {
  const DayveProgressCopy._();

  static String workingLeading(DateTime now) =>
      now.hour < 12 ? '좋은 아침이에요!' : '오전은 수고했어요!';

  static String workingTrailing(DateTime now) =>
      now.hour < 12 ? '오전도 화이팅!' : '오후도 화이팅!';
}
