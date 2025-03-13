import 'dart:convert';
import 'package:http/http.dart' as http;

// Global API anahtarına erişim
import '../main.dart' as main;

class WeatherService {
  final String baseUrl = "https://api.openweathermap.org/data/2.5/weather";

  // Weather bilgisini almak için asenkron fonksiyon
  Future<Map<String, dynamic>> getWeather(double latitude, double longitude) async {
    try {
      final response = await _fetchWeatherData(latitude, longitude);
      print('API Yanıt Kodu: ${response.statusCode}');
      print('API Yanıtı: ${response.body}');

      if (response.statusCode == 200) {
        return _parseWeatherData(response.body);
      } else {
        throw WeatherException('Hava durumu verisi alınamadı. API Hatası: ${response.statusCode}');
      }
    } catch (e) {
      if (e is WeatherException) {
        rethrow;
      }
      throw WeatherException('Bir hata oluştu: $e');
    }
  }

  // API'den hava durumu verisini çekme
  Future<http.Response> _fetchWeatherData(double latitude, double longitude) async {
    // Global değişkenden API anahtarını alıyoruz
    final apiKey = main.weatherApiKey;
    
    final String url = '$baseUrl?lat=$latitude&lon=$longitude&appid=$apiKey&units=metric&lang=tr';
    print('Hava durumu API çağrısı yapılıyor: $url');
    return await http.get(Uri.parse(url));
  }

  // Gelen JSON verisini işleme
  Map<String, dynamic> _parseWeatherData(String responseBody) {
    try {
      final Map<String, dynamic> data = json.decode(responseBody);
      return {
        'temperature': data['main']['temp'].toStringAsFixed(1),
        'weatherDescription': data['weather'][0]['description'],
        'icon': data['weather'][0]['icon'],
        'humidity': data['main']['humidity'],
        'windSpeed': data['wind']['speed'],
      };
    } catch (e) {
      throw WeatherException('Hava durumu verisi işlenirken hata oluştu: $e');
    }
  }
}

// Özel hata sınıfı
class WeatherException implements Exception {
  final String message;
  WeatherException(this.message);

  @override
  String toString() => message;
}
