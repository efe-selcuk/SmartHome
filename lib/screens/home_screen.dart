import 'package:flutter/material.dart';
import 'package:smarthome/screens/room_detail_screen.dart';

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
