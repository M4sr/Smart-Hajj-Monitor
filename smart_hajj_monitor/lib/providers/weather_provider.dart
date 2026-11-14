import 'package:flutter/material.dart';
import 'package:dio/dio.dart';

class WeatherProvider with ChangeNotifier {
  double _temperature = 42.0;
  double _apparentTemperature = 44.0;
  int _humidity = 15;
  double _windSpeed = 10.0;
  double _precipitation = 0.0;
  int _weatherCode = 0;
  int _isDay = 1;
  bool _isLoading = false;
  String? _errorMessage;

  double get temperature => _temperature;
  double get apparentTemperature => _apparentTemperature;
  int get humidity => _humidity;
  double get windSpeed => _windSpeed;
  double get precipitation => _precipitation;
  int get weatherCode => _weatherCode;
  int get isDay => _isDay;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  final Dio _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
  ));

  // WMO weather code mapping to Indonesian
  String get weatherCondition {
    switch (_weatherCode) {
      case 0:
        return 'Cerah';
      case 1:
      case 2:
      case 3:
        return 'Cerah Berawan';
      case 45:
      case 48:
        return 'Berkabut';
      case 51:
      case 53:
      case 55:
        return 'Gerimis Ringan';
      case 61:
      case 63:
      case 65:
        return 'Hujan';
      case 80:
      case 81:
      case 82:
        return 'Hujan Ringan / Sedang';
      case 95:
      case 96:
      case 99:
        return 'Hujan Badai';
      default:
        return _temperature >= 35.0 ? 'Cuaca Sangat Panas' : 'Cerah Berawan';
    }
  }

  // Dynamic health advice based on actual temperature
  String get healthAdvice {
    if (_temperature >= 40.0) {
      return 'Cuaca ekstrem panas (${_temperature.toStringAsFixed(1)}°C). Batasi aktivitas di luar, selalu gunakan payung/topi, semprotkan air ke wajah, dan wajib minum 2-3 gelas air setiap jam guna mencegah sengatan panas (heatstroke).';
    } else if (_temperature >= 35.0) {
      return 'Suhu panas (${_temperature.toStringAsFixed(1)}°C). Gunakan tabir surya/payung saat di luar tenda, dan pastikan minum air minimal 2 gelas air setiap jam untuk menghindari kelelahan panas.';
    } else if (_temperature >= 30.0) {
      return 'Suhu hangat (${_temperature.toStringAsFixed(1)}°C). Jaga hidrasi dengan minum air secara rutin dan hindari berada di bawah terik matahari langsung terlalu lama.';
    } else {
      return 'Suhu bersahabat (${_temperature.toStringAsFixed(1)}°C). Tetap konsumsi air putih secukupnya dan jaga kesehatan fisik untuk persiapan ibadah selanjutnya.';
    }
  }

  // Calculate Dehydration Risk Level
  String get dehydrationRisk {
    if (_temperature >= 40.0) {
      return 'Ekstrem';
    } else if (_temperature >= 35.0) {
      return 'Tinggi';
    } else if (_temperature >= 30.0) {
      return 'Sedang';
    } else {
      return 'Rendah';
    }
  }

  Color get dehydrationRiskColor {
    if (_temperature >= 40.0) {
      return Colors.red.shade700;
    } else if (_temperature >= 35.0) {
      return Colors.orange.shade700;
    } else if (_temperature >= 30.0) {
      return Colors.amber.shade700;
    } else {
      return Colors.green.shade700;
    }
  }

  // Dynamic Icon mapping
  IconData get weatherIcon {
    switch (_weatherCode) {
      case 0:
        return _isDay == 1 ? Icons.wb_sunny_rounded : Icons.nights_stay_rounded;
      case 1:
      case 2:
      case 3:
        return _isDay == 1 ? Icons.wb_cloudy_rounded : Icons.cloud_queue_rounded;
      case 45:
      case 48:
        return Icons.foggy;
      case 51:
      case 53:
      case 55:
      case 61:
      case 63:
      case 65:
      case 80:
      case 81:
      case 82:
        return Icons.umbrella_rounded;
      case 95:
      case 96:
      case 99:
        return Icons.thunderstorm_rounded;
      default:
        return Icons.wb_sunny_rounded;
    }
  }

  // Dynamic Icon Color
  Color get iconColor {
    switch (_weatherCode) {
      case 0:
        return _isDay == 1 ? Colors.amber.shade700 : Colors.indigo.shade300;
      case 1:
      case 2:
      case 3:
        return Colors.blueGrey.shade400;
      case 51:
      case 53:
      case 55:
      case 61:
      case 63:
      case 65:
      case 80:
      case 81:
      case 82:
        return Colors.blue.shade400;
      case 95:
      case 96:
      case 99:
        return Colors.yellow.shade800;
      default:
        return Colors.orange;
    }
  }

  Future<void> fetchWeather() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Mekkah Coordinates: Lat: 21.4267, Lon: 39.8261
      final response = await _dio.get(
        'https://api.open-meteo.com/v1/forecast',
        queryParameters: {
          'latitude': 21.4267,
          'longitude': 39.8261,
          'current': 'temperature_2m,relative_humidity_2m,apparent_temperature,precipitation,weather_code,is_day,wind_speed_10m',
        },
      );

      if (response.statusCode == 200) {
        final currentData = response.data['current'];
        if (currentData != null) {
          _temperature = (currentData['temperature_2m'] as num).toDouble();
          _apparentTemperature = (currentData['apparent_temperature'] as num?)?.toDouble() ?? _temperature;
          _humidity = (currentData['relative_humidity_2m'] as num?)?.toInt() ?? 15;
          _windSpeed = (currentData['wind_speed_10m'] as num?)?.toDouble() ?? 10.0;
          _precipitation = (currentData['precipitation'] as num?)?.toDouble() ?? 0.0;
          _weatherCode = (currentData['weather_code'] as num).toInt();
          _isDay = (currentData['is_day'] as num).toInt();
        }
      } else {
        _errorMessage = 'Gagal memuat cuaca realtime';
      }
    } catch (e) {
      _errorMessage = 'Gagal memuat cuaca: $e';
      debugPrint('Weather Fetch Error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
