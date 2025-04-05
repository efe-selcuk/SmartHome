import 'package:flutter/material.dart';
import 'package:smarthome/services/sensor_service.dart';
import 'package:smarthome/services/database_service.dart';
import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/services.dart';

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

class _ACDetailScreenState extends State<ACDetailScreen> with SingleTickerProviderStateMixin {
  bool isACOn = false;
  double temperature = 24.0;
  bool _isDisposed = false;
  Timer? _statusUpdateTimer;
  final DatabaseService _databaseService = DatabaseService();
  
  // Fan hızı ve mod ayarları
  String fanSpeed = 'Otomatik';
  String mode = 'Soğutma';
  
  List<String> fanSpeeds = ['Düşük', 'Orta', 'Yüksek', 'Otomatik'];
  List<String> modes = ['Soğutma', 'Isıtma', 'Nem Alma', 'Fan', 'Otomatik'];

  // Animasyon kontroller
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotateAnimation;

  @override
  void initState() {
    super.initState();
    _isDisposed = false;
    
    // İlk başta widget'tan gelen değerleri ata
    isACOn = widget.initialIsOn;
    temperature = widget.initialTemperature;
    
    // Animasyon kontrollerini başlat
    _animationController = AnimationController(
      duration: Duration(milliseconds: 800),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );
    
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Interval(0.2, 0.8, curve: Curves.easeOutBack),
      ),
    );
    
    _rotateAnimation = Tween<double>(begin: 0.0, end: 2 * math.pi).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Interval(0.4, 1.0, curve: Curves.elasticOut),
      ),
    );
    
    // Ekran yüklenince animasyonu başlat
    _animationController.forward();
    
    // Firestore'dan en güncel değerleri al
    _loadACStatusFromFirestore();
    
    // API'den periyodik güncellemeler al
    _startStatusUpdates();
    
    // Haptic feedback verisi
    HapticFeedback.mediumImpact();
  }

  @override
  void dispose() {
    _isDisposed = true;
    if (_statusUpdateTimer != null) {
      _statusUpdateTimer!.cancel();
    }
    _animationController.dispose();
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
        
        // Animasyon efekti
        if (value) {
          _animationController.reset();
          _animationController.forward();
          HapticFeedback.mediumImpact();
        }
        
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
    // Önce UI'da sıcaklığı güncelle (daha iyi UX için)
    setState(() {
      temperature = value.toDouble();
    });
    
    try {
      bool success = await SensorService.setACTemperature(value);
      if (success && mounted) {
        // Haptic geri bildirim ver
        HapticFeedback.selectionClick();
        
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
    final primaryColor = Theme.of(context).primaryColor;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // AC durumuna göre dinamik renkler
    final acColor = isACOn ? Colors.blue : Colors.grey.shade400;
    final backgroundColor = isDark ? Colors.grey.shade900 : Colors.grey.shade50;
    
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Theme.of(context).primaryColor),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: ListView(
          physics: AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.all(16),
          children: [
            SizedBox(height: 16),
            
            // Ana kontrol kartı - Ana animasyonlarla
            AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return Transform.scale(
                  scale: isACOn ? 1.0 : 0.98,
                  child: AnimatedContainer(
                    duration: Duration(milliseconds: 500),
                    curve: Curves.easeOutBack,
                    padding: EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: isACOn 
                          ? [Colors.blue.shade300, Colors.blue.shade600]
                          : [Colors.grey.shade300, Colors.grey.shade500],
                      ),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: isACOn 
                            ? Colors.blue.withOpacity(0.3)
                            : Colors.grey.withOpacity(0.2),
                          blurRadius: 12,
                          offset: Offset(0, 6),
                          spreadRadius: 4,
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Oda adını buraya ekliyoruz
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              widget.roomName,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                                color: Colors.white.withOpacity(0.9),
                              ),
                            ),
                            // Durum göstergesi
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: isACOn ? Colors.greenAccent : Colors.white.withOpacity(0.5),
                                    ),
                                  ),
                                  SizedBox(width: 5),
                                  Text(
                                    isACOn ? 'Açık' : 'Kapalı',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Sıcaklık göstergesi - Büyük ve net
                            TweenAnimationBuilder<double>(
                              tween: Tween<double>(begin: temperature - 1, end: temperature),
                              duration: Duration(milliseconds: 500),
                              curve: Curves.easeOutCubic,
                              builder: (context, value, child) {
                                return Text(
                                  '${value.round()}°C',
                                  style: TextStyle(
                                    fontSize: 72,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    shadows: [
                                      Shadow(
                                        blurRadius: 10.0,
                                        color: Colors.black.withOpacity(0.2),
                                        offset: Offset(2.0, 2.0),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                            
                            // Açma/Kapama düğmesi - Animasyonlu ve 3D efektli
                            GestureDetector(
                              onTap: () => _toggleAC(!isACOn),
                              child: AnimatedContainer(
                                duration: Duration(milliseconds: 300),
                                padding: EdgeInsets.all(18),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: isACOn 
                                      ? [Colors.white, Colors.white70] 
                                      : [Colors.white60, Colors.white30],
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 8,
                                      offset: Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  isACOn ? Icons.power_settings_new : Icons.power_settings_new_outlined,
                                  color: isACOn ? Colors.blue : Colors.grey.shade700,
                                  size: 36,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 30),
                        
                        // Sıcaklık ayarı slider - Daha interaktif ve şık
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Sıcaklık Ayarı',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: Colors.white.withOpacity(0.8),
                              ),
                            ),
                            SizedBox(height: 16),
                            Row(
                              children: [
                                // Azaltma butonu
                                _buildTemperatureButton(
                                  icon: Icons.remove,
                                  onTap: isACOn && temperature > 17 
                                    ? () => _setTemperature(temperature.round() - 1)
                                    : null,
                                ),
                                Expanded(
                                  child: SliderTheme(
                                    data: SliderTheme.of(context).copyWith(
                                      activeTrackColor: Colors.white,
                                      inactiveTrackColor: Colors.white.withOpacity(0.3),
                                      thumbColor: Colors.white,
                                      trackHeight: 4.0,
                                      thumbShape: RoundSliderThumbShape(
                                        enabledThumbRadius: 12.0,
                                        elevation: 4.0,
                                      ),
                                      overlayColor: Colors.white.withOpacity(0.2),
                                      overlayShape: RoundSliderOverlayShape(overlayRadius: 24.0),
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
                                // Artırma butonu
                                _buildTemperatureButton(
                                  icon: Icons.add,
                                  onTap: isACOn && temperature < 30 
                                    ? () => _setTemperature(temperature.round() + 1)
                                    : null,
                                ),
                              ],
                            ),
                          ],
                        ),
                        SizedBox(height: 24),
                        
                        // Durum göstergesi
                        AnimatedContainer(
                          duration: Duration(milliseconds: 500),
                          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Yanıp sönen LED efekti
                              if (isACOn)
                                TweenAnimationBuilder<double>(
                                  tween: Tween<double>(begin: 0.5, end: 1.0),
                                  duration: Duration(milliseconds: 1000),
                                  curve: Curves.easeInOut,
                                  builder: (context, value, child) {
                                    return Container(
                                      width: 10,
                                      height: 10,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Color.lerp(Colors.transparent, Colors.greenAccent, value),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.greenAccent.withOpacity(0.7 * value),
                                            blurRadius: 6.0 * value,
                                            spreadRadius: 2.0 * value,
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                )
                              else
                                Container(
                                  width: 10,
                                  height: 10,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.white.withOpacity(0.5),
                                  ),
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
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            
            SizedBox(height: 32),
            
            // Sıcaklık Hızlı Seçim Butonları - Daha görsel ve kullanışlı
            _buildTemperatureQuickButtons(),
            
            SizedBox(height: 32),
            
            // Ayarlar Kartları - Daha temiz ve kullanıcı dostu
            _buildSettingCard(
              'Fan Hızı',
              Icons.air,
              fanSpeeds,
              fanSpeed,
              (value) {
                if (isACOn) {
                  setState(() {
                    fanSpeed = value;
                    // Haptic geri bildirim
                    HapticFeedback.selectionClick();
                  });
                }
              },
            ),
            
            SizedBox(height: 16),
            
            _buildSettingCard(
              'Mod',
              Icons.mode_fan_off,
              modes,
              mode,
              (value) {
                if (isACOn) {
                  setState(() {
                    mode = value;
                    // Haptic geri bildirim
                    HapticFeedback.selectionClick();
                  });
                }
              },
            ),
            
            SizedBox(height: 16),
            
            // Zaman Ayarı Kartı - Modern tasarım
            _buildTimerCard(),
            
            SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // Sıcaklık +/- butonları
  Widget _buildTemperatureButton({
    required IconData icon,
    required VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: Duration(milliseconds: 200),
        padding: EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: onTap != null ? Colors.white.withOpacity(0.3) : Colors.white.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: Colors.white,
          size: 24,
        ),
      ),
    );
  }

  // Sıcaklık Hızlı Seçim Butonları
  Widget _buildTemperatureQuickButtons() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Text(
            'Hızlı Sıcaklık Ayarı',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).primaryColor,
            ),
          ),
        ),
        SizedBox(height: 16),
        SizedBox(
          height: 110,
          child: ListView(
            scrollDirection: Axis.horizontal,
            physics: BouncingScrollPhysics(),
            children: [
              _buildTempPresetCard(17, 'Çok Soğuk', Icons.ac_unit, Colors.blue.shade800),
              _buildTempPresetCard(20, 'Soğuk', Icons.ac_unit, Colors.blue.shade600),
              _buildTempPresetCard(24, 'Normal', Icons.thermostat, Colors.blue.shade400),
              _buildTempPresetCard(26, 'Sıcak', Icons.wb_sunny_outlined, Colors.orange.shade300),
              _buildTempPresetCard(30, 'Çok Sıcak', Icons.wb_sunny, Colors.orange.shade600),
            ],
          ),
        ),
      ],
    );
  }

  // Sıcaklık Preset Kartı
  Widget _buildTempPresetCard(int temp, String label, IconData icon, Color color) {
    bool isSelected = temperature.round() == temp;
    
    return GestureDetector(
      onTap: isACOn ? () => _setTemperature(temp) : null,
      child: AnimatedContainer(
        duration: Duration(milliseconds: 300),
        margin: EdgeInsets.symmetric(horizontal: 8),
        width: 90,
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.2) : Colors.grey.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? color : Colors.transparent,
            width: 2,
          ),
          boxShadow: isSelected ? [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ] : [],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? color : Colors.grey,
              size: 28,
            ),
            SizedBox(height: 8),
            Text(
              '$temp°C',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isSelected ? color : Colors.grey.shade700,
              ),
            ),
            SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: isSelected ? color.withOpacity(0.8) : Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // Ayarlar Kartı
  Widget _buildSettingCard(
    String title,
    IconData icon,
    List<String> options,
    String selectedOption,
    Function(String) onSelected,
  ) {
    return Card(
      elevation: 4,
      shadowColor: Theme.of(context).primaryColor.withOpacity(0.2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    icon,
                    color: Theme.of(context).primaryColor,
                    size: 20,
                  ),
                ),
                SizedBox(width: 12),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: options.map((option) {
                bool isSelected = selectedOption == option;
                
                return AnimatedContainer(
                  duration: Duration(milliseconds: 200),
                  child: InkWell(
                    onTap: isACOn ? () => onSelected(option) : null,
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected 
                          ? Theme.of(context).primaryColor
                          : Colors.grey.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected 
                            ? Theme.of(context).primaryColor 
                            : Colors.transparent,
                          width: 1,
                        ),
                      ),
                      child: Text(
                        option,
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.grey[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  // Zaman Ayarı Kartı
  Widget _buildTimerCard() {
    return Card(
      elevation: 4,
      shadowColor: Theme.of(context).primaryColor.withOpacity(0.2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.timer,
                    color: Theme.of(context).primaryColor,
                    size: 20,
                  ),
                ),
                SizedBox(width: 12),
                Text(
                  'Zamanlayıcı',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            Row(
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
                  onPressed: isACOn ? () {
                    // Zamanlayıcı ayarlama (demo amaçlı)
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Zamanlayıcı özelliği demo amaçlıdır')),
                    );
                  } : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  child: Text('Ayarla'),
                ),
              ],
            ),
            if (isACOn) ...[
              SizedBox(height: 12),
              // Zaman seçim butonları
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: BouncingScrollPhysics(),
                child: Row(
                  children: [
                    _buildTimerOption('30 dk'),
                    _buildTimerOption('1 saat'),
                    _buildTimerOption('2 saat'),
                    _buildTimerOption('4 saat'),
                    _buildTimerOption('8 saat'),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // Zaman Seçim Butonu
  Widget _buildTimerOption(String time) {
    return Container(
      margin: EdgeInsets.only(right: 8),
      child: OutlinedButton(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('$time için zamanlayıcı ayarlandı (demo)')),
          );
        },
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: Theme.of(context).primaryColor),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        child: Text(time),
      ),
    );
  }
}

// Modern geliştirilmiş dalga efekti
class ModernWavePainter extends CustomPainter {
  final Color color;
  final double waveFrequency;
  final double waveHeight;
  final double wavePhase;
  final double opacity;

  ModernWavePainter({
    required this.color,
    required this.waveFrequency,
    required this.waveHeight,
    required this.wavePhase,
    this.opacity = 1.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withOpacity(opacity)
      ..style = PaintingStyle.fill
      ..strokeWidth = 1.0
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 2);

    final path = Path();
    path.moveTo(0, size.height);

    for (double i = 0; i <= size.width; i++) {
      // Daha karmaşık ve doğal görünümlü dalga efekti
      final y = size.height - 
          math.sin((i / size.width * waveFrequency) + wavePhase) * waveHeight -
          math.sin((i / size.width * (waveFrequency * 0.5)) + wavePhase * 1.5) * (waveHeight * 0.3);
      
      path.lineTo(i, y);
    }

    path.lineTo(size.width, size.height);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant ModernWavePainter oldDelegate) {
    return oldDelegate.wavePhase != wavePhase || 
           oldDelegate.opacity != opacity;
  }
} 