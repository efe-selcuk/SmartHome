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

  // Odayı silme metodu
  Future<void> deleteRoomData(String roomName) async {
    try {
      String userId = currentUserId;
      if (userId.isEmpty) {
        print("Kullanıcı kimliği mevcut değil!");
        return;
      }

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('rooms')
          .doc(roomName)
          .delete();
      print("Oda silindi: $roomName");
    } catch (e) {
      print("Odayı silerken hata oluştu: $e");
    }
  }

  // Kullanıcı profil bilgilerini getirme
  Future<Map<String, dynamic>?> getUserProfile() async {
    try {
      String userId = currentUserId;
      if (userId.isEmpty) {
        print("Kullanıcı kimliği mevcut değil!");
        return null;
      }

      DocumentReference userDoc = _firestore.collection('users').doc(userId);
      DocumentSnapshot userSnapshot = await userDoc.get();

      if (userSnapshot.exists) {
        print("Kullanıcı profili yüklendi");
        return userSnapshot.data() as Map<String, dynamic>;
      } else {
        print("Kullanıcı profili bulunamadı");
        return null;
      }
    } catch (e) {
      print("Kullanıcı profili alınırken hata: $e");
      return null;
    }
  }

  // Kullanıcı profil bilgilerini güncelleme
  Future<bool> updateUserProfile(Map<String, dynamic> data) async {
    try {
      String userId = currentUserId;
      if (userId.isEmpty) {
        print("Kullanıcı kimliği mevcut değil!");
        return false;
      }

      DocumentReference userDoc = _firestore.collection('users').doc(userId);
      await userDoc.set(data, SetOptions(merge: true));
      print("Kullanıcı profili güncellendi");
      return true;
    } catch (e) {
      print("Kullanıcı profili güncellenirken hata: $e");
      return false;
    }
  }

  // Şifre sıfırlama e-postası gönderme
  Future<bool> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      print("Şifre sıfırlama e-postası gönderildi: $email");
      return true;
    } catch (e) {
      print("Şifre sıfırlama e-postası gönderilirken hata: $e");
      return false;
    }
  }
  
  // Şifre değiştirme
  Future<Map<String, dynamic>> changePassword(String currentPassword, String newPassword) async {
    try {
      User? user = _auth.currentUser;
      if (user == null) {
        return {
          'success': false, 
          'message': 'Kullanıcı oturum açmamış'
        };
      }
      
      // E-posta ve mevcut şifre ile kimlik doğrulama
      AuthCredential credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );
      
      // Yeniden kimlik doğrulama
      try {
        await user.reauthenticateWithCredential(credential);
      } catch (e) {
        print("Kimlik doğrulama hatası: $e");
        return {
          'success': false, 
          'message': 'Mevcut şifre yanlış'
        };
      }
      
      // Şifreyi güncelle
      await user.updatePassword(newPassword);
      
      print("Şifre başarıyla güncellendi");
      return {
        'success': true, 
        'message': 'Şifre başarıyla güncellendi'
      };
    } catch (e) {
      print("Şifre güncellenirken hata: $e");
      String errorMessage = 'Şifre güncellenirken bir hata oluştu';
      
      // Firebase hata kodları kontrolü
      if (e is FirebaseAuthException) {
        switch (e.code) {
          case 'weak-password':
            errorMessage = 'Şifre çok zayıf, daha güçlü bir şifre seçin';
            break;
          case 'requires-recent-login':
            errorMessage = 'Bu işlem için yeniden giriş yapmanız gerekiyor';
            break;
          default:
            errorMessage = e.message ?? errorMessage;
        }
      }
      
      return {
        'success': false, 
        'message': errorMessage
      };
    }
  }
  
  // E-posta değiştirme
  Future<bool> updateEmail(String newEmail, String password) async {
    try {
      User? user = _auth.currentUser;
      if (user == null) {
        print("Kullanıcı oturum açmamış!");
        return false;
      }
      
      // Kullanıcıyı yeniden kimlik doğrulaması için
      AuthCredential credential = EmailAuthProvider.credential(
        email: user.email!,
        password: password,
      );
      
      await user.reauthenticateWithCredential(credential);
      await user.updateEmail(newEmail);
      
      // Firestore'daki e-posta bilgisini de güncelle
      await _firestore.collection('users').doc(user.uid).update({'email': newEmail});
      
      print("E-posta başarıyla güncellendi: $newEmail");
      return true;
    } catch (e) {
      print("E-posta güncellenirken hata: $e");
      return false;
    }
  }
  
  // Kullanıcının bildirim tercihlerini güncelleme
  Future<bool> updateNotificationPreferences(Map<String, bool> preferences) async {
    try {
      String userId = currentUserId;
      if (userId.isEmpty) {
        print("Kullanıcı kimliği mevcut değil!");
        return false;
      }
      
      await _firestore.collection('users').doc(userId).update({
        'notificationPreferences': preferences
      });
      
      print("Bildirim tercihleri güncellendi");
      return true;
    } catch (e) {
      print("Bildirim tercihleri güncellenirken hata: $e");
      return false;
    }
  }
}
