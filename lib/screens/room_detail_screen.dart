import 'package:flutter/material.dart';
import 'package:flex_color_picker/flex_color_picker.dart';
import 'package:smarthome/services/sensor_service.dart';
import 'package:smarthome/services/database_service.dart';
import 'package:smarthome/screens/ac_detail_screen.dart';
import 'dart:async';

class RoomDetailsScreen extends StatefulWidget {
  final String roomName;

  const RoomDetailsScreen({super.key, required this.roomName});

  @override
  _RoomDetailsScreenState createState() => _RoomDetailsScreenState();
}

class _RoomDetailsScreenState extends State<RoomDetailsScreen> {
  List<String> devices = [];
  bool isClimaOn = false;
  bool isLightOn = false; // Işık durumu sadece switch ile kontrol edilecek
  bool isTvOn = false;
  bool _isDisposed = false;  // Eklenen değişken
  bool isIRLedOn = false;    // IR LED durumu
  double? temperature;
  double? humidity;
  double lightIntensity = 50.0;
  double climaTemperature = 22.0;
  String irLedColor = 'white'; // IR LED rengi (white, red, green, blue)
  String irLedEffect = 'normal'; // IR LED efekti - başlangıçta kart kapalı
  Color lightColor = Colors.white;

  final DatabaseService _databaseService = DatabaseService();
  Timer? _timer;

  // Cihazları eklemek için
  void addDevice(String deviceName) {
    setState(() {
      if (!devices.contains(deviceName)) {
        devices.add(deviceName);
      }
    });
    _saveRoomData();
  }

  // Firestore'a veri kaydetme
  Future<void> _saveRoomData() async {
    Map<String, dynamic> data = {
      'roomName': widget.roomName,
      'devices': devices,
      'lightColor': lightColor.value.toString(),
      'climaTemp': climaTemperature,
      'lightIntensity': lightIntensity,
      'isClimaOn': isClimaOn,
      'isLightOn': isLightOn,  // Işık durumu, switch'e bağlı olarak
      'isTvOn': isTvOn,
      'temperature': temperature,
      'humidity': humidity,
      'isIRLedOn': isIRLedOn,  // IR LED durumu eklendi
      'irLedColor': irLedColor, // IR LED rengi eklendi
      'irLedEffect': irLedEffect, // IR LED efekti eklendi
    };
    await _databaseService.saveRoomData(widget.roomName, data);
  }

  // Sıcaklık ve nem verilerini çekme
  Future<void> fetchSensorData() async {
    Map<String, double> data = await SensorService.fetchSensorData();
    setState(() {
      temperature = data['temperature'];
      humidity = data['humidity'];
    });
  }

