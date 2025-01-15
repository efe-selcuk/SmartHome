import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:smarthome/screens/room_detail_screen.dart';
import 'package:smarthome/screens/login_screen.dart';
import 'package:smarthome/services/database_service.dart';

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
  String firstName = '';  // Ad
  String lastName = '';   // Soyad

  // Firestore referansı
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Firebase Authentication'dan kullanıcıyı al
  Future<void> loadUserData() async {
    final FirebaseAuth _auth = FirebaseAuth.instance;
    final currentUser = _auth.currentUser;
    if (currentUser != null) {
      setState(() {
        user = currentUser;
      });
      // Firestore'dan kullanıcı adı ve soyadını al
      await fetchUserDetails(currentUser.uid);
    }
  }

  // Firestore'dan kullanıcı bilgilerini al
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

  // Firebase'den odaları yükle
  Future<void> loadRooms() async {
    List<String> loadedRooms = await _databaseService.loadRoomNames();
    setState(() {
      rooms = loadedRooms;
    });
  }

  // Çıkış yapma işlemi
  void logOut() {
    FirebaseAuth.instance.signOut();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => LoginScreen()),
    );
  }

  // Oda ekleme işlemi
  void addRoom(String roomName) {
    setState(() {
      if (!rooms.contains(roomName)) {
        rooms.add(roomName);
        _databaseService.saveRoomData(roomName, {});
      }
    });
  }

  // Oda detaylarına yönlendirme
  void navigateToRoomDetails(String roomName) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RoomDetailsScreen(roomName: roomName),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    loadRooms();
    loadUserData(); // Firebase'den kullanıcı verisini yükle
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Smart Home Dashboard'),
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
                    '$firstName $lastName', // Ad Soyad
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
              'Merhaba, $firstName', // Ana ekranda sadece ad
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

  // Yönlendirme işlemi
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
}
