import 'package:flutter/material.dart';
import 'package:smarthome/screens/room_detail_screen.dart';
import 'package:smarthome/screens/login_screen.dart'; // Login ekranını eklemeyi unutmayın

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

  void navigateTo(String routeName) {
    // Yönlendirme işlemleri (Örneğin: Profil, Ayarlar)
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

  void logOut() {
    // Çıkış yapıldığında login ekranına yönlendirme
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => LoginScreen()),
    );
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
                  Scaffold.of(context).openEndDrawer(); // Sağ tarafta menüyü açar
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
                    backgroundImage: AssetImage('assets/images/profile_placeholder.png'), // Profil resmi
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Efe',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'efe@example.com',
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
