import 'package:flutter/material.dart';
import 'room_card.dart';

class RoomList extends StatelessWidget {
  final List<String> rooms;
  final Function(String) onRoomTap;

  RoomList({required this.rooms, required this.onRoomTap});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1.2,
      ),
      itemCount: rooms.length,
      itemBuilder: (context, index) {
        return RoomCard(
          roomName: rooms[index],
          onTap: () => onRoomTap(rooms[index]),
        );
      },
    );
  }
}
