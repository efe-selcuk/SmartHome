import 'package:flutter/material.dart';
import 'package:smarthome/services/sensor_service.dart';
import 'package:smarthome/services/database_service.dart';
import 'dart:async';

class ACDetailScreen extends StatefulWidget {
  final String roomName;
  final bool initialIsOn;
  final double initialTemperature;

  const ACDetailScreen({
    super.key, 
    required this.roomName, 
    required this.initialIsOn,
    required this.initialTemperature,
  });

  @override
  _ACDetailScreenState createState() => _ACDetailScreenState();
}

class _ACDetailScreenState extends State<ACDetailScreen> {
  bool isACOn = false;
  double temperature = 24.0;
  bool _isDisposed = false;
  Timer? _statusUpdateTimer;
  final DatabaseService _databaseService = DatabaseService();
  
  // Fan hızı ve mod ayarları (UI demo amaçlı)
  String fanSpeed = 'Otomatik';
  String mode = 'Soğutma';
  
  List<String> fanSpeeds = ['Düşük', 'Orta', 'Yüksek', 'Otomatik'];
  List<String> modes = ['Soğutma', 'Isıtma', 'Nem Alma', 'Fan', 'Otomatik'];

  @override
  void initState() {
    super.initState();
    _isDisposed = false;
    
    // İlk başta widget'tan gelen değerleri ata
    isACOn = widget.initialIsOn;
    temperature = widget.initialTemperature;
    
    // Firestore'dan en güncel değerleri al
    _loadACStatusFromFirestore();
    
    // API'den periyodik güncellemeler al
    _startStatusUpdates();
  }

  @override
  void dispose() {
    _isDisposed = true;
    if (_statusUpdateTimer != null) {
      _statusUpdateTimer!.cancel();
    }
    super.dispose();
  }

  void _startStatusUpdates() {
    _statusUpdateTimer = Timer.periodic(Duration(seconds: 5), (timer) async {
      if (_isDisposed) {
        timer.cancel();
        return;
      }
      
      try {
        // Firestore'dan son durumu al
        final acData = await _databaseService.loadRoomData(widget.roomName);
        if (acData != null && acData.containsKey('isClimaOn')) {
          if (!_isDisposed && mounted) {
            setState(() {
              isACOn = acData['isClimaOn'];
              if (acData['climaTemp'] != null) {
                temperature = acData['climaTemp'];
              }
            });
          }
        } else {
          // Eğer Firestore'da veri yoksa, sensörden al
          final acStatus = await SensorService.getACStatus();
          if (!_isDisposed && mounted) {
            setState(() {
              isACOn = acStatus['status'] == 'on';
              if (acStatus['temperature'] != null) {
                temperature = acStatus['temperature'].toDouble();
              }
            });
          }
        }
      } catch (e) {
        print('AC durumu güncellenirken hata: $e');
      }
    });
  }

