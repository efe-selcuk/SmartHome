import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DatabaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Kullanıcıya ait Firestore koleksiyonu
  String get currentUserId {
    return _auth.currentUser?.uid ?? '';
  }

  // Odaya ait verileri Firestore'a kaydetme
  Future<void> saveRoomData(String roomName, Map<String, dynamic> data) async {
    try {
      String userId = currentUserId;
      if (userId.isEmpty) {
        print("Kullanıcı kimliği mevcut değil!");
        return;
      }

      // Kullanıcıya ait room verisini kaydet
      DocumentReference roomDoc = _firestore
          .collection('users')
          .doc(userId)
          .collection('rooms')
          .doc(roomName);
      await roomDoc.set(data, SetOptions(merge: true)); // merge: true verileri günceller
      print("Veri kaydedildi: $roomName");
    } catch (e) {
      print("Firestore verisi kaydetme hatası: $e");
    }
  }

  // Kullanıcıya ait odaları Firestore'dan al
  Future<Map<String, dynamic>?> loadRoomData(String roomName) async {
    try {
      String userId = currentUserId;
      if (userId.isEmpty) {
        print("Kullanıcı kimliği mevcut değil!");
        return null;
      }

      DocumentReference roomDoc = _firestore
          .collection('users')
          .doc(userId)
          .collection('rooms')
          .doc(roomName);
      DocumentSnapshot roomSnapshot = await roomDoc.get();

      if (roomSnapshot.exists) {
        print("Veri yüklendi: $roomName");
        return roomSnapshot.data() as Map<String, dynamic>;
      } else {
        print("Oda bulunamadı: $roomName");
      }
    } catch (e) {
      print("Firestore verisi alma hatası: $e");
    }
    return null; // Eğer veri bulunamazsa
  }

  // Kullanıcının odalarını yükleme
  Future<List<String>> loadRoomNames() async {
    try {
      String userId = currentUserId;
      if (userId.isEmpty) {
        print("Kullanıcı kimliği mevcut değil!");
        return [];
      }

      QuerySnapshot roomsSnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('rooms')
          .get();

      return roomsSnapshot.docs.map((doc) => doc.id).toList();
    } catch (e) {
      print("Kullanıcının odaları alınırken hata: $e");
      return [];
    }
  }
}