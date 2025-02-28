import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class SecurityScreen extends StatefulWidget {
  const SecurityScreen({super.key});

  @override
  _SecurityScreenState createState() => _SecurityScreenState();
}

class _SecurityScreenState extends State<SecurityScreen> {
  final String socketUrl = 'ws://192.168.1.6:81';
  WebSocketChannel? _channel;
  StreamController<Uint8List>? _streamController;
  bool isLiveStreaming = false;
  List<Uint8List> capturedImages = [];
  Uint8List? currentFrame;

  @override
  void initState() {
    super.initState();
    _streamController = StreamController<Uint8List>();
  }

  void _startStream() {
    try {
      _channel = WebSocketChannel.connect(Uri.parse(socketUrl));
      _channel!.stream.listen(
        (dynamic data) {
          if (data is List<int>) {
            final Uint8List frameData = Uint8List.fromList(data);
            if (_isValidJPEG(frameData)) {
              setState(() {
                currentFrame = frameData;
              });
              _streamController?.add(frameData);
            }
          }
        },
        onError: (error) {
          print('WebSocket error: $error');
          _handleConnectionError();
        },
        onDone: () {
          print('WebSocket connection closed');
          _handleConnectionError();
        },
      );

      setState(() {
        isLiveStreaming = true;
      });
    } catch (e) {
      print('Connection error: $e');
      _handleConnectionError();
    }
  }

  bool _isValidJPEG(Uint8List data) {
    if (data.length < 2) return false;
    return data[0] == 0xFF && data[1] == 0xD8; // JPEG başlangıç belirteci
  }

  void _handleConnectionError() {
    setState(() {
      isLiveStreaming = false;
    });
    _channel?.sink.close();
    _channel = null;
  }

  void _captureScreenshot() {
    if (currentFrame != null) {
      setState(() {
        capturedImages.add(currentFrame!);
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
              onTap: () => Navigator.pop(context),
              child: Image.memory(imageData, fit: BoxFit.contain),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _channel?.sink.close();
    _streamController?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text("Güvenlik Kamerası", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.red,
      ),
      body: Column(
        children: [
          Expanded(
            flex: 3,
            child: Center(
              child: isLiveStreaming
                  ? StreamBuilder<Uint8List>(
                      stream: _streamController?.stream,
                      builder: (context, snapshot) {
                        if (snapshot.hasError) {
                          return Center(
                            child: Text(
                              "Bağlantı hatası: ${snapshot.error}",
                              style: TextStyle(color: Colors.black54),
                            ),
                          );
                        }

                        if (!snapshot.hasData) {
                          return Center(
                            child: CircularProgressIndicator(color: Colors.red),
                          );
                        }

                        return Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.memory(
                                snapshot.data!,
                                fit: BoxFit.cover,
                                gaplessPlayback: true,
                              ),
                            ),
                            Positioned(
                              bottom: 20,
                              right: 20,
                              child: FloatingActionButton(
                                backgroundColor: Colors.red,
                                onPressed: _captureScreenshot,
                                child: Icon(Icons.camera_alt, color: Colors.white),
                              ),
                            ),
                          ],
                        );
                      },
                    )
                  : ElevatedButton(
                      onPressed: _startStream,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text("Canlı Yayını Başlat", style: TextStyle(color: Colors.white)),
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