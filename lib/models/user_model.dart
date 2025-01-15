class UserModel {
  String email;
  Map<String, dynamic> settings;
  List<Map<String, dynamic>> rooms;
  List<Map<String, dynamic>> devices;

  UserModel({
    required this.email,
    required this.settings,
    required this.rooms,
    required this.devices,
  });

  // Firestore'dan kullanıcı verisini almak için bir factory method
  factory UserModel.fromFirestore(Map<String, dynamic> firestoreData) {
    return UserModel(
      email: firestoreData['email'] ?? '',
      settings: firestoreData['settings'] ?? {},
      rooms: List<Map<String, dynamic>>.from(firestoreData['rooms'] ?? []),
      devices: List<Map<String, dynamic>>.from(firestoreData['devices'] ?? []),
    );
  }

  // Kullanıcı verisini Firestore'a kaydetmek için bir method
  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'settings': settings,
      'rooms': rooms,
      'devices': devices,
    };
  }
}
