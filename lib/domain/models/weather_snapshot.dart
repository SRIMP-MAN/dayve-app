enum WeatherCondition {
  clear,
  partlyCloudy,
  cloudy,
  rain,
  snow,
  fog,
  unknown,
}

class WeatherSnapshot {
  const WeatherSnapshot({
    required this.condition,
    required this.updatedAt,
    this.temperature,
    this.sunrise,
    this.sunset,
  });

  final double? temperature;
  final WeatherCondition condition;
  final DateTime? sunrise;
  final DateTime? sunset;
  final DateTime updatedAt;

  bool isFreshAt(
    DateTime now, {
    Duration maxAge = const Duration(minutes: 60),
  }) {
    final age = now.difference(updatedAt);
    return !age.isNegative && age <= maxAge;
  }

}
