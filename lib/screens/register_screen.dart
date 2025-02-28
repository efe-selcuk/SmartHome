import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Firestore'u ekleyin
import 'package:smarthome/screens/home_screen.dart';  // Giriş sonrası yönlendirilecek ekran

class RegisterScreen extends StatefulWidget {
  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _firstNameController = TextEditingController(); // İsim alanı
  final _lastNameController = TextEditingController();  // Soyisim alanı
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance; // Firestore örneği

  bool _isLoading = false;

  Future<void> _register() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Firebase Authentication ile kullanıcı oluşturma
      final UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      if (userCredential.user != null) {
        // Kullanıcı oluşturulduktan sonra, Firestore'a isim ve soyisim ekleyelim
        await _firestore.collection('users').doc(userCredential.user!.uid).set({
          'firstName': _firstNameController.text.trim(),
          'lastName': _lastNameController.text.trim(),
          'email': _emailController.text.trim(),
          'createdAt': Timestamp.now(), // Kaydın oluşturulma tarihi
        });

        // Başarılı bir şekilde kayıt olduktan sonra anasayfaya yönlendirme ve önceki ekranları temizleme
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => HomeScreen()),
              (Route<dynamic> route) => false, // Bu satır önceki tüm ekranları temizler
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text('Hata'),
            content: Text(e.toString()),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: Text('Tamam'),
              ),
            ],
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.home, size: 30, color: Colors.white),
            SizedBox(width: 10),
            Text('Kayıt Ol'),
          ],
        ),
        centerTitle: true,
        backgroundColor: Colors.red[900],
        elevation: 0,
        bottom: PreferredSize(
          child: Container(
            color: Colors.white,
            height: 1,
          ),
          preferredSize: Size.fromHeight(1),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo veya resim ekleyelim
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(50),
                    color: Colors.red[900]!.withOpacity(0.1),
                  ),
                  child: Icon(
                    Icons.home,
                    size: 100,
                    color: Colors.red[900],
                  ),
                ),
                SizedBox(height: 40),
                // İsim giriş
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 8,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _firstNameController,
                    decoration: InputDecoration(
                      labelText: 'İsim',
                      hintText: 'İsminizi girin',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person, color: Colors.red[900]),
                    ),
                  ),
                ),
                SizedBox(height: 20),
                // Soyisim giriş
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 8,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _lastNameController,
                    decoration: InputDecoration(
                      labelText: 'Soyisim',
                      hintText: 'Soyisminizi girin',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person, color: Colors.red[900]),
                    ),
                  ),
                ),
                SizedBox(height: 20),
                // E-posta giriş
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 8,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _emailController,
                    decoration: InputDecoration(
                      labelText: 'E-posta',
                      hintText: 'E-posta adresinizi girin',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.email, color: Colors.red[900]),
                    ),
                    keyboardType: TextInputType.emailAddress,
                  ),
                ),
                SizedBox(height: 20),
                // Şifre giriş
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 8,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _passwordController,
                    decoration: InputDecoration(
                      labelText: 'Şifre',
                      hintText: 'Şifrenizi girin',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.lock, color: Colors.red[900]),
                    ),
                    obscureText: true,
                  ),
                ),
                SizedBox(height: 20),
                // Kayıt ol butonu
                ElevatedButton(
                  onPressed: _isLoading ? null : _register,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red[400],
                    padding: EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    minimumSize: Size(double.infinity, 50),
                  ),
                  child: _isLoading
                      ? CircularProgressIndicator(color: Colors.white)
                      : Text(
                    'Kayıt Ol',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                SizedBox(height: 20),
                // Geri dön butonu
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: Text(
                    'Zaten bir hesabınız var mı? Giriş yap',
                    style: TextStyle(
                      color: Colors.blue,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}