  Future<void> _toggleAC(bool value) async {
    try {
      bool success = await SensorService.setACStatus(value);
      if (success && mounted) {
        setState(() {
          isACOn = value;
        });
        
        // Firestore'a AC durumunu kaydet
        await _databaseService.saveRoomData(widget.roomName, {
          'isClimaOn': value,
          'climaTemp': temperature,
          'lastUpdated': DateTime.now().millisecondsSinceEpoch,
        });
      }
    } catch (e) {
      print('AC kontrol edilirken hata: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('AC kontrol edilemedi: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _setTemperature(int value) async {
    try {
      bool success = await SensorService.setACTemperature(value);
      if (success && mounted) {
        setState(() {
          temperature = value.toDouble();
        });
        
        // Firestore'a sıcaklık ayarını kaydet
        await _databaseService.saveRoomData(widget.roomName, {
          'isClimaOn': isACOn,
          'climaTemp': value.toDouble(),
          'lastUpdated': DateTime.now().millisecondsSinceEpoch,
        });
      }
    } catch (e) {
      print('Sıcaklık ayarlanırken hata: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sıcaklık ayarlanamadı: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _loadACStatusFromFirestore() async {
    try {
      final acData = await _databaseService.loadRoomData(widget.roomName);
      if (acData != null && acData.containsKey('isClimaOn') && mounted) {
        setState(() {
          isACOn = acData['isClimaOn'];
          if (acData['climaTemp'] != null) {
            temperature = acData['climaTemp'];
          }
        });
      }
    } catch (e) {
      print('Firestore\'dan AC durumu yüklenirken hata: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.roomName} - Klima Kontrolü'),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Ana sıcaklık ve kontrol kartı
              _buildMainControlCard(),
              SizedBox(height: 24),
              
              // Hızlı sıcaklık seçme butonları
              _buildTemperatureQuickButtons(),
              SizedBox(height: 24),
              
              // Fan hızı ayarı
              _buildSettingCard(
                title: 'Fan Hızı',
                icon: Icons.air,
                child: _buildOptionSelector(
                  options: fanSpeeds,
                  selectedOption: fanSpeed,
                  onSelected: (value) {
                    setState(() {
                      fanSpeed = value;
                    });
                  },
                ),
              ),
              SizedBox(height: 16),
              
              // Mod seçimi
              _buildSettingCard(
                title: 'Mod',
                icon: Icons.mode_fan_off,
                child: _buildOptionSelector(
                  options: modes,
                  selectedOption: mode,
                  onSelected: (value) {
                    setState(() {
                      mode = value;
                    });
                  },
                ),
              ),
              SizedBox(height: 16),
              
              // Zamanlayıcı butonu
              _buildSettingCard(
                title: 'Zamanlayıcı',
                icon: Icons.timer,
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Klimayı belirli bir süre sonra otomatik kapatabilirsiniz',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        // Zamanlayıcı ayarlama (demo amaçlı)
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Zamanlayıcı özelliği demo amaçlıdır')),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text('Ayarla'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMainControlCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isACOn 
              ? [Colors.blue.shade300, Colors.blue.shade600]
              : [Colors.grey.shade300, Colors.grey.shade500],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Sıcaklık göstergesi
                Text(
                  '${temperature.round()}°C',
                  style: TextStyle(
                    fontSize: 64,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                
                // Açma/Kapama düğmesi
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: IconButton(
                    onPressed: () => _toggleAC(!isACOn),
                    icon: Icon(
                      isACOn ? Icons.power_settings_new : Icons.power_settings_new_outlined,
                      color: Colors.white,
                      size: 30,
                    ),
                    padding: EdgeInsets.all(16),
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),
            
            // Sıcaklık ayarı
            Text(
              'Sıcaklık Ayarı',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.white.withOpacity(0.8),
              ),
            ),
            SizedBox(height: 10),
            Row(
              children: [
                IconButton(
                  onPressed: isACOn ? () {
                    if (temperature > 17) {
                      _setTemperature(temperature.round() - 1);
                    }
                  } : null,
                  icon: Icon(Icons.remove_circle_outline, color: Colors.white),
                ),
                Expanded(
                  child: SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: Colors.white,
                      inactiveTrackColor: Colors.white.withOpacity(0.3),
                      thumbColor: Colors.white,
                      trackHeight: 4.0,
                    ),
                    child: Slider(
                      value: temperature,
                      min: 17.0,
                      max: 30.0,
                      divisions: 13,
                      onChanged: isACOn 
                        ? (value) {
                            setState(() {
                              temperature = value;
                            });
                          }
                        : null,
                      onChangeEnd: isACOn
                        ? (value) => _setTemperature(value.round())
                        : null,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: isACOn ? () {
                    if (temperature < 30) {
                      _setTemperature(temperature.round() + 1);
                    }
                  } : null,
                  icon: Icon(Icons.add_circle_outline, color: Colors.white),
                ),
              ],
            ),
            
            // Durum göstergesi
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isACOn ? Icons.circle : Icons.power_off, 
                  color: isACOn ? Colors.greenAccent : Colors.white.withOpacity(0.5),
                  size: 12,
                ),
                SizedBox(width: 8),
                Text(
                  isACOn ? 'Çalışıyor - $mode modu' : 'Kapalı',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTemperatureQuickButtons() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Hızlı Sıcaklık Ayarı',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildTempButton(17, 'Çok Soğuk'),
            _buildTempButton(20, 'Soğuk'),
            _buildTempButton(24, 'Normal'),
            _buildTempButton(26, 'Sıcak'),
            _buildTempButton(30, 'Çok Sıcak'),
          ],
        ),
      ],
    );
  }

  Widget _buildTempButton(int temp, String label) {
    bool isSelected = temperature.round() == temp;
    
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4.0),
        child: GestureDetector(
          onTap: isACOn ? () => _setTemperature(temp) : null,
          child: Column(
            children: [
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.blue : Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(50),
                  border: Border.all(
                    color: isSelected ? Colors.blue.shade300 : Colors.grey.shade300,
                    width: 2,
                  ),
                ),
                child: Text(
                  '$temp°',
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.grey[700],
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettingCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Colors.blue),
                SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildOptionSelector({
    required List<String> options,
    required String selectedOption,
    required Function(String) onSelected,
  }) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((option) {
        bool isSelected = selectedOption == option;
        
        return InkWell(
          onTap: isACOn ? () => onSelected(option) : null,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? Colors.blue : Colors.grey.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              option,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey[700],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
} 