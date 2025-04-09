import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:smarthome/screens/automation_screen.dart'; // AutomationRule sınıfını kullanmak için import

class SensorService {
  // Son uygulanan otomasyon işlemlerini izleme
  static final Map<String, int> _lastAppliedRules = {};

  // Otomasyon kurallarını uygulama metodu
  static Future<bool> applyAutomationRule(
      String room, AutomationRule rule, Map<String, double> sensorData) async {
    if (!rule.isEnabled) return false;

    // Son 5 dakika içinde aynı oda için otomasyon uygulandıysa tekrar uygulama
    int currentTime = DateTime.now().millisecondsSinceEpoch;
    int lastAppliedTime = _lastAppliedRules[room] ?? 0;
    int timeDifference = currentTime - lastAppliedTime;
    
    if (lastAppliedTime > 0 && timeDifference < 300000) { // 5 dakika
      print('$room odasına son $timeDifference ms önce otomasyon uygulandı, tekrar uygulanmıyor');
      return true; // Başarılı gibi true dön, işlem tekrar yapılmasın
    }

    // Önce mevcut AC durumunu kontrol et
    try {
      final acStatus = await getACStatus();
      bool isAlreadyOn = acStatus['status'] == 'on';
      int currentTemp = acStatus['temperature'] ?? 0;
      
      // Eğer klima zaten açık ve hedef sıcaklıkta ise tekrar işlem yapma
      if (isAlreadyOn && currentTemp == rule.targetTemperature) {
        print('Klima zaten açık ve hedef sıcaklıkta (${rule.targetTemperature}°C), işlem atlandı.');
        // Son uygulama zamanını güncelle
        _lastAppliedRules[room] = currentTime;
        return true;
      }
      
      // Koşulları kontrol et
      double temperature = sensorData['temperature'] ?? 0.0;
      double humidity = sensorData['humidity'] ?? 0.0;
      bool shouldTurnOnAC = false;

      // Sıcaklık eşiği kontrolü (büyük/küçük karşılaştırma)
      if (rule.isTemperatureAbove) {
        // Sıcaklık eşiğin üzerindeyse
        shouldTurnOnAC = temperature > rule.temperatureThreshold;
      } else {
        // Sıcaklık eşiğin altındaysa
        shouldTurnOnAC = temperature < rule.temperatureThreshold;
      }

      // Nem eşiği kontrolü (büyük/küçük karşılaştırma)
      if (rule.isHumidityAbove) {
        // Nem eşiğin üzerindeyse
        shouldTurnOnAC = shouldTurnOnAC || humidity > rule.humidityThreshold;
      } else {
        // Nem eşiğin altındaysa
        shouldTurnOnAC = shouldTurnOnAC || humidity < rule.humidityThreshold;
      }

      if (shouldTurnOnAC) {
        // Klimayı aç ve hedef sıcaklığı ayarla
        print('Otomasyon koşulları sağlandı, klima açılıyor. Sıcaklık: $temperature°C, Nem: $humidity%');
        
        // Burada paralel olarak iki işlemi çağırmak arka arkaya tekrara neden olabilir
        // Önce klimayı aç, sonra sıcaklığı ayarla
        bool acSuccess = await setACStatus(true);
        
        if (acSuccess) {
          // Kısa bir bekleme ekleyelim
          await Future.delayed(Duration(milliseconds: 500));
          
          // Sonra sıcaklığı ayarla
          bool tempSuccess = await setACTemperature(rule.targetTemperature);
          
          if (tempSuccess) {
            // İşlem başarılıysa son uygulama zamanını güncelle
            _lastAppliedRules[room] = currentTime;
            print('Otomasyon kuralı uygulandı: $room odası için klima açıldı, sıcaklık: ${rule.targetTemperature}°C');
            return true;
          } else {
            print('Otomasyon kuralı kısmen uygulandı: Klima açıldı fakat sıcaklık ayarlanamadı');
            return true; // Yine de başarılı sayalım, klimayı açtık en azından
          }
        } else {
          print('Otomasyon kuralı uygulanamadı: Klima açılamadı');
          return false;
        }
      } else {
        print('Otomasyon koşulları sağlanmadı, işlem yapılmadı');
        return false;
      }
    } catch (e) {
      print('AC durumu kontrol edilirken hata: $e');
      return false;
    }
  }

  // TV durum değişkenlerini bellek içinde tutma
  static bool _isTvOn = false;
  static int _tvVolume = 50;
  static int _tvChannel = 1;
  static bool _isTvMuted = false;
  
  // TV durum bilgilerini alma
  static Map<String, dynamic> getTvMemoryStatus() {
    return {
      'isOn': _isTvOn,
      'volume': _tvVolume,
      'channel': _tvChannel,
      'isMuted': _isTvMuted,
    };
  }
  
