import '../models/weather_snapshot.dart';

enum DayPeriod { morning, day, evening, night }

class DayBackgroundState {
  const DayBackgroundState({
    required this.period,
    required this.assetPath,
    required this.nextTransitionAt,
    required this.weatherCondition,
    required this.weatherOverlayOpacity,
    required this.weatherMessage,
  });

  final DayPeriod period;
  final String assetPath;
  final DateTime nextTransitionAt;
  final WeatherCondition weatherCondition;
  final double weatherOverlayOpacity;
  final String weatherMessage;
}

class DayBackgroundResolver {
  const DayBackgroundResolver();

  DayBackgroundState resolve({
    required DateTime now,
    WeatherSnapshot? weather,
  }) {
    final freshWeather = weather?.isFreshAt(now) == true ? weather : null;
    final boundaries = _boundaries(now, freshWeather);
    final period = _periodAt(now, boundaries);
    final condition = freshWeather?.condition ?? WeatherCondition.unknown;

    return DayBackgroundState(
      period: period,
      assetPath: _assetFor(period),
      nextTransitionAt: _nextTransition(now, boundaries),
      weatherCondition: condition,
      weatherOverlayOpacity: _overlayOpacity(condition),
      weatherMessage: _weatherMessage(period, condition),
    );
  }

  _DayBoundaries _boundaries(DateTime now, WeatherSnapshot? weather) {
    final date = DateTime(now.year, now.month, now.day);
    final hasSolarData = weather?.sunrise != null &&
        weather?.sunset != null &&
        _sameDate(weather!.sunrise!, now) &&
        _sameDate(weather.sunset!, now);

    if (hasSolarData) {
      final sunrise = weather.sunrise!;
      final sunset = weather.sunset!;
      return _DayBoundaries(
        morningStart: sunrise,
        morningEnd: DateTime(now.year, now.month, now.day, 11),
        eveningStart: sunset.subtract(const Duration(minutes: 45)),
        nightStart: sunset.add(const Duration(minutes: 30)),
      );
    }

    final fallback = _seasonalFallback(now.month);
    return _DayBoundaries(
      morningStart: date.add(Duration(minutes: fallback.morningStartMinutes)),
      morningEnd: date.add(const Duration(hours: 11)),
      eveningStart: date.add(Duration(minutes: fallback.eveningStartMinutes)),
      nightStart: date.add(Duration(minutes: fallback.nightStartMinutes)),
    );
  }

  DayPeriod _periodAt(DateTime now, _DayBoundaries boundaries) {
    if (now.isBefore(boundaries.morningStart)) return DayPeriod.night;
    if (now.isBefore(boundaries.morningEnd)) return DayPeriod.morning;
    if (now.isBefore(boundaries.eveningStart)) return DayPeriod.day;
    if (now.isBefore(boundaries.nightStart)) return DayPeriod.evening;
    return DayPeriod.night;
  }

  DateTime _nextTransition(DateTime now, _DayBoundaries boundaries) {
    for (final boundary in [
      boundaries.morningStart,
      boundaries.morningEnd,
      boundaries.eveningStart,
      boundaries.nightStart,
    ]) {
      if (boundary.isAfter(now)) return boundary;
    }

    final tomorrow = now.add(const Duration(days: 1));
    final fallback = _seasonalFallback(tomorrow.month);
    return DateTime(tomorrow.year, tomorrow.month, tomorrow.day).add(
      Duration(minutes: fallback.morningStartMinutes),
    );
  }

  String _assetFor(DayPeriod period) => switch (period) {
        DayPeriod.morning => 'assets/day_backgrounds/morning.png',
        DayPeriod.day => 'assets/day_backgrounds/day.png',
        DayPeriod.evening => 'assets/day_backgrounds/evening.png',
        DayPeriod.night => 'assets/day_backgrounds/night.png',
      };

  _SeasonalFallback _seasonalFallback(int month) => switch (month) {
        >= 3 && <= 5 => const _SeasonalFallback(6 * 60, 18 * 60, 19 * 60 + 30),
        >= 6 && <= 8 => const _SeasonalFallback(5 * 60, 19 * 60, 20 * 60 + 30),
        >= 9 && <= 11 => const _SeasonalFallback(6 * 60, 17 * 60 + 30, 19 * 60),
        _ => const _SeasonalFallback(7 * 60, 16 * 60 + 30, 18 * 60),
      };

  double _overlayOpacity(WeatherCondition condition) => switch (condition) {
        WeatherCondition.clear => 0,
        WeatherCondition.partlyCloudy => .04,
        WeatherCondition.cloudy => .12,
        WeatherCondition.rain => .18,
        WeatherCondition.snow => .10,
        WeatherCondition.fog => .20,
        WeatherCondition.unknown => 0,
      };

  String _weatherMessage(
    DayPeriod period,
    WeatherCondition condition,
  ) {
    if (period == DayPeriod.night &&
        (condition == WeatherCondition.clear ||
            condition == WeatherCondition.unknown)) {
      return '오늘도 수고했어요';
    }
    return switch (condition) {
      WeatherCondition.clear => '오늘도 햇살 좋은 하루',
      WeatherCondition.partlyCloudy => '구름 사이로 천천히 가요',
      WeatherCondition.cloudy => '조금 흐려도 괜찮아요',
      WeatherCondition.rain => '빗소리와 천천히 가요',
      WeatherCondition.snow => '오늘은 조금 특별한 하루',
      WeatherCondition.fog => '서두르지 말고 천천히 가요',
      WeatherCondition.unknown => '',
    };
  }

  bool _sameDate(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

class _DayBoundaries {
  const _DayBoundaries({
    required this.morningStart,
    required this.morningEnd,
    required this.eveningStart,
    required this.nightStart,
  });

  final DateTime morningStart;
  final DateTime morningEnd;
  final DateTime eveningStart;
  final DateTime nightStart;
}

class _SeasonalFallback {
  const _SeasonalFallback(
    this.morningStartMinutes,
    this.eveningStartMinutes,
    this.nightStartMinutes,
  );

  final int morningStartMinutes;
  final int eveningStartMinutes;
  final int nightStartMinutes;
}