  // Renk Seçici Dialog
  void _showColorPicker() async {
    Color pickedColor = lightColor;
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Renk Seç"),
          content: ColorPicker(
            color: pickedColor,
            onColorChanged: (color) {
              setState(() {
                lightColor = color;
              });
              _saveRoomData();
            },
            showColorCode: true,
            wheelDiameter: 250,
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text("Tamam"),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text("Vazgeç"),
            ),
          ],
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    _isDisposed = false;  // initState'de false olarak ayarla
    _loadRoomData();
    // Periyodik veri güncellemeleri başlatılıyor
    _startPeriodicUpdates();
    _startACStatusUpdates(); // AC durumunu güncelleme
    _checkIRLedStatus(); // IR LED durumunu kontrol et
  }

  // IR LED durumunu kontrol et
  Future<void> _checkIRLedStatus() async {
    try {
      Map<String, dynamic> status = await SensorService.getIRLedStatus();
      setState(() {
        isIRLedOn = status['isOn'];
      });
    } catch (e) {
      print('IR LED durumu kontrol edilirken hata: $e');
    }
  }

  @override
  void dispose() {
    _isDisposed = true;  // dispose edildiğinde true yap
    // Periyodik güncellemeleri durduruyoruz
    _stopPeriodicUpdates();
    super.dispose();
  }

  // Periyodik veri güncellemelerini başlat
  void _startPeriodicUpdates() {
    _timer = Timer.periodic(Duration(seconds: 10), (timer) {
      fetchSensorData();  // 10 saniyede bir veriyi güncelle
    });
  }

  // AC durumunu periyodik olarak güncelle
  Timer? _acStatusTimer;
  void _startACStatusUpdates() {
    _acStatusTimer = Timer.periodic(Duration(seconds: 3), (timer) async {
      if (_isDisposed) {
        timer.cancel();
        return;
      }
      
      try {
        Map<String, dynamic>? roomData = await _databaseService.loadRoomData(widget.roomName);
        if (roomData != null && mounted) {
          bool newIsClimaOn = roomData['isClimaOn'] ?? false;
          double newClimaTemp = roomData['climaTemp'] ?? 22.0;
          
          // Sadece değişiklik varsa state'i güncelle
          if (newIsClimaOn != isClimaOn || newClimaTemp != climaTemperature) {
            setState(() {
              isClimaOn = newIsClimaOn;
              climaTemperature = newClimaTemp;
            });
          }
        }
      } catch (e) {
        print('AC durumu güncellenirken hata: $e');
      }
    });
  }

  // Periyodik veri güncellemelerini durdur
  void _stopPeriodicUpdates() {
    if (_timer != null) {
      _timer!.cancel();
    }
    if (_acStatusTimer != null) {
      _acStatusTimer!.cancel();
    }
  }

  // Firestore'dan odadaki verileri yükleme
  Future<void> _loadRoomData() async {
    Map<String, dynamic>? roomData = await _databaseService.loadRoomData(widget.roomName);

    if (roomData != null) {
      setState(() {
        devices = List<String>.from(roomData['devices'] ?? []);
        lightColor = Color(int.parse(roomData['lightColor'] ?? '0'));
        climaTemperature = roomData['climaTemp'];
        lightIntensity = roomData['lightIntensity'];
        isClimaOn = roomData['isClimaOn'];
        isLightOn = roomData['isLightOn'] ?? false;  // Işık durumu, eğer belirtilmediyse false
        isTvOn = roomData['isTvOn'];
        temperature = roomData['temperature'];
        humidity = roomData['humidity'];
        
        // IR LED verileri
        isIRLedOn = roomData['isIRLedOn'] ?? false;
        irLedColor = roomData['irLedColor'] ?? 'white';
        irLedEffect = roomData['irLedEffect'] ?? 'normal';
      });
    } else {
      print("Oda verisi bulunamadı.");
    }
  }

  // Işık açma/kapatma
  Future<void> _controlLight(bool isOn) async {
    setState(() {
      isLightOn = isOn;
    });
    
    // Odanın adına göre oda numarasını belirle
    int roomNumber;
    
    switch (widget.roomName.toLowerCase()) {
      case 'salon':
        roomNumber = 1;
        break;
      case 'yatak odası':
        roomNumber = 2;
        break;
      case 'mutfak':
        roomNumber = 3;
        break;
      case 'banyo':
        roomNumber = 4;
        break;
      case 'çocuk odası':
        roomNumber = 5;
        break;
      default:
        // Eğer özel bir oda ismi var ise, son kelimesindeki sayıyı almaya çalış
        // Örnek: "Oda 3" için 3 numaralı odayı kullan
        final RegExp regExp = RegExp(r'(\d+)');
        final match = regExp.firstMatch(widget.roomName);
        if (match != null) {
          roomNumber = int.parse(match.group(1)!);
          // Eğer oda numarası 5'ten büyükse, 1-5 arasında bir değere map yap
          if (roomNumber > 5) {
            roomNumber = ((roomNumber - 1) % 5) + 1;
          }
        } else {
          // Eşleşme yoksa varsayılan olarak 1. odayı kullan
          roomNumber = 1;
        }
        break;
    }
    
    print('Oda: ${widget.roomName}, Oda Numarası: $roomNumber olarak belirlendi');
    
    await SensorService.controlLight(roomNumber, isOn);  // Belirlenen oda numarasına göre ESP32'ye komut gönder
    _saveRoomData();  // Veriyi kaydet
  }

  // IR LED açma/kapatma
  Future<void> _controlIRLed(bool isOn) async {
    try {
      bool success = await SensorService.controlIRLed(isOn);
      if (success) {
        setState(() {
          isIRLedOn = isOn;
        });
        _saveRoomData();
      }
    } catch (e) {
      print('IR LED kontrol edilirken hata: $e');
    }
  }

  // IR LED rengini değiştir
  Future<void> _setIRLedColor(String color) async {
    try {
      bool success = await SensorService.setIRLedColor(color);
      if (success) {
        setState(() {
          irLedColor = color;
        });
        _saveRoomData();
      }
    } catch (e) {
      print('IR LED rengi ayarlanırken hata: $e');
    }
  }

  // IR LED efektini değiştir
  Future<void> _setIRLedEffect(String effect) async {
    try {
      bool success = await SensorService.setIRLedEffect(effect);
      if (success) {
        setState(() {
          irLedEffect = effect;
        });
        _saveRoomData();
      }
    } catch (e) {
      print('IR LED efekti ayarlanırken hata: $e');
    }
  }

  // IR LED parlaklığını artır
  Future<void> _increaseIRLedBrightness() async {
    try {
      await SensorService.increaseIRLedBrightness();
    } catch (e) {
      print('IR LED parlaklığı artırılırken hata: $e');
    }
  }

  // IR LED parlaklığını azalt
  Future<void> _decreaseIRLedBrightness() async {
    try {
      await SensorService.decreaseIRLedBrightness();
    } catch (e) {
      print('IR LED parlaklığı azaltılırken hata: $e');
    }
  }

  // Klima açma/kapatma
  Future<void> _controlAC(bool isOn) async {
    try {
      bool success = await SensorService.setACStatus(isOn);
      if (success) {
        setState(() {
          isClimaOn = isOn;
        });
        _saveRoomData();
      }
    } catch (e) {
      print('Klima kontrol edilirken hata: $e');
      // Hata durumunda kullanıcıya bilgi ver
      if (!_isDisposed && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Klima kontrol edilemedi: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Klima sıcaklığını ayarlama
  Future<void> _setACTemperature(int temperature) async {
    try {
      bool success = await SensorService.setACTemperature(temperature);
      if (success) {
        setState(() {
          climaTemperature = temperature.toDouble();
        });
        _saveRoomData();
      }
    } catch (e) {
      print('Klima sıcaklığı ayarlanırken hata: $e');
      // Hata durumunda kullanıcıya bilgi ver
      if (!_isDisposed && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Klima sıcaklığı ayarlanamadı: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.roomName} Detayları'),
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).primaryColor.withOpacity(0.1),
              Colors.white,
            ],
          ),
        ),
        child: SingleChildScrollView(
          physics: BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Oda Başlığı ve Sensör Verileri
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.roomName,
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).primaryColor,
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Oda Durumu',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                          Icon(
                            Icons.home,
                            size: 40,
                            color: Theme.of(context).primaryColor,
                          ),
                        ],
                      ),
                      SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildSensorWidget(
                            icon: Icons.thermostat,
                            value: temperature?.toStringAsFixed(1) ?? '--',
                            unit: '°C',
                            label: 'Sıcaklık',
                          ),
                          Container(
                            height: 50,
                            width: 1,
                            color: Colors.grey[300],
                          ),
                          _buildSensorWidget(
                            icon: Icons.water_drop,
                            value: humidity?.toStringAsFixed(1) ?? '--',
                            unit: '%',
                            label: 'Nem',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 24),
                
                // Cihaz Listesi Başlığı ve Ekleme Butonu
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Cihazlar',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: _showAddDeviceDialog,
                      icon: Icon(Icons.add),
                      label: Text('Cihaz Ekle'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColor,
                        foregroundColor: Colors.white,
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                
                // Cihaz Listesi
                devices.isEmpty
                    ? Center(
                        child: Column(
                          children: [
                            Icon(
                              Icons.devices_other,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            SizedBox(height: 16),
                            Text(
                              'Henüz cihaz eklenmemiş.',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
                        itemCount: devices.length,
                        itemBuilder: (context, index) {
                          if (devices[index] == 'Işık') {
                            return _buildLightCard();
                          } else if (devices[index] == 'Klima') {
                            return _buildClimaCard();
                          } else if (devices[index] == 'Akıllı TV') {
                            return _buildDefaultDeviceCard(devices[index]);
                          } else if (devices[index] == 'Akıllı LED Işık') {
                            return _buildIRLedCard();
                          }
                          return Container();
                        },
                      ),
                SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showAddDeviceDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Cihaz Ekle"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDeviceOption(
                icon: Icons.lightbulb,
                title: "Işık",
                onTap: () {
                  addDevice("Işık");
                  Navigator.pop(context);
                },
              ),
              _buildDeviceOption(
                icon: Icons.ac_unit,
                title: "Klima",
                onTap: () {
                  addDevice("Klima");
                  Navigator.pop(context);
                },
              ),
              _buildDeviceOption(
                icon: Icons.tv,
                title: "Akıllı TV",
                onTap: () {
                  addDevice("Akıllı TV");
                  Navigator.pop(context);
                },
              ),
              _buildDeviceOption(
                icon: Icons.wb_incandescent,
                title: "Akıllı LED Işık",
                onTap: () {
                  addDevice("Akıllı LED Işık");
                  Navigator.pop(context);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text("İptal"),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDeviceOption({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        margin: EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.grey[300]!,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 24,
              color: Theme.of(context).primaryColor,
            ),
            SizedBox(width: 16),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            Spacer(),
            Icon(
              Icons.add_circle_outline,
              color: Theme.of(context).primaryColor,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSensorWidget({
    required IconData icon,
    required String value,
    required String unit,
    required String label,
  }) {
    return Column(
      children: [
        Icon(
          icon,
          size: 24,
          color: Theme.of(context).primaryColor,
        ),
        SizedBox(height: 8),
        RichText(
          text: TextSpan(
            style: DefaultTextStyle.of(context).style,
            children: [
              TextSpan(
                text: value,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor,
                ),
              ),
              TextSpan(
                text: unit,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildLightCard() {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 8),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: AnimatedContainer(
        duration: Duration(milliseconds: 300),
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          color: isLightOn ? Colors.yellow.withOpacity(0.1) : Colors.white,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.lightbulb,
                      color: isLightOn ? lightColor : Colors.grey,
                      size: 28,
                    ),
                    SizedBox(width: 12),
                    Text(
                      'Işık',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Switch(
                  value: isLightOn,
                  onChanged: _controlLight,
                  activeColor: Theme.of(context).primaryColor,
                ),
              ],
            ),
            if (isLightOn) ...[
              SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Parlaklık',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                        SizedBox(height: 8),
                        SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            activeTrackColor: Theme.of(context).primaryColor,
                            thumbColor: Theme.of(context).primaryColor,
                            overlayColor: Theme.of(context).primaryColor.withOpacity(0.2),
                          ),
                          child: Slider(
                            value: lightIntensity,
                            min: 0.0,
                            max: 100.0,
                            onChanged: (value) {
                              setState(() {
                                lightIntensity = value;
                              });
                              _saveRoomData();
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 16),
                  GestureDetector(
                    onTap: _showColorPicker,
                    child: Container(
                      height: 40,
                      width: 40,
                      decoration: BoxDecoration(
                        color: lightColor,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.grey[300]!,
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: lightColor.withOpacity(0.3),
                            blurRadius: 8,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildClimaCard() {
    return GestureDetector(
      onTap: () {
        // Klima detay ekranına git
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ACDetailScreen(
              roomName: widget.roomName,
              initialIsOn: isClimaOn,
              initialTemperature: climaTemperature,
            ),
          ),
        );
      },
      child: Card(
        margin: EdgeInsets.symmetric(vertical: 8),
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        child: AnimatedContainer(
          duration: Duration(milliseconds: 300),
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            color: isClimaOn ? Colors.blue.withOpacity(0.1) : Colors.white,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.ac_unit,
                        color: isClimaOn ? Colors.blue : Colors.grey,
                        size: 28,
                      ),
                      SizedBox(width: 12),
                      Text(
                        'Klima',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Switch(
                    value: isClimaOn,
                    onChanged: (value) {
                      _controlAC(value); // Yeni API ile kontrolü çağır
                    },
                    activeColor: Colors.blue,
                  ),
                ],
              ),
              if (isClimaOn) ...[
                SizedBox(height: 16),
                // Sıcaklık bilgisi görüntüle, değiştirme seçeneği detay sayfasında
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Sıcaklık',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                        Text(
                          '${climaTemperature.round()}°C',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                      ],
                    ),
                    Icon(
                      Icons.arrow_forward_ios,
                      color: Colors.grey,
                      size: 16,
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTemperatureButton(int temp) {
    bool isSelected = climaTemperature.round() == temp;
    
    return GestureDetector(
      onTap: () {
        _setACTemperature(temp);
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue : Colors.grey.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? Colors.blue.shade300 : Colors.transparent,
            width: 1,
          ),
        ),
        child: Text(
          '$temp°C',
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey[700],
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildDefaultDeviceCard(String deviceName) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 8),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: ListTile(
        contentPadding: EdgeInsets.all(16),
        leading: Icon(
          Icons.devices_other,
          size: 28,
          color: Theme.of(context).primaryColor,
        ),
        title: Text(
          deviceName,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  // IR LED kontrol kartı
  Widget _buildIRLedCard() {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 8),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          gradient: isIRLedOn 
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: _getGradientColors(),
              ) 
            : null,
          color: isIRLedOn ? null : Colors.white,
        ),
        child: Theme(
          data: Theme.of(context).copyWith(
            dividerColor: Colors.transparent,
            unselectedWidgetColor: isIRLedOn ? Colors.white : Colors.grey,
            colorScheme: ColorScheme.fromSwatch().copyWith(
              secondary: isIRLedOn ? Colors.white : Theme.of(context).primaryColor,
            ),
          ),
          child: ExpansionTile(
            title: Row(
              children: [
                Icon(
                  Icons.wb_incandescent,
                  color: isIRLedOn ? _getIconColor() : Colors.grey,
                  size: 28,
                ),
                SizedBox(width: 12),
                Text(
                  'Akıllı LED Işık',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isIRLedOn ? Colors.white : Colors.black,
                  ),
                ),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Switch(
                  value: isIRLedOn,
                  onChanged: _controlIRLed,
                  activeColor: Colors.white,
                ),
                Icon(
                  Icons.expand_more,
                  color: isIRLedOn ? Colors.white : Colors.grey,
                ),
              ],
            ),
            tilePadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            childrenPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 0),
            expandedCrossAxisAlignment: CrossAxisAlignment.start,
            children: isIRLedOn 
              ? [
                  Divider(color: Colors.white30),
                  SizedBox(height: 12),
                  Text(
                    'Renk',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 12),
                  // Renk seçim butonları
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildColorButton('red', 'Kırmızı', Colors.red),
                      _buildColorButton('green', 'Yeşil', Colors.green),
                      _buildColorButton('blue', 'Mavi', Colors.blue),
                      _buildColorButton('white', 'Beyaz', Colors.white),
                    ],
                  ),
                  SizedBox(height: 20),
                  Text(
                    'Efektler',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 12),
                  // Efekt seçim butonları
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildEffectButton('flash', 'Flash'),
                        SizedBox(width: 10),
                        _buildEffectButton('strobe', 'Strobe'),
                        SizedBox(width: 10),
                        _buildEffectButton('fade', 'Fade'),
                        SizedBox(width: 10),
                        _buildEffectButton('smooth', 'Smooth'),
                      ],
                    ),
                  ),
                  SizedBox(height: 20),
                  Text(
                    'Parlaklık',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 12),
                  // Parlaklık kontrol butonları
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton(
                        onPressed: _decreaseIRLedBrightness,
                        child: Icon(Icons.remove, color: Colors.white),
                        style: ElevatedButton.styleFrom(
                          shape: CircleBorder(),
                          padding: EdgeInsets.all(12),
                          backgroundColor: Colors.black38,
                        ),
                      ),
                      SizedBox(width: 30),
                      ElevatedButton(
                        onPressed: _increaseIRLedBrightness,
                        child: Icon(Icons.add, color: Colors.white),
                        style: ElevatedButton.styleFrom(
                          shape: CircleBorder(),
                          padding: EdgeInsets.all(12),
                          backgroundColor: Colors.black38,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                ]
              : [],
          ),
        ),
      ),
    );
  }

  // IR LED renk seçim butonu
  Widget _buildColorButton(String colorName, String label, Color buttonColor) {
    bool isSelected = irLedColor == colorName;
    return Column(
      children: [
        GestureDetector(
          onTap: () => _setIRLedColor(colorName),
          child: AnimatedContainer(
            duration: Duration(milliseconds: 300),
            height: 45,
            width: 45,
            decoration: BoxDecoration(
              color: buttonColor,
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? Colors.white : Colors.transparent,
                width: 3,
              ),
              boxShadow: [
                BoxShadow(
                  color: buttonColor.withOpacity(0.6),
                  blurRadius: isSelected ? 12 : 5,
                  spreadRadius: isSelected ? 4 : 0,
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.white,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  // IR LED efekt seçim butonu
  Widget _buildEffectButton(String effectName, String label) {
    bool isSelected = irLedEffect == effectName;
    return GestureDetector(
      onTap: () => _setIRLedEffect(effectName),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white24 : Colors.black26,
          borderRadius: BorderRadius.circular(20),
          border: isSelected ? Border.all(color: Colors.white, width: 2) : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: Colors.white,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  // IR LED arka plan renklerini seçme
  List<Color> _getGradientColors() {
    switch (irLedColor) {
      case 'red':
        return [Colors.red.shade700, Colors.red.shade900];
      case 'green':
        return [Colors.green.shade600, Colors.green.shade900];
      case 'blue':
        return [Colors.blue.shade600, Colors.blue.shade900];
      case 'white':
      default:
        return [Color(0xFF6A11CB), Color(0xFF2575FC)]; // Mor-mavi gradyan
    }
  }

  // IR LED ikon rengini seçme
  Color _getIconColor() {
    switch (irLedColor) {
      case 'red':
        return Colors.white;
      case 'green':
        return Colors.white;
      case 'blue':
        return Colors.white;
      case 'white':
      default:
        return Colors.white;
    }
  }
}