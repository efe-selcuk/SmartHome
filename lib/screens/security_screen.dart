import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class SecurityScreen extends StatefulWidget {
  @override
  _SecurityScreenState createState() => _SecurityScreenState();
}

class _SecurityScreenState extends State<SecurityScreen> {
  final String socketUrl = 'ws://192.168.1.10:81';
  late WebSocketChannel _channel;
  late StreamSubscription _webSocketSubscription;
  late StreamController<List<int>> _streamController;
  bool isLiveStreaming = false;
  int lastFrameTime = 0;
  List<Uint8List> capturedImages = [];
  List<int> currentImageData = []; // To store the current image for fullscreen

  @override
  void initState() {
    super.initState();
    _streamController = StreamController<List<int>>();
  }

  void _connectToWebSocket() {
    _channel = WebSocketChannel.connect(Uri.parse(socketUrl));
    _webSocketSubscription = _channel.stream.listen(_onDataReceived);
    setState(() {
      isLiveStreaming = true;
    });
  }

  void _onDataReceived(dynamic data) {
    int currentTime = DateTime.now().millisecondsSinceEpoch;
    if (currentTime - lastFrameTime < 1000 / 15 + 120) return;
    lastFrameTime = currentTime;
    List<int> byteData = List<int>.from(data);
    if (isValidImage(byteData)) {
      currentImageData = byteData; // Update the current image data
      _streamController.add(byteData);
    }
  }

  bool isValidImage(List<int> byteData) {
    return byteData[0] == 0xFF && byteData[1] == 0xD8 && byteData[byteData.length - 2] == 0xFF && byteData[byteData.length - 1] == 0xD9;
  }

  void _captureScreenshot(List<int> imageData) {
    if (imageData.isNotEmpty) {
      setState(() {
        capturedImages.add(Uint8List.fromList(imageData));
      });
    }
  }

  void _showFullScreenImage(Uint8List imageData) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.black,
          body: Center(
            child: GestureDetector(
              onTap: () => Navigator.pop(context), // Tap to close
              child: Image.memory(imageData, fit: BoxFit.contain), // Show image centered
            ),
          ),
        ),
      ),
    );
  }

  void _showFullScreenLiveStream() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.black,
          body: Center(
            child: currentImageData.isNotEmpty
                ? Image.memory(Uint8List.fromList(currentImageData), fit: BoxFit.contain) // Centered
                : Center(child: CircularProgressIndicator(color: Colors.red)),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _channel.sink.close();
    _webSocketSubscription.cancel();
    _streamController.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text("Güvenlik Kamerası", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.red, // Tema rengini kırmızı yapıyoruz
      ),
      body: Column(
        children: [
          Expanded(
            flex: 3,
            child: Center(
              child: isLiveStreaming
                  ? StreamBuilder<List<int>>(
                stream: _streamController.stream,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return CircularProgressIndicator(color: Colors.red);
                  }
                  if (snapshot.hasData && isValidImage(snapshot.data!)) {
                    List<int> imageData = snapshot.data!;
                    return Stack(
                      children: [
                        GestureDetector(
                          onTap: () => _showFullScreenLiveStream(),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.memory(
                              Uint8List.fromList(imageData),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 20,
                          right: 20,
                          child: FloatingActionButton(
                            backgroundColor: Colors.red,
                            onPressed: () => _captureScreenshot(imageData),
                            child: Icon(Icons.camera_alt, color: Colors.white),
                          ),
                        ),
                      ],
                    );
                  }
                  return Text("Yayın Başlatılıyor...", style: TextStyle(color: Colors.black54));
                },
              )
                  : ElevatedButton(
                onPressed: _connectToWebSocket,
                child: Text("Canlı Yayını Başlat", style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red, // Buton rengini kırmızı yapıyoruz
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ),
          Divider(color: Colors.grey),
          Expanded(
            flex: 1,
            child: capturedImages.isNotEmpty
                ? ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: capturedImages.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: GestureDetector(
                    onTap: () => _showFullScreenImage(capturedImages[index]),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.memory(
                        capturedImages[index],
                        fit: BoxFit.cover,
                        width: 100,
                        height: 100,
                      ),
                    ),
                  ),
                );
              },
            )
                : Center(
              child: Text("Henüz görüntü alınmadı", style: TextStyle(color: Colors.black54)),
            ),
          ),
        ],
      ),
    );
  }
}