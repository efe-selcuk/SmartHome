import 'package:flutter/material.dart';
import 'package:flex_color_picker/flex_color_picker.dart'; // Renk Seçici
import 'package:smarthome/services/sensor_service.dart'; // SensorService'i import ettik

class RoomDetailsScreen extends StatefulWidget {
  final String roomName;

  RoomDetailsScreen({required this.roomName});

  @override
  _RoomDetailsScreenState createState() => _RoomDetailsScreenState();
}

class _RoomDetailsScreenState extends State<RoomDetailsScreen> {
  List<String> devices = [];
  bool isClimaOn = false;
  bool isLightOn = false;
  bool isTvOn = false;
  double? temperature;
  double? humidity;
  double? lightIntensity = 50.0; // Işık yoğunluğu varsayalım
  double? climaTemperature = 22.0; // Klima sıcaklık varsayalım
  Color lightColor = Colors.white; // Işık rengi varsayalım

  // Cihazları eklemek için
  void addDevice(String deviceName) {
    setState(() {
      if (!devices.contains(deviceName)) {
        devices.add(deviceName);
      }
    });
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
    Color pickedColor = lightColor; // Varsayılan renk
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
            },
            showColorCode: true, // Renk kodunu göster
            wheelDiameter: 250, // Renk çarkı çapı
          ),
          actions: [
            TextButton(
              onPressed: () {
                setState(() {
                  lightColor = pickedColor;
                });
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
    fetchSensorData();  // İlk olarak sıcaklık ve nem verilerini al
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

            // Cihazlar listesi
            devices.isEmpty
                ? Center(child: Text('Henüz cihaz eklenmemiş.'))
                : Expanded(
              child: ListView.builder(
                itemCount: devices.length,
                itemBuilder: (context, index) {
                  if (devices[index] == 'Klima') {
                    return Card(
                      child: ListTile(
                        leading: Icon(Icons.ac_unit, color: Colors.blue),
                        title: Text('Klima'),
                        subtitle: Column(
                          children: [
                            Text('Derece: ${climaTemperature?.toStringAsFixed(1)}°C'),
                            Slider(
                              value: climaTemperature ?? 22.0,
                              min: 16.0,
                              max: 30.0,
                              onChanged: (value) {
                                setState(() {
                                  climaTemperature = value;
                                });
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
                          },
                        ),
                      ),
                    );
                  } else if (devices[index] == 'Işık') {
                    return Card(
                      child: ListTile(
                        leading: Icon(Icons.lightbulb, color: lightColor),
                        title: Text('Işık'),
                        subtitle: Column(
                          children: [
                            Text('Renk: ${lightColor.toString()}'),
                            Slider(
                              value: lightIntensity ?? 50.0,
                              min: 0.0,
                              max: 100.0,
                              onChanged: (value) {
                                setState(() {
                                  lightIntensity = value;
                                });
                              },
                            ),
                            ElevatedButton(
                              onPressed: _showColorPicker,  // Renk seçici butonu
                              child: Text("Rengi Seç"),
                            ),
                          ],
                        ),
                        trailing: Switch(
                          value: isLightOn,
                          onChanged: (value) {
                            setState(() {
                              isLightOn = value;
                            });
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
                        title: Text('Klima'),
                        onTap: () {
                          addDevice('Klima');
                          Navigator.pop(context);
                        },
                      ),
                      ListTile(
                        title: Text('Işık'),
                        onTap: () {
                          addDevice('Işık');
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
                          fetchSensorData();
                          Navigator.pop(context);
                        },
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: Text('Kapat'),
                  ),
                ],
              );
            },
          );
        },
        child: Icon(Icons.add),
      ),
    );
  }
}
