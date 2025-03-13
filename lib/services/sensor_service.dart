import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';

class SensorService {
  static const String apiUrl = 'http://192.168.1.2'; // ESP32'nin IP adresi

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

  // Yeni AC kontrol metotları
  
  // AC durumunu al
  static Future<Map<String, dynamic>> getACStatus() async {
    try {
      final response = await http.get(Uri.parse('$apiUrl/status'));
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data;
      } else {
        throw Exception('AC durumu alınamadı');
      }
    } catch (e) {
      print('AC durumu alınırken hata: $e');
      return {'status': 'unknown', 'temperature': 22};
    }
  }
  
  // AC'yi aç/kapa
  static Future<bool> setACStatus(bool isOn) async {
    try {
      final response = await http.get(Uri.parse('$apiUrl/ac?status=${isOn ? "on" : "off"}'));
      
      if (response.statusCode == 200) {
        print('AC ${isOn ? "açıldı" : "kapandı"}');
        return true;
      } else {
        print('AC kontrol edilemedi');
        return false;
      }
    } catch (e) {
      print('AC kontrol edilirken hata: $e');
      return false;
    }
  }
  
  // AC sıcaklığını ayarla (17-30 arasında)
  static Future<bool> setACTemperature(int temperature) async {
    // Sıcaklık değerini 17-30 arasında sınırla
    temperature = temperature.clamp(17, 30);
    
    try {
      final response = await http.get(Uri.parse('$apiUrl/ac?temp=$temperature'));
      
      if (response.statusCode == 200) {
        print('AC sıcaklığı $temperature°C\'ye ayarlandı');
        return true;
      } else {
        print('AC sıcaklığı ayarlanamadı');
        return false;
      }
    } catch (e) {
      print('AC sıcaklığı ayarlanırken hata: $e');
      return false;
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
