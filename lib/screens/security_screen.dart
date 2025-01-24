import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class SecurityScreen extends StatefulWidget {
  @override
  _SecurityScreenState createState() => _SecurityScreenState();
}

class _SecurityScreenState extends State<SecurityScreen> {
  String esp32CamUrl = "http://192.168.1.100/"; // ESP32-CAM cihazının IP adresi
  String imageUrl = "";

  // Fotoğraf çek ve URL'yi güncelle
  Future<void> fetchImage() async {
    try {
      final response = await http.get(Uri.parse(esp32CamUrl)); // HTTP GET isteği gönder

      if (response.statusCode == 200) {
        setState(() {
          imageUrl = esp32CamUrl; // Çekilen fotoğrafın URL'si güncelleniyor
        });
      } else {
        print("ESP32-CAM bağlantı hatası: ${response.statusCode}");
        showError("ESP32-CAM bağlantı hatası: ${response.statusCode}");
      }
    } catch (e) {
      print("Hata oluştu: $e");
      showError("ESP32-CAM bağlantısı başarısız.");
    }
  }

  void showError(String message) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Hata"),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text("Tamam"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Güvenlik Sistemi"),
        actions: [
          IconButton(
            icon: Icon(Icons.camera_alt),
            onPressed: fetchImage, // Fotoğraf çekmek için buton
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "Kamera Görüntüsü",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            imageUrl.isNotEmpty
                ? Image.network(
              imageUrl,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Center(
                  child: CircularProgressIndicator(
                    value: loadingProgress.expectedTotalBytes != null
                        ? loadingProgress.cumulativeBytesLoaded /
                        loadingProgress.expectedTotalBytes!
                        : null,
                  ),
                );
              },
              errorBuilder: (context, error, stackTrace) {
                return Text("Görüntü yüklenemedi.");
              },
            )
                : Text("Görüntü henüz çekilmedi."),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: fetchImage,
        child: Icon(Icons.refresh),
      ),
    );
  }
}
