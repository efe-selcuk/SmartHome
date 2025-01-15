import 'package:flutter/material.dart';

class RoomCard extends StatelessWidget {
  final String roomName;
  final VoidCallback onTap;

  RoomCard({required this.roomName, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 5,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        color: Colors.red[50],
        child: Center(
          child: Text(
            roomName,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red[900]),
          ),
        ),
      ),
    );
  }
}
