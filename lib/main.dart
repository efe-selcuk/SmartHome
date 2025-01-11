import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Home',
      theme: ThemeData(
        primaryColor: Colors.red[900],
        scaffoldBackgroundColor: Colors.white,
        fontFamily: 'Poppins',
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.red[900],
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
          iconTheme: IconThemeData(color: Colors.white),
        ),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: Colors.red[900],
          foregroundColor: Colors.white,
        ),
        textTheme: TextTheme(
          bodyMedium: TextStyle(color: Colors.black),
          bodySmall: TextStyle(color: Colors.black54),
        ),
      ),
      home: HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<String> rooms = [];
  final List<String> predefinedRooms = [
    "Salon",
    "Yatak Odası",
    "Mutfak",
    "Banyo",
    "Çocuk Odası",
  ];

  void addRoom(String roomName) {
    setState(() {
      if (!rooms.contains(roomName)) {
        rooms.add(roomName);
      }
    });
  }

  void navigateToRoomDetails(String roomName) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RoomDetailsScreen(roomName: roomName),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Smart Home Dashboard'),
        actions: [
          IconButton(
            icon: Icon(Icons.settings),
            onPressed: () {
              // Ayarlar sayfasına gitmek için kullanılabilir.
            },
          ),
          IconButton(
            icon: Icon(Icons.account_circle),
            onPressed: () {
              // Profil sayfasına gitmek için kullanılabilir.
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Merhaba mesajı
            Text(
              'Merhaba, Efe',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(
              'Evinize hoş geldiniz',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            SizedBox(height: 20),

            // Odalar başlığı ve odaların listesi
            Text(
              'Odalar',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Expanded(
              child: rooms.isEmpty
                  ? Center(child: Text('Henüz oda eklenmemiş.'))
                  : GridView.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 1.2,
                ),
                itemCount: rooms.length,
                itemBuilder: (context, index) {
                  final room = rooms[index];
                  return GestureDetector(
                    onTap: () => navigateToRoomDetails(room),
                    child: Card(
                      elevation: 5,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      color: Colors.red[50],
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            getRoomIcon(room),
                            size: 60,
                            color: Colors.red[900],
                          ),
                          SizedBox(height: 10),
                          Text(
                            room,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.red[900],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
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
                title: Text('Oda Seç'),
                content: Container(
                  width: double.minPositive,
                  child: ListView(
                    shrinkWrap: true,
                    children: predefinedRooms.map((room) {
                      return ListTile(
                        title: Text(room),
                        onTap: () {
                          addRoom(room);
                          Navigator.pop(context);
                        },
                      );
                    }).toList(),
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

  IconData getRoomIcon(String roomName) {
    switch (roomName) {
      case 'Salon':
        return Icons.tv; // Oturma odası ikonu
      case 'Yatak Odası':
        return Icons.bed; // Yatak ikonu
      case 'Mutfak':
        return Icons.kitchen; // Mutfak ikonu
      case 'Banyo':
        return Icons.bathtub; // Banyo ikonu
      case 'Çocuk Odası':
        return Icons.toys; // Çocuk odası ikonu
      default:
        return Icons.home; // Genel ev ikonu
    }
  }
}

class RoomDetailsScreen extends StatefulWidget {
  final String roomName;

  RoomDetailsScreen({required this.roomName});

  @override
  _RoomDetailsScreenState createState() => _RoomDetailsScreenState();
}

class _RoomDetailsScreenState extends State<RoomDetailsScreen> {
  List<String> devices = [];
  double? temperature;
  double? humidity;
  bool isClimaOn = false;
  bool isLightOn = false;
  bool isTvOn = false;

  // Cihaz eklemek için kullanılacak dialog
  void showDeviceDialog() {
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
                    fetchSensorData();  // Sıcaklık & Nem verilerini al
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
  }

  // Cihazı eklemek
  void addDevice(String deviceName) {
    setState(() {
      if (!devices.contains(deviceName)) {
        devices.add(deviceName);
      }
    });
  }

  // ESP32'den sıcaklık ve nem verilerini almak
  Future<void> fetchSensorData() async {
    try {
      final response = await http.get(Uri.parse('http://192.168.1.8')); // ESP32'nin IP adresini kullanın
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          temperature = data['temperature']?.toDouble();
          humidity = data['humidity']?.toDouble();
        });
      } else {
        throw Exception('Veri alınamadı.');
      }
    } catch (e) {
      print('Hata: $e');
    }
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
              '${widget.roomName}',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            Text('Bu odada aşağıdaki cihazlar bulunmaktadır:',
                style: TextStyle(fontSize: 18)),
            SizedBox(height: 20),

            // Cihazlar listesi
            devices.isEmpty
                ? Center(child: Text('Henüz cihaz eklenmemiş.'))
                : Expanded(
              child: ListView.builder(
                itemCount: devices.length,
                itemBuilder: (context, index) {
                  if (devices[index] == 'Sıcaklık & Nem') {
                    return Card(
                      child: ListTile(
                        leading: Icon(Icons.thermostat, color: Colors.red),
                        title: Text(
                          'Sıcaklık: ${temperature?.toStringAsFixed(1)}°C, Nem: ${humidity?.toStringAsFixed(1)}%',
                        ),
                      ),
                    );
                  } else if (devices[index] == 'Klima') {
                    return Card(
                      child: ListTile(
                        leading: Icon(Icons.ac_unit, color: Colors.blue),
                        title: Text('Klima'),
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
                        leading: Icon(Icons.lightbulb, color: Colors.yellow),
                        title: Text('Işık'),
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
                  }
                  return Container();
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: showDeviceDialog,
        child: Icon(Icons.add),
      ),
    );
  }
}
