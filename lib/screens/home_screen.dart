import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:location/location.dart'; // geolocator yerine location import ediyoruz
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:smarthome/screens/room_detail_screen.dart';
import 'package:smarthome/screens/login_screen.dart';
import 'package:smarthome/services/database_service.dart';
import 'package:smarthome/services/sensor_service.dart';

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

  final DatabaseService _databaseService = DatabaseService();
  User? user;
  String firstName = '';
  String lastName = '';

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String temperature = '--';
  String weatherDescription = '--';

  // location paketi ile kullanıcı verilerini yükleme
  Future<void> loadUserData() async {
    final FirebaseAuth _auth = FirebaseAuth.instance;
    final currentUser = _auth.currentUser;
    if (currentUser != null) {
      setState(() {
        user = currentUser;
      });
      await fetchUserDetails(currentUser.uid);
    }
  }

  Future<void> fetchUserDetails(String userId) async {
    try {
      DocumentSnapshot doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists) {
        setState(() {
          firstName = doc['firstName'] ?? 'Ad Bulunamadı';
          lastName = doc['lastName'] ?? 'Soyad Bulunamadı';
        });
      }
    } catch (e) {
      print("Error fetching user details: $e");
    }
  }

  Future<void> loadRooms() async {
    List<String> loadedRooms = await _databaseService.loadRoomNames();
    setState(() {
      rooms = loadedRooms;
    });
  }

  // Konum iznini kontrol et ve konum verisini al
  Future<void> getUserLocation() async {
    Location location = Location();

    bool serviceEnabled;
    PermissionStatus permission;

    // Konum servislerinin etkin olup olmadığını kontrol et
    serviceEnabled = await location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await location.requestService();
      if (!serviceEnabled) {
        print("Konum servisi kapalı. Lütfen etkinleştirin.");
        return;
      }
    }

    // Konum izni kontrolü
    permission = await location.hasPermission();
    if (permission == PermissionStatus.denied) {
      permission = await location.requestPermission();
      if (permission == PermissionStatus.denied) {
        print("Konum izni reddedildi. Lütfen izni verin.");
        return;
      }
    }

    if (permission == PermissionStatus.deniedForever) {
      print("Konum izni kalıcı olarak reddedildi. Uygulama ayarlarına gidin.");
      return;
    }

    // Konum verisini al
    try {
      LocationData locationData = await location.getLocation();
      print('Kullanıcı Konumu: ${locationData.latitude}, ${locationData.longitude}');
      getWeatherData(locationData.latitude!, locationData.longitude!);
    } catch (e) {
      print('Konum alırken hata oluştu: $e');
    }
  }

  Future<void> getWeatherData(double latitude, double longitude) async {
    final String url = "https://api.openweathermap.org/data/2.5/weather?lat=$latitude&lon=$longitude&appid=b265ec116d325a1b81af0bc0f5d3b50e&units=metric";
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      var data = json.decode(response.body);
      setState(() {
        temperature = data['main']['temp'].toString();
        weatherDescription = data['weather'][0]['description'];
      });
    } else {
      throw Exception('Hava durumu verisi alınamadı');
    }
  }

  void logOut() {
    FirebaseAuth.instance.signOut();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => LoginScreen()),
    );
  }

  @override
  void initState() {
    super.initState();
    loadRooms();
    loadUserData();
    getUserLocation();
  }

  void addRoom(String roomName) {
    setState(() {
      if (!rooms.contains(roomName)) {
        rooms.add(roomName);
        _databaseService.saveRoomData(roomName, {});
      }
    });
  }

  void navigateTo(String routeName) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: Text(routeName),
          ),
          body: Center(
            child: Text('$routeName ekranı'),
          ),
        ),
      ),
    );
  }

  void deleteRoom(String roomName) {
    setState(() {
      rooms.remove(roomName);
    });
    _databaseService.deleteRoomData(roomName);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Chakrapp'),
        actions: [
          Builder(
            builder: (context) {
              return IconButton(
                icon: Icon(Icons.menu),
                onPressed: () {
                  Scaffold.of(context).openEndDrawer();
                },
              );
            },
          ),
        ],
      ),
      endDrawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.red[900],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundImage: AssetImage('assets/images/profile_placeholder.png'),
                  ),
                  SizedBox(height: 10),
                  Text(
                    '$firstName $lastName',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    user != null ? user!.email ?? 'E-posta bulunamadı' : 'E-posta bulunamadı',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: Icon(Icons.person),
              title: Text('Profil'),
              onTap: () => navigateTo('Profil'),
            ),
            ListTile(
              leading: Icon(Icons.settings),
              title: Text('Ayarlar'),
              onTap: () => navigateTo('Ayarlar'),
            ),
            Divider(),
            ListTile(
              leading: Icon(Icons.logout),
              title: Text('Çıkış Yap'),
              onTap: logOut,
            ),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Merhaba, $firstName',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(
              'Evinize hoş geldiniz',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            SizedBox(height: 20),
            Text(
              'Odalar',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Container(
              padding: EdgeInsets.all(16.0),
              margin: EdgeInsets.only(bottom: 20.0),
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.5),
                    spreadRadius: 5,
                    blurRadius: 7,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Text(
                    'Sıcaklık: $temperature°C',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Hava Durumu: $weatherDescription',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ],
              ),
            ),
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
                    onLongPress: () {
                      showDialog(
                        context: context,
                        builder: (context) {
                          return AlertDialog(
                            title: Text('Oda Sil'),
                            content: Text('$room odasını silmek istiyor musunuz?'),
                            actions: [
                              TextButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                },
                                child: Text('İptal'),
                              ),
                              TextButton(
                                onPressed: () {
                                  deleteRoom(room);
                                  Navigator.pop(context);
                                },
                                child: Text('Sil'),
                              ),
                            ],
                          );
                        },
                      );
                    },
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
                          int roomNumber = predefinedRooms.indexOf(room) + 1;
                          SensorService.controlLight(roomNumber, true); // Işık açılıyor
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
        return Icons.tv;
      case 'Yatak Odası':
        return Icons.bed;
      case 'Mutfak':
        return Icons.kitchen;
      case 'Banyo':
        return Icons.bathtub;
      case 'Çocuk Odası':
        return Icons.toys;
      default:
        return Icons.home;
    }
  }

  void navigateToRoomDetails(String roomName) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RoomDetailsScreen(roomName: roomName),
      ),
    );
  }
}