  // TV durum bilgilerini güncelleme
  static void updateTvMemoryStatus({bool? isOn, int? volume, int? channel, bool? isMuted}) {
    if (isOn != null) _isTvOn = isOn;
    if (volume != null) _tvVolume = volume;
    if (channel != null) _tvChannel = channel;
    if (isMuted != null) _isTvMuted = isMuted;
  }

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
  static void startPeriodicUpdates(
      Function(Map<String, double>) onDataReceived) {
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
      final response = await http
          .get(Uri.parse('$apiUrl$endpoint?status=${isOn ? "on" : "off"}'));

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
    final response =
        await http.get(Uri.parse('$apiUrl$endpoint?temperature=$temperature'));

    if (response.statusCode == 200) {
      print(
          'Oda $room kliması ${temperature.toStringAsFixed(1)}°C\'ye ayarlandı');
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
        // Sıcaklık değeri double ise int'e dönüştür
        if (data['temperature'] is double) {
          data['temperature'] = data['temperature'].round();
        }
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
      final response =
          await http.get(Uri.parse('$apiUrl/ac?status=${isOn ? "on" : "off"}'));

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
      final response =
          await http.get(Uri.parse('$apiUrl/ac?temp=$temperature'));

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
    final response =
        await http.get(Uri.parse('$apiUrl$endpoint?color=$colorValue'));

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
      final response = await http
          .get(Uri.parse('$apiUrl/irled?status=${isOn ? "on" : "off"}'));

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
      final response =
          await http.get(Uri.parse('$apiUrl/irled?effect=$effect'));

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
      final response =
          await http.get(Uri.parse('$apiUrl/irled?brightness=down'));

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

  // TV Kontrol Metotları

  // TV durumunu al - Simülasyon
  static Future<Map<String, dynamic>> getTvStatus(String roomName) async {
    try {
      // Gerçek uygulamada burada sunucuya istek yapılır
      // Şimdilik simülasyon yapıyoruz
      await Future.delayed(Duration(milliseconds: 300)); // Gerçek istek simülasyonu

      // Simülasyon verileri
      return {
        'isOn': true,
        'volume': 50,
        'channel': 1,
        'isMuted': false,
      };
    } catch (e) {
      print('TV durumu alınırken hata: $e');
      // Varsayılan değerler döndür
      return {
        'isOn': false,
        'volume': 50,
        'channel': 1,
        'isMuted': false,
      };
    }
  }

  // TV'yi aç/kapa - Simülasyon
  static Future<bool> controlTv(String roomName, bool isOn) async {
    try {
      // Gerçek uygulamada burada sunucuya istek yapılır
      // Şimdilik simülasyon yapıyoruz
      await Future.delayed(Duration(milliseconds: 300)); // Gerçek istek simülasyonu
      
      print('TV ${isOn ? "açıldı" : "kapatıldı"}');
      return true;
    } catch (e) {
      print('TV kontrol edilirken hata: $e');
      return false;
    }
  }

  // TV ses seviyesini ayarla - Simülasyon
  static Future<bool> setTvVolume(String roomName, int volume) async {
    try {
      // Gerçek uygulamada burada sunucuya istek yapılır
      // Şimdilik simülasyon yapıyoruz
      await Future.delayed(Duration(milliseconds: 300)); // Gerçek istek simülasyonu
      
      print('TV ses seviyesi $volume olarak ayarlandı');
      return true;
    } catch (e) {
      print('TV ses seviyesi ayarlanırken hata: $e');
      return false;
    }
  }

  // TV sesini kapat/aç - Simülasyon
  static Future<bool> toggleTvMute(String roomName) async {
    try {
      // Gerçek uygulamada burada sunucuya istek yapılır
      // Şimdilik simülasyon yapıyoruz
      await Future.delayed(Duration(milliseconds: 300)); // Gerçek istek simülasyonu
      
      print('TV sessiz modu değiştirildi');
      return true;
    } catch (e) {
      print('TV sessiz modu değiştirilirken hata: $e');
      return false;
    }
  }

  // TV kanalını değiştir - Simülasyon
  static Future<bool> setTvChannel(String roomName, int channel) async {
    try {
      // Gerçek uygulamada burada sunucuya istek yapılır
      // Şimdilik simülasyon yapıyoruz
      await Future.delayed(Duration(milliseconds: 300)); // Gerçek istek simülasyonu
      
      print('TV kanalı $channel olarak değiştirildi');
      return true;
    } catch (e) {
      print('TV kanalı değiştirilirken hata: $e');
      return false;
    }
  }

  // TV uygulamasını başlat - Simülasyon
  static Future<bool> launchTvApp(String roomName, String appName) async {
    try {
      // Gerçek uygulamada burada sunucuya istek yapılır
      // Şimdilik simülasyon yapıyoruz
      await Future.delayed(Duration(milliseconds: 300)); // Gerçek istek simülasyonu
      
      print('TV uygulaması $appName başlatıldı');
      return true;
    } catch (e) {
      print('TV uygulaması başlatılırken hata: $e');
      return false;
    }
  }

  // TV Kumanda Fonksiyonları - Gerçek ESP32 kontrolü için
  
  // TV Güç Kontrolü
  static Future<bool> controlTvPower() async {
    try {
      final response = await http.get(Uri.parse('$apiUrl/remote?power=toggle'));
      
      if (response.statusCode == 200) {
        print('TV güç durumu değiştirildi');
        // Bellek içindeki durumu güncelle
        _isTvOn = !_isTvOn;
        return true;
      } else {
        print('TV güç durumu değiştirilemedi');
        return false;
      }
    } catch (e) {
      print('TV güç kontrolü sırasında hata: $e');
      return false;
    }
  }
  
  // TV Ses Kontrolü
  static Future<bool> controlTvVolume(String action) async {
    if (!['up', 'down', 'mute'].contains(action)) {
      print('Geçersiz ses kontrol komutu: $action');
      return false;
    }
    
    try {
      final response = await http.get(Uri.parse('$apiUrl/remote?volume=$action'));
      
      if (response.statusCode == 200) {
        print('TV ses seviyesi $action işlemi uygulandı');
        
        // Bellek içindeki durumu güncelle
        if (action == 'up') {
          _tvVolume = (_tvVolume + 5).clamp(0, 100);
          _isTvMuted = false;
        } else if (action == 'down') {
          _tvVolume = (_tvVolume - 5).clamp(0, 100);
        } else if (action == 'mute') {
          _isTvMuted = !_isTvMuted;
        }
        
        return true;
      } else {
        print('TV ses seviyesi değiştirilemedi');
        return false;
      }
    } catch (e) {
      print('TV ses kontrolü sırasında hata: $e');
      return false;
    }
  }
  
  // TV Kanal Kontrolü
  static Future<bool> controlTvChannel(String action) async {
    if (!['up', 'down'].contains(action)) {
      print('Geçersiz kanal kontrol komutu: $action');
      return false;
    }
    
    try {
      final response = await http.get(Uri.parse('$apiUrl/remote?channel=$action'));
      
      if (response.statusCode == 200) {
        print('TV kanal $action işlemi uygulandı');
        
        // Bellek içindeki durumu güncelle
        if (action == 'up') {
          _tvChannel++;
        } else if (action == 'down' && _tvChannel > 1) {
          _tvChannel--;
        }
        
        return true;
      } else {
        print('TV kanal değiştirilemedi');
        return false;
      }
    } catch (e) {
      print('TV kanal kontrolü sırasında hata: $e');
      return false;
    }
  }
  
  // TV Sayısal Tuş Kontrolü
  static Future<bool> controlTvNumberButton(int number) async {
    if (number < 0 || number > 9) {
      print('Geçersiz sayı: $number');
      return false;
    }
    
    try {
      final response = await http.get(Uri.parse('$apiUrl/remote?button=$number'));
      
      if (response.statusCode == 200) {
        print('TV $number tuşu uygulandı');
        
        // Bellek içindeki kanal bilgisini güncelle (kanal değiştirme amacıyla kullanıldığında)
        _tvChannel = number;
        
        return true;
      } else {
        print('TV sayısal tuşu uygulanamadı');
        return false;
      }
    } catch (e) {
      print('TV sayısal tuş kontrolü sırasında hata: $e');
      return false;
    }
  }
  
  // TV Yön Tuşları Kontrolü
  static Future<bool> controlTvDirection(String direction) async {
    if (!['up', 'down', 'left', 'right'].contains(direction)) {
      print('Geçersiz yön komutu: $direction');
      return false;
    }
    
    try {
      final response = await http.get(Uri.parse('$apiUrl/remote?direction=$direction'));
      
      if (response.statusCode == 200) {
        print('TV yön tuşu $direction uygulandı');
        return true;
      } else {
        print('TV yön tuşu uygulanamadı');
        return false;
      }
    } catch (e) {
      print('TV yön kontrolü sırasında hata: $e');
      return false;
    }
  }
  
  // TV OK Tuşu Kontrolü
  static Future<bool> controlTvOkButton() async {
    try {
      final response = await http.get(Uri.parse('$apiUrl/remote?button=ok'));
      
      if (response.statusCode == 200) {
        print('TV OK tuşu uygulandı');
        return true;
      } else {
        print('TV OK tuşu uygulanamadı');
        return false;
      }
    } catch (e) {
      print('TV OK tuşu kontrolü sırasında hata: $e');
      return false;
    }
  }
}
