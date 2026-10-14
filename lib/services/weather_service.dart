import '../domain/models/weather_snapshot.dart';

abstract interface class WeatherService {
  Future<WeatherSnapshot?> loadCached();

  Future<WeatherSnapshot?> refresh();
}

/// Default offline implementation. DAYVE remains fully functional without
/// location permission, a weather account, or a network connection.
class TimeOnlyWeatherService implements WeatherService {
  const TimeOnlyWeatherService();

  @override
  Future<WeatherSnapshot?> loadCached() async => null;

  @override
  Future<WeatherSnapshot?> refresh() async => null;
}
