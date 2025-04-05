import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';

class SensorService {
  static const String apiUrl = 'http://192.168.1.5'; // ESP32'nin IP adresi

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
  
  // IR LED Kontrolleri - Yeni Eklenen Fonksiyonlar
  
  // IR LED durumunu al
  static Future<Map<String, dynamic>> getIRLedStatus() async {
    try {
      final response = await http.get(Uri.parse('$apiUrl/status'));
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'isOn': data['irLed'] == 'on',
        };
      } else {
        throw Exception('IR LED durumu alınamadı');
      }
    } catch (e) {
      print('IR LED durumu alınırken hata: $e');
      return {'isOn': false};
    }
  }
  
  // IR LED'i aç/kapa
  static Future<bool> controlIRLed(bool isOn) async {
    try {
      final response = await http.get(Uri.parse('$apiUrl/irled?status=${isOn ? "on" : "off"}'));
      
      if (response.statusCode == 200) {
        print('IR LED ${isOn ? "açıldı" : "kapatıldı"}');
        return true;
      } else {
        print('IR LED kontrol edilemedi');
        return false;
      }
    } catch (e) {
      print('IR LED kontrol edilirken hata: $e');
      return false;
    }
  }
  
  // IR LED rengini değiştir
  static Future<bool> setIRLedColor(String color) async {
    // Geçerli renk değerlerini kontrol et
    if (!['red', 'green', 'blue', 'white'].contains(color)) {
      return false;
    }
    
    try {
      final response = await http.get(Uri.parse('$apiUrl/irled?color=$color'));
      
      if (response.statusCode == 200) {
        print('IR LED rengi $color olarak ayarlandı');
        return true;
      } else {
        print('IR LED rengi ayarlanamadı');
        return false;
      }
    } catch (e) {
      print('IR LED rengi ayarlanırken hata: $e');
      return false;
    }
  }
  
  // IR LED efektini değiştir
  static Future<bool> setIRLedEffect(String effect) async {
    // Geçerli efekt değerlerini kontrol et
    if (!['flash', 'strobe', 'fade', 'smooth'].contains(effect)) {
      return false;
    }
    
    try {
      final response = await http.get(Uri.parse('$apiUrl/irled?effect=$effect'));
      
      if (response.statusCode == 200) {
        print('IR LED efekti $effect olarak ayarlandı');
        return true;
      } else {
        print('IR LED efekti ayarlanamadı');
        return false;
      }
    } catch (e) {
      print('IR LED efekti ayarlanırken hata: $e');
      return false;
    }
  }
  
  // IR LED parlaklığını artır
  static Future<bool> increaseIRLedBrightness() async {
    try {
      final response = await http.get(Uri.parse('$apiUrl/irled?brightness=up'));
      
      if (response.statusCode == 200) {
        print('IR LED parlaklığı artırıldı');
        return true;
      } else {
        print('IR LED parlaklığı artırılamadı');
        return false;
      }
    } catch (e) {
      print('IR LED parlaklığı artırılırken hata: $e');
      return false;
    }
  }
  
  // IR LED parlaklığını azalt
  static Future<bool> decreaseIRLedBrightness() async {
    try {
      final response = await http.get(Uri.parse('$apiUrl/irled?brightness=down'));
      
      if (response.statusCode == 200) {
        print('IR LED parlaklığı azaltıldı');
        return true;
      } else {
        print('IR LED parlaklığı azaltılamadı');
        return false;
      }
    } catch (e) {
      print('IR LED parlaklığı azaltılırken hata: $e');
      return false;
    }
  }
}
