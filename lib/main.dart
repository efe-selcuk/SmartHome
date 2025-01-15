import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';  // Firebase Core paketini ekleyin
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();  // Uygulama başlatılmadan önce Firebase'i başlatmak için
  try {
    await Firebase.initializeApp();  // Firebase'i başlatın
    runApp(MyApp());  // Başarıyla başlatıldıktan sonra uygulamayı çalıştır
  } catch (e) {
    runApp(ErrorApp(error: e.toString()));  // Firebase başlatılamazsa hata mesajını göster
  }
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Home',
      theme: ThemeData(
        primaryColor: Colors.red[900],
        scaffoldBackgroundColor: Colors.white,
        fontFamily: 'Poppins',
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.red[900],
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
          iconTheme: IconThemeData(color: Colors.white),
        ),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: Colors.red[900],
          foregroundColor: Colors.white,
        ),
        textTheme: TextTheme(
          bodyMedium: TextStyle(color: Colors.black),
          bodySmall: TextStyle(color: Colors.black54),
        ),
      ),
      home: HomeScreen(),
    );
  }
}

class ErrorApp extends StatelessWidget {
  final String error;

  ErrorApp({required this.error});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Firebase Error',
      home: Scaffold(
        appBar: AppBar(
          title: Text('Firebase Error'),
        ),
        body: Center(
          child: Text(
            'Firebase bağlantısı hatalı: $error',
            style: TextStyle(fontSize: 16, color: Colors.red),
          ),
        ),
      ),
    );
  }
}
