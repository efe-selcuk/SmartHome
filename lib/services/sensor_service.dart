import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';

class SensorService {
  static const String apiUrl = 'http://192.168.1.8'; // ESP32'nin IP adresi
  static Timer? _timer; // Sıcaklık ve nem verilerini periyodik olarak güncellemek için Timer

  // Sıcaklık ve nem verilerini al
  static Future<Map<String, double>> fetchSensorData() async {
    try {
      final response = await http.get(Uri.parse(apiUrl));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        double temperature = data['temperature']?.toDouble() ?? 0.0;
        double humidity = data['humidity']?.toDouble() ?? 0.0;

        print('Sıcaklık: $temperature, Nem: $humidity');
        return {
          'temperature': temperature,
          'humidity': humidity,
        };
      } else {
        throw Exception('Veri alınamadı');
      }
    } catch (e) {
      print('Hata: $e');
      return {'temperature': 0.0, 'humidity': 0.0};
    }
  }

  // Periyodik veri güncelleme
  static void startPeriodicUpdates(Function(Map<String, double>) onDataReceived) {
    _timer?.cancel(); // Önceki zamanlayıcıyı iptal et
    _timer = Timer.periodic(Duration(seconds: 5), (timer) async {
      Map<String, double> sensorData = await fetchSensorData();
      onDataReceived(sensorData);
    });
  }

  // LED'i açma veya kapama
  static Future<void> controlLight(bool isOn) async {
    try {
      final response = await http.get(Uri.parse('$apiUrl/light?status=${isOn ? "on" : "off"}'));

      if (response.statusCode == 200) {
        print('Işık ${isOn ? "açıldı" : "kapandı"}');
      } else {
        throw Exception('Işık kontrol edilemedi');
      }
    } catch (e) {
      print('Hata: $e');
    }
  }

  // Zamanlayıcıyı durdur
  static void stopPeriodicUpdates() {
    _timer?.cancel();
  }
}
