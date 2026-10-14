import 'package:flutter_test/flutter_test.dart';
import 'package:haru_app/domain/models/weather_snapshot.dart';
import 'package:haru_app/domain/services/day_background_resolver.dart';

void main() {
  const resolver = DayBackgroundResolver();

  test('autumn fallback maps the four supplied assets deterministically', () {
    final cases = <(DateTime, DayPeriod, String)>[
      (
        DateTime(2026, 9, 15, 6),
        DayPeriod.morning,
        'assets/day_backgrounds/morning.png',
      ),
      (
        DateTime(2026, 9, 15, 12),
        DayPeriod.day,
        'assets/day_backgrounds/day.png',
      ),
      (
        DateTime(2026, 9, 15, 18),
        DayPeriod.evening,
        'assets/day_backgrounds/evening.png',
      ),
      (
        DateTime(2026, 9, 15, 21),
        DayPeriod.night,
        'assets/day_backgrounds/night.png',
      ),
    ];

    for (final (now, period, asset) in cases) {
      final state = resolver.resolve(now: now);
      expect(state.period, period);
      expect(state.assetPath, asset);
    }
  });

  test('seasonal fallback changes morning and evening boundaries', () {
    expect(
      resolver.resolve(now: DateTime(2026, 7, 1, 5, 30)).period,
      DayPeriod.morning,
    );
    expect(
      resolver.resolve(now: DateTime(2026, 7, 1, 19, 30)).period,
      DayPeriod.evening,
    );
    expect(
      resolver.resolve(now: DateTime(2026, 1, 1, 6, 30)).period,
      DayPeriod.night,
    );
    expect(
      resolver.resolve(now: DateTime(2026, 1, 1, 17)).period,
      DayPeriod.evening,
    );
  });

  test('fresh sunrise and sunset data override seasonal fallback', () {
    final now = DateTime(2026, 7, 1, 18);
    final weather = WeatherSnapshot(
      condition: WeatherCondition.clear,
      temperature: 27,
      sunrise: DateTime(2026, 7, 1, 5, 40),
      sunset: DateTime(2026, 7, 1, 18, 40),
      updatedAt: DateTime(2026, 7, 1, 17, 50),
    );

    final state = resolver.resolve(now: now, weather: weather);

    expect(state.period, DayPeriod.evening);
    expect(state.nextTransitionAt, DateTime(2026, 7, 1, 19, 10));
    expect(state.weatherMessage, '오늘도 햇살 좋은 하루');
  });

  test('stale weather is ignored and offline time fallback remains valid', () {
    final now = DateTime(2026, 9, 15, 12);
    final stale = WeatherSnapshot(
      condition: WeatherCondition.rain,
      sunrise: DateTime(2026, 9, 15, 9),
      sunset: DateTime(2026, 9, 15, 12),
      updatedAt: DateTime(2026, 9, 15, 8),
    );

    final state = resolver.resolve(now: now, weather: stale);

    expect(state.period, DayPeriod.day);
    expect(state.weatherCondition, WeatherCondition.unknown);
    expect(state.weatherOverlayOpacity, 0);
    expect(state.nextTransitionAt, DateTime(2026, 9, 15, 17, 30));
  });

  test('weather overlay remains lightweight and does not replace the asset',
      () {
    final now = DateTime(2026, 9, 15, 12);
    final rainy = WeatherSnapshot(
      condition: WeatherCondition.rain,
      updatedAt: now,
    );

    final state = resolver.resolve(now: now, weather: rainy);

    expect(state.assetPath, 'assets/day_backgrounds/day.png');
    expect(state.weatherOverlayOpacity, .18);
    expect(state.weatherMessage, '빗소리와 천천히 가요');
  });
}
