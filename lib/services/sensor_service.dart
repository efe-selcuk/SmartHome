import 'package:http/http.dart' as http;
import 'dart:convert';  // JSON işlemleri için

class SensorService {
  static const String apiUrl = 'http://192.168.1.8'; // ESP32'nin IP adresi

  static Future<Map<String, double>> fetchSensorData() async {
    try {
      final response = await http.get(Uri.parse(apiUrl));

      if (response.statusCode == 200) {
        // JSON verisini çözümleyin
        final data = jsonDecode(response.body);
        double temperature = data['temperature']?.toDouble() ?? 0.0;
        double humidity = data['humidity']?.toDouble() ?? 0.0;

        print('Sıcaklık: $temperature, Nem: $humidity'); // Veriyi konsola yazdır
        return {
          'temperature': temperature,
          'humidity': humidity,
        };
      } else {
        throw Exception('Veri alınamadı');
      }
    } catch (e) {
      print('Hata: $e');
      return {'temperature': 0.0, 'humidity': 0.0};  // Veriler null değil, 0.0 ile başla
    }
  }
}
