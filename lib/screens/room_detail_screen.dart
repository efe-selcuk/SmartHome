import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flex_color_picker/flex_color_picker.dart';
import 'package:smarthome/services/sensor_service.dart';
import 'package:smarthome/services/database_service.dart';
import 'dart:async';

class RoomDetailsScreen extends StatefulWidget {
  final String roomName;

  RoomDetailsScreen({required this.roomName});

  @override
  _RoomDetailsScreenState createState() => _RoomDetailsScreenState();
}

class _RoomDetailsScreenState extends State<RoomDetailsScreen> {
  List<String> devices = [];
  bool isClimaOn = false;
  bool isLightOn = false; // Işık durumu sadece switch ile kontrol edilecek
  bool isTvOn = false;
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
    _loadRoomData();
    // Periyodik veri güncellemeleri başlatılıyor
    _startPeriodicUpdates();
  }

  @override
  void dispose() {
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

  // Periyodik veri güncellemelerini durdur
  void _stopPeriodicUpdates() {
    if (_timer != null) {
      _timer!.cancel();
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
    int room = 1;  // Odanın numarasını burada belirtin, örneğin 1. oda
    await SensorService.controlLight(room, isOn);  // ESP32'ye ışığı açma/kapama komutu gönder
    _saveRoomData();  // Veriyi kaydet
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.roomName} Detayları'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${widget.roomName} Odası',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            devices.isEmpty
                ? Center(child: Text('Henüz cihaz eklenmemiş.'))
                : Expanded(
              child: ListView.builder(
                itemCount: devices.length,
                itemBuilder: (context, index) {
                  if (devices[index] == 'Işık') {
                    return Card(
                      child: ListTile(
                        leading: Icon(Icons.lightbulb, color: lightColor),
                        title: Text('Işık'),
                        subtitle: Column(
                          children: [
                            // Işık rengini yuvarlak bir kutuda göstermek için
                            Container(
                              height: 40,
                              width: 40,
                              decoration: BoxDecoration(
                                color: lightColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                            Slider(
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
                            ElevatedButton(
                              onPressed: _showColorPicker,
                              child: Text("Rengi Seç"),
                            ),
                          ],
                        ),
                        trailing: Switch(
                          value: isLightOn,
                          onChanged: (value) {
                            // Işığı açma veya kapama
                            _controlLight(value);
                          },
                        ),
                      ),
                    );
                  } else if (devices[index] == 'Klima') {
                    return Card(
                      child: ListTile(
                        leading: Icon(Icons.ac_unit, color: Colors.blue),
                        title: Text('Klima'),
                        subtitle: Column(
                          children: [
                            Text('Derece: ${climaTemperature.toStringAsFixed(1)}°C'),
                            Slider(
                              value: climaTemperature,
                              min: 16.0,
                              max: 30.0,
                              onChanged: (value) {
                                setState(() {
                                  climaTemperature = value;
                                });
                                _saveRoomData();
                              },
                            ),
                          ],
                        ),
                        trailing: Switch(
                          value: isClimaOn,
                          onChanged: (value) {
                            setState(() {
                              isClimaOn = value;
                            });
                            _saveRoomData();
                          },
                        ),
                      ),
                    );
                  } else if (devices[index] == 'Akıllı TV') {
                    return Card(
                      child: ListTile(
                        leading: Icon(Icons.tv, color: Colors.black),
                        title: Text('Akıllı TV'),
                        trailing: Switch(
                          value: isTvOn,
                          onChanged: (value) {
                            setState(() {
                              isTvOn = value;
                            });
                            _saveRoomData();
                          },
                        ),
                      ),
                    );
                  } else if (devices[index] == 'Sıcaklık & Nem') {
                    return Card(
                      child: ListTile(
                        leading: Icon(Icons.thermostat, color: Colors.red),
                        title: Text(
                          'Sıcaklık: ${temperature?.toStringAsFixed(1)}°C, Nem: ${humidity?.toStringAsFixed(1)}%',
                        ),
                      ),
                    );
                  }
                  return Container();
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) {
              return AlertDialog(
                title: Text('Cihaz Seç'),
                content: Container(
                  width: double.minPositive,
                  child: ListView(
                    shrinkWrap: true,
                    children: [
                      ListTile(
                        title: Text('Işık'),
                        onTap: () {
                          addDevice('Işık');
                          Navigator.pop(context);
                        },
                      ),
                      ListTile(
                        title: Text('Klima'),
                        onTap: () {
                          addDevice('Klima');
                          Navigator.pop(context);
                        },
                      ),
                      ListTile(
                        title: Text('Akıllı TV'),
                        onTap: () {
                          addDevice('Akıllı TV');
                          Navigator.pop(context);
                        },
                      ),
                      ListTile(
                        title: Text('Sıcaklık & Nem'),
                        onTap: () {
                          addDevice('Sıcaklık & Nem');
                          Navigator.pop(context);
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
        child: Icon(Icons.add),
      ),
    );
  }
}