import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:io';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';

// En başta global bir değişken olarak API key tanımlayalım
String weatherApiKey = '';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    // Önce kök dizindeki .env dosyasını yüklemeyi deneyelim
    bool dotenvLoaded = false;
    
    try {
      await dotenv.load(fileName: ".env");
      dotenvLoaded = true;
      print(".env dosyası kök dizinden yüklendi");
    } catch (e) {
      print("Kök dizindeki .env dosyası yüklenemedi: $e");
      
      // Kök dizinde başarısız olursa, assets klasöründen deneyelim
      try {
        await dotenv.load(fileName: "assets/.env");
        dotenvLoaded = true;
        print(".env dosyası assets klasöründen yüklendi");
      } catch (assetError) {
        print("assets/.env dosyası da yüklenemedi: $assetError");
      }
    }
    
    // API anahtarını global değişkene atayalım
    if (dotenvLoaded) {
      weatherApiKey = dotenv.env['WEATHER_API_KEY'] ?? '';
      print("API anahtarı yüklendi: ${weatherApiKey.isNotEmpty ? 'Başarılı' : 'Başarısız'}");
    }
    
    if (weatherApiKey.isEmpty) {
      // .env dosyasından yüklenemezse, hardcoded değeri kullan (geçici çözüm)
      weatherApiKey = '0187db96d590aeb744a5c51c22726cde';
      print("API anahtarı .env'den okunamadı, sabit değer kullanılıyor.");
    }
    
    await Firebase.initializeApp();
    runApp(MyApp());
  } catch (e) {
    print("Hata: $e");
    
    // Hata durumunda da hardcoded API key kullan
    weatherApiKey = '0187db96d590aeb744a5c51c22726cde';
    print("Hata nedeniyle sabit API anahtarı kullanılıyor");
    
    try {
      await Firebase.initializeApp();
      runApp(MyApp());
    } catch (firebaseError) {
      runApp(ErrorApp(error: firebaseError.toString()));
    }
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

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
      home: AuthWrapper(),
    );
  }
}

class ErrorApp extends StatelessWidget {
  final String error;

  const ErrorApp({super.key, required this.error});

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

/// Kullanıcı oturum durumunu kontrol eder ve uygun ekranı gösterir.
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          // Bağlantı sırasında bir yükleme ekranı göster
          return Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }
        if (snapshot.hasData) {
          // Kullanıcı oturum açmışsa HomeScreen'e yönlendir
          return HomeScreen();
        }
        // Kullanıcı oturum açmamışsa LoginScreen'e yönlendir
        return LoginScreen();
      },
    );
  }
}
