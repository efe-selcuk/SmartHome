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
import 'package:smarthome/screens/control_panel_screen.dart';
import 'package:smarthome/screens/profile_screen.dart';
import 'package:smarthome/screens/notifications_screen.dart';
import 'package:smarthome/screens/settings_screen.dart';
import 'package:smarthome/screens/help_screen.dart';
import 'package:app_settings/app_settings.dart';
import 'package:smarthome/services/weather_service.dart';

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
  final WeatherService _weatherService = WeatherService();
  String humidity = '--';
  String windSpeed = '--';
  String weatherIcon = '';

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
        _showLocationDialog(
          'Konum Servisi Kapalı',
          'Hava durumu bilgilerini görebilmek için lütfen konum servisini etkinleştirin.',
          'Ayarlara Git',
          () async {
            if (await location.requestService()) {
              Navigator.pop(context);
              getUserLocation();
            }
          },
        );
        return;
      }
    }

    // Konum izni kontrolü
    permission = await location.hasPermission();
    if (permission == PermissionStatus.denied) {
      permission = await location.requestPermission();
      if (permission == PermissionStatus.denied) {
        _showLocationDialog(
          'Konum İzni Gerekli',
          'Hava durumu bilgilerini görebilmek için konum iznine ihtiyacımız var.',
          'İzin Ver',
          () async {
            Navigator.pop(context);
            getUserLocation();
          },
        );
        return;
      }
    }

    if (permission == PermissionStatus.deniedForever) {
      _showLocationDialog(
        'Konum İzni Gerekli',
        'Hava durumu bilgilerini görebilmek için uygulama ayarlarından konum iznini etkinleştirmeniz gerekiyor.',
        'Ayarlara Git',
        () async {
          await AppSettings.openAppSettings();
        },
      );
      return;
    }

    // Konum verisini al
    try {
      LocationData locationData = await location.getLocation();
      print('Kullanıcı Konumu: ${locationData.latitude}, ${locationData.longitude}');
      getWeatherData(locationData.latitude!, locationData.longitude!);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Konum alınamadı. Lütfen daha sonra tekrar deneyin.'),
          duration: Duration(seconds: 3),
        ),
      );
      print('Konum alırken hata oluştu: $e');
    }
  }

  // Konum izni dialog penceresi
  void _showLocationDialog(String title, String message, String buttonText, VoidCallback onPressed) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            title,
            style: TextStyle(
              color: Colors.red[900],
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.location_on,
                size: 64,
                color: Colors.red[900],
              ),
              SizedBox(height: 16),
              Text(
                message,
                style: TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Vazgeç',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ),
            ElevatedButton(
              onPressed: onPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[900],
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(buttonText),
            ),
          ],
        );
      },
    );
  }

  Future<void> getWeatherData(double latitude, double longitude) async {
    try {
      final weatherData = await _weatherService.getWeather(latitude, longitude);
      
      setState(() {
        temperature = weatherData['temperature'];
        weatherDescription = weatherData['weatherDescription'];
        humidity = weatherData['humidity'].toString();
        windSpeed = weatherData['windSpeed'].toString();
        weatherIcon = weatherData['icon'];
      });
    } catch (e) {
      print('Hava durumu verisi alınırken hata oluştu: $e');
      setState(() {
        temperature = '--';
        weatherDescription = 'Hata oluştu';
        humidity = '--';
        windSpeed = '--';
        weatherIcon = '';
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Hava durumu bilgisi alınamadı: ${e.toString()}'),
          duration: Duration(seconds: 3),
          backgroundColor: Colors.red[900],
        ),
      );
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
    Widget screen;
    switch (routeName) {
      case 'Kontrol Paneli':
        screen = ControlPanelScreen();
        break;
      case 'Profil':
        screen = ProfileScreen();
        break;
      case 'Bildirimler':
        screen = NotificationsScreen();
        break;
      case 'Ayarlar':
        screen = SettingsScreen();
        break;
      case 'Yardım':
        screen = HelpScreen();
        break;
      default:
        screen = Scaffold(
          appBar: AppBar(
            title: Text(routeName),
          ),
          body: Center(
            child: Text('$routeName ekranı'),
          ),
        );
    }

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => screen),
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
                              backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                              child: Icon(
                                Icons.person,
                                size: 40,
                                color: Theme.of(context).primaryColor,
                              ),
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
                  _buildWeatherCard(),
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
        backgroundColor: Theme.of(context).primaryColor,
        child: Icon(Icons.security),
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
            stops: [0.0, 0.3],
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
                  Row(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white,
                            width: 2,
                          ),
                        ),
                        child: CircleAvatar(
                          radius: 30,
                          backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                          child: Icon(
                            Icons.person,
                            size: 40,
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(left: 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                  Text(
                    '$firstName $lastName',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                              SizedBox(height: 4),
                  Text(
                                user != null ? user!.email ?? 'E-posta bulunamadı' : 'E-posta bulunamadı',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.home_work,
                          color: Colors.white,
                          size: 16,
                        ),
                        SizedBox(width: 8),
                        Text(
                          '${rooms.length} Oda',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            _buildDrawerSection(
              'Ana Özellikler',
              [
                _buildDrawerItem(Icons.dashboard_rounded, 'Kontrol Paneli', () => navigateTo('Kontrol Paneli')),
                _buildDrawerItem(Icons.security, 'Güvenlik', () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => SecurityScreen()),
                  );
                }),
              ],
            ),
            Divider(height: 0),
            _buildDrawerSection(
              'Ayarlar',
              [
                _buildDrawerItem(Icons.person, 'Profil', () => navigateTo('Profil')),
                _buildDrawerItem(Icons.notifications, 'Bildirimler', () => navigateTo('Bildirimler')),
                _buildDrawerItem(Icons.settings, 'Ayarlar', () => navigateTo('Ayarlar')),
                _buildDrawerItem(Icons.help_outline, 'Yardım', () => navigateTo('Yardım')),
              ],
            ),
            Divider(height: 0),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton.icon(
                onPressed: logOut,
                icon: Icon(Icons.logout),
                label: Text('Çıkış Yap'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerSection(String title, List<Widget> items) {
    return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            title,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ),
        ...items,
      ],
    );
  }

  Widget _buildDrawerItem(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Container(
        padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
          color: Theme.of(context).primaryColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: Theme.of(context).primaryColor,
          size: 20,
        ),
      ),
                    title: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: Icon(
        Icons.chevron_right,
        color: Colors.grey[400],
        size: 20,
      ),
      onTap: onTap,
      dense: true,
      visualDensity: VisualDensity.compact,
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
                ...predefinedRooms.map((room) => _buildRoomOption(room)),
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

  // Hava Durumu Widget'ı
  Widget _buildWeatherCard() {
    return Container(
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
            children: [
              if (weatherIcon.isNotEmpty)
                Image.network(
                  'https://openweathermap.org/img/w/$weatherIcon.png',
                  width: 50,
                  height: 50,
                  errorBuilder: (context, error, stackTrace) {
                    return Icon(
                      Icons.wb_sunny,
                      size: 40,
                      color: Colors.orange,
                    );
                  },
                )
              else
                Icon(
                  Icons.wb_sunny,
                  size: 40,
                  color: Colors.orange,
                ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
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
              ),
            ],
          ),
          SizedBox(height: 12),
          Divider(),
          SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildWeatherInfo(
                Icons.water_drop,
                'Nem',
                '$humidity%',
                Colors.blue,
              ),
              _buildWeatherInfo(
                Icons.air,
                'Rüzgar',
                '$windSpeed m/s',
                Colors.green,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWeatherInfo(
    IconData icon,
    String label,
    String value,
    Color color,
  ) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 12,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}
