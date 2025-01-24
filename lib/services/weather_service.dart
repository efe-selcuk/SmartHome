import 'dart:convert';
import 'package:http/http.dart' as http;

class WeatherService {
  final String apiKey = 'b265ec116d325a1b81af0bc0f5d3b50e';
  final String baseUrl = "https://api.openweathermap.org/data/2.5/weather";

  // Weather bilgisini almak için asenkron fonksiyon
  Future<Map<String, dynamic>> getWeather(double latitude, double longitude) async {
    try {
      final response = await _fetchWeatherData(latitude, longitude);

      if (response.statusCode == 200) {
        return _parseWeatherData(response.body);
      } else {
        throw WeatherException('Hava durumu verisi alınamadı. API Hatası: ${response.statusCode}');
      }
    } catch (e) {
      throw WeatherException('Bir hata oluştu: $e');
    }
  }

  // API'den hava durumu verisini çekme
  Future<http.Response> _fetchWeatherData(double latitude, double longitude) {
    final String url = '$baseUrl?lat=$latitude&lon=$longitude&appid=$apiKey&units=metric';
    return http.get(Uri.parse(url));
  }

  // Gelen JSON verisini işleme
  Map<String, dynamic> _parseWeatherData(String responseBody) {
    final Map<String, dynamic> data = json.decode(responseBody);
    return {
      'temperature': data['main']['temp'],
      'weatherDescription': data['weather'][0]['description'],
    };
  }
}

// Özel hata sınıfı
class WeatherException implements Exception {
  final String message;
  WeatherException(this.message);

  @override
  String toString() => 'WeatherException: $message';
}
