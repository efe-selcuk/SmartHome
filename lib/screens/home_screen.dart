import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:location/location.dart';
import 'package:smarthome/screens/room_detail_screen.dart';
import 'package:smarthome/screens/login_screen.dart';
import 'package:smarthome/services/database_service.dart';
import 'package:smarthome/screens/security_screen.dart'; // Import the security screen
import 'package:smarthome/screens/profile_screen.dart';
import 'package:smarthome/screens/settings_screen.dart';
import 'package:smarthome/screens/help_screen.dart';
import 'package:smarthome/screens/automation_screen.dart'; // Import the automation screen
import 'package:app_settings/app_settings.dart';
import 'package:smarthome/services/weather_service.dart';
import 'package:smarthome/services/sensor_service.dart'; // Add this import
import 'dart:math' as math;

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
  String profilePicture = 'assets/images/adam.jpg'; // Default profile picture

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
          profilePicture = doc['profilePicture'] ?? 'assets/images/adam.jpg';
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
      case 'Profil':
        screen = ProfileScreen();
        break;
      case 'Ayarlar':
        screen = SettingsScreen();
        break;
      case 'Yardım':
        screen = HelpScreen();
        break;
      case 'Otomasyon':
        screen = AutomationScreen();
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
            expandedHeight: 150.0,
            floating: false,
            pinned: true,
            stretch: true,
            backgroundColor: Theme.of(context).primaryColor,
            elevation: 4,
            flexibleSpace: LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                // Calculate the app bar's current height to adjust content
                final expandRatio = (constraints.maxHeight - kToolbarHeight) / (150.0 - kToolbarHeight);
                final isCollapsed = expandRatio < 0.3;
                
                return FlexibleSpaceBar(
                  titlePadding: EdgeInsets.only(left: 20, bottom: 16),
                  centerTitle: false,
                  title: AnimatedOpacity(
                    duration: Duration(milliseconds: 200),
                    opacity: isCollapsed ? 1.0 : 1.0,
                    child: Text(
                      'Chakra',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.5,
                        shadows: [
                          Shadow(
                            blurRadius: 10.0,
                            color: Colors.black.withOpacity(0.3),
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                  ),
                  collapseMode: CollapseMode.pin,
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Gradient background with artistic design
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Theme.of(context).primaryColor,
                              Theme.of(context).primaryColor.withOpacity(0.7),
                            ],
                          ),
                        ),
                      ),
                      // Artistic overlay pattern
                      CustomPaint(
                        painter: ArtisticPatternPainter(),
                        child: Container(),
                      ),
                      // Content - Moved user profile to the top with higher padding
                      SafeArea(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 10, 20, 80),
                          child: Opacity(
                            opacity: expandRatio.clamp(0.0, 1.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: EdgeInsets.all(2),
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: Colors.white,
                                          width: 2,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.2),
                                            blurRadius: 8,
                                            offset: Offset(0, 3),
                                          ),
                                        ],
                                      ),
                                      child: GestureDetector(
                                        onTap: _showProfilePictureSelectionDialog,
                                        child: CircleAvatar(
                                          radius: 20,
                                          backgroundColor: Colors.white.withOpacity(0.2),
                                          backgroundImage: AssetImage(profilePicture),
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            'Hoş geldin 👋',
                                            style: TextStyle(
                                              color: Colors.white.withOpacity(0.9),
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          Text(
                                            '$firstName $lastName',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              shadows: [
                                                Shadow(
                                                  color: Colors.black26,
                                                  blurRadius: 5,
                                                  offset: Offset(0, 2),
                                                ),
                                              ],
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
                    ],
                  ),
                );
              },
            ),
            actions: [
              Builder(
                builder: (context) {
                  return IconButton(
                    icon: Icon(
                      Icons.menu_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
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
                  // Ana Göstergeler - Daha dolu bir görünüm için yeni bir widget ekliyoruz
                  _buildMainStats(),
                  SizedBox(height: 16),
                  
                  // Hava Durumu Kartı
                  _buildWeatherCard(),
                  SizedBox(height: 16),
                  
                  // Odalar Başlığı ve Ekleme Butonu
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Theme.of(context).primaryColor,
                                  Theme.of(context).primaryColor.withOpacity(0.8),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Theme.of(context).primaryColor.withOpacity(0.3),
                                  blurRadius: 10,
                                  offset: Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.home_work_rounded,
                              size: 24,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(width: 12),
                          Text(
                            'Odalar',
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                              color: Colors.black87,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                      ElevatedButton(
                        onPressed: () => _showAddRoomDialog(),
                        style: ElevatedButton.styleFrom(
                          elevation: 4,
                          shadowColor: Theme.of(context).primaryColor.withOpacity(0.4),
                          backgroundColor: Theme.of(context).primaryColor,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.add, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'Oda Ekle',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  
                  // Odalar Listesi
                  rooms.isEmpty
                      ? Center(
                          child: Container(
                            padding: EdgeInsets.all(30),
                            margin: EdgeInsets.symmetric(vertical: 20),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 20,
                                  offset: Offset(0, 10),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                Container(
                                  width: 100,
                                  height: 100,
                                  decoration: BoxDecoration(
                                    color: Colors.grey[100],
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.home_work_outlined,
                                    size: 60,
                                    color: Colors.grey[400],
                                  ),
                                ),
                                SizedBox(height: 24),
                                Text(
                                  'Henüz oda eklenmemiş',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey[800],
                                  ),
                                ),
                                SizedBox(height: 12),
                                Text(
                                  'İlk odanızı eklemek için "Oda Ekle" butonuna tıklayın',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 15,
                                    color: Colors.grey[600],
                                    height: 1.5,
                                  ),
                                ),
                                SizedBox(height: 24),
                                ElevatedButton(
                                  onPressed: () => _showAddRoomDialog(),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Theme.of(context).primaryColor,
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                  child: Text(
                                    'Oda Ekle',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      : GridView.builder(
                          shrinkWrap: true,
                          physics: NeverScrollableScrollPhysics(),
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                            childAspectRatio: 1.0,
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
      floatingActionButton: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).primaryColor.withOpacity(0.3),
              blurRadius: 15,
              offset: Offset(0, 6),
              spreadRadius: 0,
            ),
          ],
          borderRadius: BorderRadius.circular(30),
        ),
        child: FloatingActionButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => SecurityScreen()),
            );
          },
          backgroundColor: Theme.of(context).primaryColor,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          child: Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Theme.of(context).primaryColor,
                  Color.fromARGB(255, 180, 0, 0),
                ],
              ),
            ),
            child: Icon(
              Icons.security_rounded,
              size: 28,
              color: Colors.white,
            ),
          ),
        ),
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
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 20,
              offset: Offset(0, 10),
              spreadRadius: 0,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            children: [
              // Background decoration
              Positioned(
                right: -40,
                bottom: -40,
                child: Container(
                  width: 130,
                  height: 130,
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withOpacity(0.08),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              Positioned(
                left: -20,
                top: -20,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withOpacity(0.05),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              // Content
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Theme.of(context).primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(
                            _getRoomIcon(roomName),
                            size: 24,
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                        // AC Hızlı Kontrol Butonu
                        _buildACQuickControl(roomName),
                      ],
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
                          size: 14,
                          color: Colors.grey[600],
                        ),
                        SizedBox(width: 6),
                        FutureBuilder<Map<String, dynamic>?>(
                          future: _databaseService.loadRoomData(roomName),
                          builder: (context, snapshot) {
                            int deviceCount = 0;
                            
                            if (snapshot.hasData && snapshot.data != null) {
                              // Cihaz sayısını belirleme
                              final devices = snapshot.data!['devices'] as List<dynamic>?;
                              deviceCount = devices?.length ?? 0;
                            }
                            
                            return Text(
                              '$deviceCount Cihaz',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey[600],
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Hover effect overlay
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
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Klima hızlı kontrol butonu
  Widget _buildACQuickControl(String roomName) {
    return StatefulBuilder(
      builder: (context, setState) {
        return InkWell(
          borderRadius: BorderRadius.circular(30),
          onTap: () async {
            // Klima durum değişikliği için 
            Map<String, dynamic>? roomData = await _databaseService.loadRoomData(roomName);
            if (roomData != null) {
              bool isClimaOn = roomData['isClimaOn'] ?? false;
              
              // API ile klimayı aç/kapa
              bool success = await SensorService.setACStatus(!isClimaOn);
              
              if (success) {
                // Firestore'da durumu güncelle
                roomData['isClimaOn'] = !isClimaOn;
                
                // Klima sıcaklığı yoksa varsayılan değer ayarla
                if (!roomData.containsKey('climaTemp')) {
                  roomData['climaTemp'] = 22.0;
                }
                
                // Değişiklik zaman damgası ekle
                roomData['lastUpdated'] = DateTime.now().millisecondsSinceEpoch;
                
                await _databaseService.saveRoomData(roomName, roomData);
                setState(() {});  // StatefulBuilder'daki state'i güncelle
              }
            }
          },
          child: FutureBuilder<Map<String, dynamic>?>(
            future: _databaseService.loadRoomData(roomName),
            builder: (context, snapshot) {
              bool isClimaOn = false;
              
              if (snapshot.hasData && snapshot.data != null) {
                isClimaOn = snapshot.data!['isClimaOn'] ?? false;
              }
              
              return AnimatedContainer(
                duration: Duration(milliseconds: 300),
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isClimaOn 
                      ? Colors.blue.withOpacity(0.15) 
                      : Colors.grey.withOpacity(0.1),
                  shape: BoxShape.circle,
                  boxShadow: isClimaOn
                      ? [
                          BoxShadow(
                            color: Colors.blue.withOpacity(0.2),
                            blurRadius: 10,
                            spreadRadius: 1,
                          )
                        ]
                      : [],
                  border: Border.all(
                    color: isClimaOn 
                        ? Colors.blue.withOpacity(0.5) 
                        : Colors.transparent,
                    width: 2,
                  ),
                ),
                child: Icon(
                  Icons.ac_unit_rounded,
                  color: isClimaOn ? Colors.blue : Colors.grey[400],
                  size: 24,
                ),
              );
            },
          ),
        );
      },
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
                        child: GestureDetector(
                          onTap: _showProfilePictureSelectionDialog,
                          child: CircleAvatar(
                            radius: 30,
                            backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                            backgroundImage: AssetImage(profilePicture),
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
                _buildDrawerItem(Icons.security, 'Güvenlik', () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => SecurityScreen()),
                  );
                }),
                _buildDrawerItem(Icons.smart_toy, 'Otomasyon', () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => AutomationScreen()),
                  );
                }),
              ],
            ),
            Divider(height: 0),
            _buildDrawerSection(
              'Ayarlar',
              [
                _buildDrawerItem(Icons.person, 'Profil', () => navigateTo('Profil')),
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
            borderRadius: BorderRadius.circular(24),
          ),
          elevation: 10,
          backgroundColor: Colors.white,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.white,
                  Colors.grey[50]!,
                ],
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Theme.of(context).primaryColor,
                            Theme.of(context).primaryColor.withOpacity(0.8),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Theme.of(context).primaryColor.withOpacity(0.3),
                            blurRadius: 12,
                            offset: Offset(0, 5),
                          )
                        ],
                      ),
                      child: Icon(
                        Icons.add_home,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    SizedBox(width: 12),
                    Text(
                      'Oda Ekle',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 30),
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: Colors.grey[50],
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 10,
                        offset: Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      ...predefinedRooms.map((room) => _buildRoomOption(room)),
                    ],
                  ),
                ),
                SizedBox(height: 20),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.grey[600],
                    padding: EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Vazgeç',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildRoomOption(String roomName) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () {
          addRoom(roomName);
          Navigator.pop(context);
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _getRoomIcon(roomName),
                  size: 28,
                  color: Theme.of(context).primaryColor,
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Text(
                  roomName,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ),
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.add,
                  color: Theme.of(context).primaryColor,
                  size: 20,
                ),
              ),
            ],
          ),
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
    // Hava durumuna göre renkler ve ikonlar
    final Map<String, List<Color>> weatherGradients = {
      'Clear': [Color(0xFF3399fe), Color(0xFF66c6ff)], // Açık - Mavi tonları
      'Clouds': [Color(0xFF6c7689), Color(0xFF8c96a8)], // Bulutlu - Gri tonları
      'Rain': [Color(0xFF4B6CB7), Color(0xFF182848)], // Yağmurlu - Koyu mavi
      'Thunderstorm': [Color(0xFF283E51), Color(0xFF4B79A1)], // Fırtınalı - Koyu lacivert
      'Snow': [Color(0xFF8e9eab), Color(0xFFeef2f3)], // Karlı - Gri-beyaz
      'Mist': [Color(0xFF757F9A), Color(0xFFD7DDE8)], // Sisli - Gri-bej
      'default': [Color(0xFF3399fe), Color(0xFF66c6ff)], // Varsayılan
    };
    
    // Hava durumuna göre gradient seçimi
    List<Color> gradientColors = weatherGradients['default']!;
    
    // Mevcut hava durumuna göre gradient belirle
    if (weatherDescription.isNotEmpty) {
      for (String condition in weatherGradients.keys) {
        if (weatherDescription.toLowerCase().contains(condition.toLowerCase())) {
          gradientColors = weatherGradients[condition]!;
          break;
        }
      }
    }
    
    // Hava durumuna göre arka plan ikonları
    IconData weatherBgIcon = Icons.wb_sunny;
    if (weatherDescription.toLowerCase().contains('cloud')) {
      weatherBgIcon = Icons.cloud;
    } else if (weatherDescription.toLowerCase().contains('rain')) {
      weatherBgIcon = Icons.grain;
    } else if (weatherDescription.toLowerCase().contains('thunder')) {
      weatherBgIcon = Icons.flash_on;
    } else if (weatherDescription.toLowerCase().contains('snow')) {
      weatherBgIcon = Icons.ac_unit;
    } else if (weatherDescription.toLowerCase().contains('mist') || 
               weatherDescription.toLowerCase().contains('fog')) {
      weatherBgIcon = Icons.water;
    }
    
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradientColors,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: gradientColors[0].withOpacity(0.3),
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Arka plan dekoratif ikonları
          Positioned(
            right: -15,
            top: -20,
            child: Icon(
              weatherBgIcon,
              size: 80,
              color: Colors.white.withOpacity(0.1),
            ),
          ),
          // Ana içerik
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Konum bilgisi
              Row(
                children: [
                  Icon(
                    Icons.location_on,
                    color: Colors.white.withOpacity(0.8),
                    size: 14,
                  ),
                  SizedBox(width: 4),
                  Text(
                    'Bulunduğunuz Konum',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8),
              // Hava durumu ana bilgileri
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Hava durumu ikonu
                  Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: weatherIcon.isNotEmpty
                      ? Image.network(
                          'https://openweathermap.org/img/w/$weatherIcon.png',
                          width: 35,
                          height: 35,
                          errorBuilder: (context, error, stackTrace) => Icon(
                            weatherBgIcon,
                            size: 26,
                            color: Colors.white,
                          ),
                        )
                      : Icon(
                          weatherBgIcon,
                          size: 26,
                          color: Colors.white,
                        ),
                  ),
                  SizedBox(width: 12),
                  // Sıcaklık ve açıklama
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              temperature,
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              '°C',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white.withOpacity(0.8),
                              ),
                            ),
                          ],
                        ),
                        Text(
                          weatherDescription,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Nem ve rüzgar bilgisi
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.water_drop, color: Colors.white, size: 14),
                          SizedBox(width: 4),
                          Text(
                            '$humidity%',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.air, color: Colors.white, size: 14),
                          SizedBox(width: 4),
                          Text(
                            '$windSpeed m/s',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Ana istatistikler widget'ı
  Widget _buildMainStats() {
    return FutureBuilder<Map<String, double>>(
      future: SensorService.fetchSensorData(),
      builder: (context, snapshot) {
        // Varsayılan değerler (veri yüklenirken veya hata durumunda)
        String tempValue = '--°C';
        String humidityValue = '--%';
        
        // Eğer veri başarıyla alındıysa gerçek değerleri kullan
        if (snapshot.hasData && snapshot.data != null) {
          tempValue = '${snapshot.data!['temperature']?.toStringAsFixed(1) ?? '--'}°C';
          humidityValue = '${snapshot.data!['humidity']?.toStringAsFixed(0) ?? '--'}%';
        }
        
        return Container(
          padding: EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 12,
                offset: Offset(0, 5),
              )
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(Icons.thermostat, 'Sıcaklık', tempValue, Colors.orange),
              _buildVerticalDivider(),
              _buildStatItem(Icons.water_drop, 'Nem', humidityValue, Colors.blue),
              _buildVerticalDivider(),
              _buildStatItem(Icons.shield, 'Güvenlik', 'Aktif', Colors.green),
            ],
          ),
        );
      }
    );
  }

  Widget _buildVerticalDivider() {
    return Container(
      height: 40,
      width: 1,
      color: Colors.grey.withOpacity(0.2),
    );
  }

  Widget _buildStatItem(IconData icon, String label, String value, Color color) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  void _showProfilePictureSelectionDialog() {
    final List<String> availableImages = [
      'assets/images/adam.jpg',
      'assets/images/siyah.jpg',
      'assets/images/sari.jpg',
      'assets/images/kel.jpg',
      'assets/images/cocuk.jpg',
      'assets/images/kadin.jpg',
      'assets/images/ciddi.jpg',
    ];

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          elevation: 10,
          backgroundColor: Colors.white,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.white,
                  Colors.grey[50]!,
                ],
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Theme.of(context).primaryColor,
                            Theme.of(context).primaryColor.withOpacity(0.8),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Theme.of(context).primaryColor.withOpacity(0.3),
                            blurRadius: 12,
                            offset: Offset(0, 5),
                          )
                        ],
                      ),
                      child: Icon(
                        Icons.person,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    SizedBox(width: 12),
                    Text(
                      'Profil Fotoğrafı Seç',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 30),
                Container(
                  height: 300,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: Colors.grey[50],
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 10,
                        offset: Offset(0, 5),
                      ),
                    ],
                  ),
                  child: GridView.builder(
                    padding: EdgeInsets.all(12),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    itemCount: availableImages.length,
                    itemBuilder: (context, index) {
                      return GestureDetector(
                        onTap: () {
                          _updateProfilePicture(availableImages[index]);
                          Navigator.pop(context);
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: profilePicture == availableImages[index]
                                  ? Theme.of(context).primaryColor
                                  : Colors.transparent,
                              width: 3,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 5,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.asset(
                              availableImages[index],
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                SizedBox(height: 20),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.grey[600],
                    padding: EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Vazgeç',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _updateProfilePicture(String imagePath) async {
    if (user != null) {
      try {
        await _firestore.collection('users').doc(user!.uid).update({
          'profilePicture': imagePath,
        });
        setState(() {
          profilePicture = imagePath;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Profil fotoğrafı güncellendi'),
            backgroundColor: Theme.of(context).primaryColor,
            duration: Duration(seconds: 2),
          ),
        );
      } catch (e) {
        print("Error updating profile picture: $e");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Profil fotoğrafı güncellenirken bir hata oluştu'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }
}

// Artistic Pattern Painter for background design
class ArtisticPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    
    // Desenler için rastgele değerler
    final random = math.Random(42); // Sabit seed ile rastgele değerler
    
    // Desenli arka plan
    for (int i = 0; i < 8; i++) {
      // Yatay çizgiler
      double y = size.height * (0.2 + 0.1 * i);
      double amplitude = 15 + random.nextDouble() * 10;
      double frequency = 0.02 + random.nextDouble() * 0.04;
      
      Path wavePath = Path();
      wavePath.moveTo(0, y);
      
      for (double x = 0; x <= size.width; x += 5) {
        double dy = math.sin(x * frequency) * amplitude;
        wavePath.lineTo(x, y + dy);
      }
      
      canvas.drawPath(wavePath, paint);
    }
    
    // Dikey çizgiler
    for (int i = 0; i < 6; i++) {
      double x = size.width * (0.1 + 0.2 * i);
      
      Path path = Path();
      path.moveTo(x, 0);
      path.lineTo(x, size.height * 0.5);
      
      canvas.drawPath(path, paint);
    }
    
    // Daireler
    for (int i = 0; i < 8; i++) {
      double x = random.nextDouble() * size.width;
      double y = random.nextDouble() * size.height * 0.6;
      double radius = 10 + random.nextDouble() * 40;
      
      canvas.drawCircle(
        Offset(x, y), 
        radius, 
        Paint()
          ..color = Colors.white.withOpacity(0.04)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.8
      );
    }
    
    // Noktalar
    final dotPaint = Paint()
      ..color = Colors.white.withOpacity(0.2)
      ..style = PaintingStyle.fill;
      
    for (int i = 0; i < 30; i++) {
      double x = random.nextDouble() * size.width;
      double y = random.nextDouble() * size.height * 0.7;
      double radius = 1 + random.nextDouble() * 2;
      
      canvas.drawCircle(Offset(x, y), radius, dotPaint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return false;
  }
}
