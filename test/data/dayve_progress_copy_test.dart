import 'package:flutter_test/flutter_test.dart';
import 'package:haru_app/domain/content/dayve_progress_copy.dart';

void main() {
  test('morning copy stays in the morning before noon', () {
    final now = DateTime(2026, 9, 16, 10, 14);

    expect(DayveProgressCopy.workingLeading(now), '좋은 아침이에요!');
    expect(DayveProgressCopy.workingTrailing(now), '오전도 화이팅!');
  });

  test('afternoon copy starts at noon', () {
    final now = DateTime(2026, 9, 16, 12);

    expect(DayveProgressCopy.workingLeading(now), '오전은 수고했어요!');
    expect(DayveProgressCopy.workingTrailing(now), '오후도 화이팅!');
  });
}
