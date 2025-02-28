import 'package:cloud_firestore/cloud_firestore.dart';

class DeviceService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Tüm cihazları getir
  Future<List<Map<String, dynamic>>> getAllDevices() async {
    List<Map<String, dynamic>> allDevices = [];
    
    try {
      // Tüm odaları al
      QuerySnapshot roomsSnapshot = await _firestore.collection('rooms').get();
      
      // Her odadaki cihazları al
      for (var room in roomsSnapshot.docs) {
        QuerySnapshot devicesSnapshot = await room.reference.collection('devices').get();
        
        // Cihazları listeye ekle
        for (var device in devicesSnapshot.docs) {
          Map<String, dynamic> deviceData = device.data() as Map<String, dynamic>;
          deviceData['id'] = device.id;
          deviceData['roomId'] = room.id;
          deviceData['roomName'] = room['name'];
          allDevices.add(deviceData);
        }
      }
      
      return allDevices;
    } catch (e) {
      print('Cihazları getirirken hata: $e');
      return [];
    }
  }

  // Cihaz durumunu güncelle
  Future<bool> updateDeviceStatus(String roomId, String deviceId, bool isActive) async {
    try {
      await _firestore
          .collection('rooms')
          .doc(roomId)
          .collection('devices')
          .doc(deviceId)
          .update({'isActive': isActive});
      return true;
    } catch (e) {
      print('Cihaz durumu güncellenirken hata: $e');
      return false;
    }
  }

  // Cihaz ekle
  Future<bool> addDevice(String roomId, Map<String, dynamic> deviceData) async {
    try {
      await _firestore
          .collection('rooms')
          .doc(roomId)
          .collection('devices')
          .add(deviceData);
      return true;
    } catch (e) {
      print('Cihaz eklenirken hata: $e');
      return false;
    }
  }

  // Cihaz sil
  Future<bool> deleteDevice(String roomId, String deviceId) async {
    try {
      await _firestore
          .collection('rooms')
          .doc(roomId)
          .collection('devices')
          .doc(deviceId)
          .delete();
      return true;
    } catch (e) {
      print('Cihaz silinirken hata: $e');
      return false;
    }
  }
} 