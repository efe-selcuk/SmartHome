import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/transition_screen.dart';

// En başta global bir değişken olarak API key tanımlayalım
String weatherApiKey = '';

// Tema ve Dil için global değişkenler
bool isDarkMode = false;
String appLanguage = 'Türkçe';

// Ayarları kaydetmek için yardımcı fonksiyon
Future<void> saveAppSettings() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('darkMode', isDarkMode);
    await prefs.setString('language', appLanguage);
  } catch (e) {
    print("Ayarlar kaydedilemedi: $e");
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Ayarları yükle
  try {
    final prefs = await SharedPreferences.getInstance();
    isDarkMode = prefs.getBool('darkMode') ?? false;
    appLanguage = prefs.getString('language') ?? 'Türkçe';
    print("Ayarlar yüklendi: Karanlık mod: $isDarkMode, Dil: $appLanguage");
  } catch (e) {
    print("Ayarlar yüklenemedi: $e");
  }
  
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
    runApp(const MyApp());
  } catch (e) {
    print("Hata: $e");
    
    // Hata durumunda da hardcoded API key kullan
    weatherApiKey = '0187db96d590aeb744a5c51c22726cde';
    print("Hata nedeniyle sabit API anahtarı kullanılıyor");
    
    try {
      await Firebase.initializeApp();
      runApp(const MyApp());
    } catch (firebaseError) {
      runApp(ErrorApp(error: firebaseError.toString()));
    }
  }
}

// Tema ve dil ayarları için InheritedWidget
class AppSettings extends InheritedWidget {
  final bool isDarkMode;
  final String language;
  final Function(bool) updateTheme;
  final Function(String) updateLanguage;

  const AppSettings({
    super.key,
    required this.isDarkMode,
    required this.language,
    required this.updateTheme,
    required this.updateLanguage,
    required super.child,
  });

  static AppSettings of(BuildContext context) {
    final result = context.dependOnInheritedWidgetOfExactType<AppSettings>();
    assert(result != null, 'No AppSettings found in context');
    return result!;
  }

  @override
  bool updateShouldNotify(AppSettings oldWidget) {
    return isDarkMode != oldWidget.isDarkMode || 
           language != oldWidget.language;
  }
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  // ThemeMode için getter
  ThemeMode get themeMode => isDarkMode ? ThemeMode.dark : ThemeMode.light;
  
  // Tema değiştirme metodu
  void updateTheme(bool darkMode) async {
    if (isDarkMode != darkMode) {
      setState(() {
        isDarkMode = darkMode;
      });
      saveAppSettings();
    }
  }
  
  // Dil değiştirme metodu
  void updateLanguage(String language) async {
    if (appLanguage != language) {
      setState(() {
        appLanguage = language;
      });
      saveAppSettings();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppSettings(
      isDarkMode: isDarkMode,
      language: appLanguage,
      updateTheme: updateTheme,
      updateLanguage: updateLanguage,
      child: MaterialApp(
        title: 'Smart Home',
        themeMode: themeMode,
        theme: ThemeData(
          useMaterial3: true,
          primaryColor: Colors.red[900],
          scaffoldBackgroundColor: Colors.white,
          fontFamily: 'Poppins',
          colorScheme: ColorScheme.light(
            primary: Colors.red[900]!,
            secondary: Colors.red[700]!,
            surface: Colors.white,
            background: Colors.grey[50]!,
            onBackground: Colors.black87,
            onSurface: Colors.black,
          ),
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
          cardTheme: CardTheme(
            color: Colors.white,
            shadowColor: Colors.black.withOpacity(0.1),
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[900],
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          switchTheme: SwitchThemeData(
            thumbColor: MaterialStateProperty.resolveWith<Color?>((states) {
              if (states.contains(MaterialState.selected)) {
                return Colors.white;
              }
              return null;
            }),
            trackColor: MaterialStateProperty.resolveWith<Color?>((states) {
              if (states.contains(MaterialState.selected)) {
                return Colors.red[900];
              }
              return null;
            }),
          ),
          textTheme: TextTheme(
            bodyMedium: TextStyle(color: Colors.black87),
            bodySmall: TextStyle(color: Colors.black54),
            titleMedium: TextStyle(color: Colors.black, fontWeight: FontWeight.w500),
          ),
          dividerTheme: DividerThemeData(
            color: Colors.grey[300],
            thickness: 1,
          ),
        ),
        darkTheme: ThemeData(
          useMaterial3: true,
          primaryColor: Colors.red[800],
          scaffoldBackgroundColor: Color(0xFF121212),
          fontFamily: 'Poppins',
          colorScheme: ColorScheme.dark(
            primary: Colors.red[800]!,
            secondary: Colors.red[600]!,
            surface: Color(0xFF1E1E1E),
            background: Color(0xFF121212),
            onBackground: Colors.white,
            onSurface: Colors.white,
          ),
          appBarTheme: AppBarTheme(
            backgroundColor: Color(0xFF1E1E1E),
            titleTextStyle: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
            iconTheme: IconThemeData(color: Colors.white),
          ),
          floatingActionButtonTheme: FloatingActionButtonThemeData(
            backgroundColor: Colors.red[800],
            foregroundColor: Colors.white,
          ),
          cardTheme: CardTheme(
            color: Color(0xFF2C2C2C),
            shadowColor: Colors.black.withOpacity(0.3),
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[800],
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          switchTheme: SwitchThemeData(
            thumbColor: MaterialStateProperty.resolveWith<Color?>((states) {
              if (states.contains(MaterialState.selected)) {
                return Colors.white;
              }
              return null;
            }),
            trackColor: MaterialStateProperty.resolveWith<Color?>((states) {
              if (states.contains(MaterialState.selected)) {
                return Colors.red[800];
              }
              return null;
            }),
          ),
          textTheme: TextTheme(
            bodyMedium: TextStyle(color: Colors.white),
            bodySmall: TextStyle(color: Colors.white70),
            titleMedium: TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
          ),
          dividerTheme: DividerThemeData(
            color: Colors.grey[800],
            thickness: 1,
          ),
        ),
        home: AuthWrapper(),
      ),
    );
  }
}

// Yardımcı sınıflar
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
          // Kullanıcı oturum açmışsa TransitionScreen'e yönlendir
          return TransitionScreen();
        }
        // Kullanıcı oturum açmamışsa LoginScreen'e yönlendir
        return LoginScreen();
      },
    );
  }
}
