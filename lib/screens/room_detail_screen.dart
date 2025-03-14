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
  double? temperature;
  double? humidity;
  double lightIntensity = 50.0;
  double climaTemperature = 22.0;
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
                      onPressed: () => _showAddDeviceDialog(),
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
                          }
                          return Container();
                        },
                      ),
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
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Cihaz Ekle',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
                SizedBox(height: 20),
                _buildDeviceOption(
                  icon: Icons.lightbulb_outline,
                  title: 'Işık',
                  onTap: () {
                    addDevice('Işık');
                    Navigator.pop(context);
                  },
                ),
                _buildDeviceOption(
                  icon: Icons.ac_unit,
                  title: 'Klima',
                  onTap: () {
                    addDevice('Klima');
                    Navigator.pop(context);
                  },
                ),
                _buildDeviceOption(
                  icon: Icons.tv,
                  title: 'Akıllı TV',
                  onTap: () {
                    addDevice('Akıllı TV');
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
          ),
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
}