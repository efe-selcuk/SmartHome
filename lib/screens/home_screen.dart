import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:location/location.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:smarthome/screens/room_detail_screen.dart';
import 'package:smarthome/screens/login_screen.dart';
import 'package:smarthome/services/database_service.dart';
import 'package:smarthome/services/sensor_service.dart';
import 'package:smarthome/screens/security_screen.dart'; // Import the security screen

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

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
    final FirebaseAuth auth = FirebaseAuth.instance;
    final currentUser = auth.currentUser;
    if (currentUser != null) {
      setState(() {
        user = currentUser;
      });
      await fetchUserDetails(currentUser.uid);
    }
  }

  Future<void> fetchUserDetails(String userId) async {
    try {
      DocumentSnapshot doc =
          await _firestore.collection('users').doc(userId).get();
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
      print(
          'Kullanıcı Konumu: ${locationData.latitude}, ${locationData.longitude}');
      getWeatherData(locationData.latitude!, locationData.longitude!);
    } catch (e) {
      print('Konum alırken hata oluştu: $e');
    }
  }

  Future<void> getWeatherData(double latitude, double longitude) async {
    final String url =
        "https://api.openweathermap.org/data/2.5/weather?lat=$latitude&lon=$longitude&appid=b265ec116d325a1b81af0bc0f5d3b50e&units=metric";
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
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200.0,
            floating: false,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: EdgeInsets.only(left: 16, bottom: 16),
              title: Text(
                'Chakra',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                ),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Theme.of(context).primaryColor,
                      Theme.of(context).primaryColor.withOpacity(0.8),
                    ],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: 20),
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 30,
                              backgroundImage: AssetImage('assets/images/profile_placeholder.png'),
                            ),
                            SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Hoş geldin,',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 16,
                                    ),
                                  ),
                                  Text(
                                    '$firstName $lastName',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: Icon(Icons.notifications_none),
                onPressed: () {
                  // Bildirimler için
                },
              ),
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
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Hava Durumu Kartı
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
                    child: Row(
                      children: [
                        Icon(
                          Icons.wb_sunny,
                          size: 40,
                          color: Colors.orange,
                        ),
                        SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '$temperature°C',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              weatherDescription,
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 24),
                  
                  // Odalar Başlığı ve Ekleme Butonu
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Odalar',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: () => _showAddRoomDialog(),
                        icon: Icon(Icons.add),
                        label: Text('Oda Ekle'),
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
                  
                  // Odalar Listesi
                  rooms.isEmpty
                      ? Center(
                          child: Column(
                            children: [
                              Icon(
                                Icons.home_work_outlined,
                                size: 64,
                                color: Colors.grey[400],
                              ),
                              SizedBox(height: 16),
                              Text(
                                'Henüz oda eklenmemiş',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        )
                      : GridView.builder(
                          shrinkWrap: true,
                          physics: NeverScrollableScrollPhysics(),
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                            childAspectRatio: 1.2,
                          ),
                          itemCount: rooms.length,
                          itemBuilder: (context, index) {
                            return _buildRoomCard(rooms[index]);
                          },
                        ),
                ],
              ),
            ),
          ),
        ],
      ),
      endDrawer: _buildDrawer(),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => SecurityScreen()),
          );
        },
        child: Icon(Icons.security),
        backgroundColor: Theme.of(context).primaryColor,
      ),
    );
  }

  Widget _buildRoomCard(String roomName) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => RoomDetailsScreen(roomName: roomName),
          ),
        );
      },
      onLongPress: () => _showDeleteConfirmation(roomName),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 15,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            children: [
              // Arkaplan Dekorasyon
              Positioned(
                right: -20,
                bottom: -20,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              // İçerik
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        _getRoomIcon(roomName),
                        size: 32,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                    SizedBox(height: 12),
                    Text(
                      roomName,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.devices,
                          size: 16,
                          color: Colors.grey[600],
                        ),
                        SizedBox(width: 4),
                        Text(
                          '4 Cihaz',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Hover Efekti için Overlay
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => RoomDetailsScreen(roomName: roomName),
                      ),
                    );
                  },
                  onLongPress: () => _showDeleteConfirmation(roomName),
                  splashColor: Theme.of(context).primaryColor.withOpacity(0.1),
                  highlightColor: Theme.of(context).primaryColor.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getRoomIcon(String roomName) {
    switch (roomName.toLowerCase()) {
      case 'salon':
        return Icons.living;
      case 'yatak odası':
        return Icons.bed;
      case 'mutfak':
        return Icons.kitchen;
      case 'banyo':
        return Icons.bathtub;
      case 'çocuk odası':
        return Icons.child_care;
      default:
        return Icons.room;
    }
  }

  Widget _buildDrawer() {
    return Drawer(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).primaryColor,
              Colors.white,
            ],
          ),
        ),
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.transparent,
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
            _buildDrawerItem(Icons.person, 'Profil', () => navigateTo('Profil')),
            _buildDrawerItem(Icons.settings, 'Ayarlar', () => navigateTo('Ayarlar')),
            Divider(),
            _buildDrawerItem(Icons.logout, 'Çıkış Yap', logOut),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: Theme.of(context).primaryColor),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: onTap,
    );
  }

  void _showAddRoomDialog() {
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
                  'Oda Ekle',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
                SizedBox(height: 20),
                ...predefinedRooms.map((room) => _buildRoomOption(room)).toList(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildRoomOption(String roomName) {
    return InkWell(
      onTap: () {
        addRoom(roomName);
        Navigator.pop(context);
      },
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
              _getRoomIcon(roomName),
              size: 24,
              color: Theme.of(context).primaryColor,
            ),
            SizedBox(width: 16),
            Text(
              roomName,
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

  void _showDeleteConfirmation(String roomName) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: Colors.white,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.delete_outline,
                    color: Colors.red,
                    size: 32,
                  ),
                ),
                SizedBox(height: 16),
                Text(
                  'Odayı Sil',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  '$roomName odasını silmek istediğinizden emin misiniz?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 16,
                  ),
                ),
                SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        'Vazgeç',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        deleteRoom(roomName);
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Sil',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
