import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';

class SensorService {
  static const String apiUrl = 'http://192.168.1.8'; // ESP32'nin IP adresi

  // Her odanın GPIO pinini belirleyelim
  static const Map<int, String> roomEndpoints = {
    1: '/room1/light',
    2: '/room2/light',
    3: '/room3/light',
    4: '/room4/light',
    5: '/room5/light',
  };

  // Periyodik veri güncelleme
  static void startPeriodicUpdates(Function(Map<String, double>) onDataReceived) {
    Timer.periodic(Duration(seconds: 5), (timer) async {
      Map<String, double> sensorData = await fetchSensorData();
      onDataReceived(sensorData);
    });
  }

  // Sıcaklık ve nem verilerini al
  static Future<Map<String, double>> fetchSensorData() async {
    try {
      final response = await http.get(Uri.parse('$apiUrl/'));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        double temperature = data['temperature']?.toDouble() ?? 0.0;
        double humidity = data['humidity']?.toDouble() ?? 0.0;

        return {
          'temperature': temperature,
          'humidity': humidity,
        };
      } else {
        throw Exception('Veri alınamadı');
      }
    } catch (e) {
      return {'temperature': 0.0, 'humidity': 0.0};
    }
  }

  // Oda ışığını açma veya kapama
  static Future<void> controlLight(int room, bool isOn) async {
    final endpoint = roomEndpoints[room];
    if (endpoint != null) {
      final response = await http.get(Uri.parse('$apiUrl$endpoint?status=${isOn ? "on" : "off"}'));

      if (response.statusCode == 200) {
        print('Oda $room ışığı ${isOn ? "açıldı" : "kapandı"}');
      } else {
        print('Işık kontrol edilemedi');
      }
    } else {
      print('Oda numarası hatalı.');
    }
  }

  // Oda sıcaklık değerini ayarla (Klima için örnek)
  static Future<void> controlClima(int room, double temperature) async {
    final endpoint = '/room$room/clima';
    final response = await http.get(Uri.parse('$apiUrl$endpoint?temperature=$temperature'));

    if (response.statusCode == 200) {
      print('Oda $room kliması ${temperature.toStringAsFixed(1)}°C\'ye ayarlandı');
    } else {
      print('Klima kontrol edilemedi');
    }
  }

  // Oda ışık rengini ayarlama
  static Future<void> controlLightColor(int room, int colorValue) async {
    final endpoint = '/room$room/light/color';
    final response = await http.get(Uri.parse('$apiUrl$endpoint?color=$colorValue'));

    if (response.statusCode == 200) {
      print('Oda $room ışık rengi ayarlandı');
    } else {
      print('Işık rengi ayarlanamadı');
    }
  }
}
