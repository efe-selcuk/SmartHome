import 'package:flutter/material.dart';
import 'package:smarthome/services/sensor_service.dart';

class TvRemoteScreen extends StatefulWidget {
  final String roomName;

  const TvRemoteScreen({super.key, required this.roomName});

  @override
  _TvRemoteScreenState createState() => _TvRemoteScreenState();
}

class _TvRemoteScreenState extends State<TvRemoteScreen> {
  bool isTvOn = false;
  int currentVolume = 50;
  int currentChannel = 1;
  bool isMuted = false;
  List<String> favoriteChannels = [
    'TRT 1',
    'Show TV',
    'ATV',
    'Fox',
    'CNN Türk',
    'NTV',
    'TLC',
    'Netflix',
    'YouTube',
  ];
  
  @override
  void initState() {
    super.initState();
    _getTvStatus();
  }
  
  Future<void> _getTvStatus() async {
    try {
      // Artık bellek içinden durum bilgisini alıyoruz
      final status = SensorService.getTvMemoryStatus();
      
      if (mounted) {
        setState(() {
          isTvOn = status['isOn'] ?? false;
          currentVolume = status['volume'] ?? 50;
          currentChannel = status['channel'] ?? 1;
          isMuted = status['isMuted'] ?? false;
        });
      }
    } catch (e) {
      print('TV durumu alınırken hata: $e');
      // Varsayılan değerleri ayarla
      if (mounted) {
        setState(() {
          isTvOn = false;
          currentVolume = 50;
          currentChannel = 1;
          isMuted = false;
        });
      }
      
      // Hata durumunda kullanıcıya bildir
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('TV durumu alınamadı, varsayılan değerler kullanılıyor.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  Future<void> _controlTv(bool isOn) async {
    try {
      // API üzerinden kontrol
      bool success = await SensorService.controlTvPower();
      if (success && mounted) {
        setState(() {
          isTvOn = !isTvOn; // Durumu tersine çevir
        });
      }
    } catch (e) {
      print('TV kontrol edilirken hata: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('TV kontrol edilemedi: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _setVolume(int volume) async {
    try {
      // Ses artırma veya azaltma
      String action;
      if (volume > currentVolume) {
        action = 'up';
      } else if (volume < currentVolume) {
        action = 'down';
      } else {
        return; // Değişiklik yok
      }
      
      bool success = await SensorService.controlTvVolume(action);
      if (success && mounted) {
        // Bellek içindeki durumu alarak güncelle
        final status = SensorService.getTvMemoryStatus();
        setState(() {
          currentVolume = status['volume'] ?? currentVolume;
          isMuted = status['isMuted'] ?? isMuted;
        });
      }
    } catch (e) {
      print('TV ses seviyesi ayarlanırken hata: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ses seviyesi ayarlanamadı: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _toggleMute() async {
    try {
      bool success = await SensorService.controlTvVolume('mute');
      if (success && mounted) {
        // Bellek içindeki durumu alarak güncelle
        final status = SensorService.getTvMemoryStatus();
        setState(() {
          isMuted = status['isMuted'] ?? !isMuted;
        });
      }
    } catch (e) {
      print('TV sessiz modu değiştirilirken hata: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sessiz modu değiştirilemedi: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _changeChannel(int channel) async {
    try {
      // Channel doğrudan endpoint ile değil, up/down ile değiştirilir
      // Sayısal tuş kullanımı için alternatif yöntem
      bool success = await SensorService.controlTvNumberButton(channel);
      if (success && mounted) {
        // Bellek içindeki durumu alarak güncelle
        final status = SensorService.getTvMemoryStatus();
        setState(() {
          currentChannel = status['channel'] ?? channel;
        });
      }
    } catch (e) {
      print('TV kanalı değiştirilirken hata: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Kanal değiştirilemedi: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Channel up fonksiyonu
  Future<void> _channelUp() async {
    try {
      bool success = await SensorService.controlTvChannel('up');
      if (success && mounted) {
        // Bellek içindeki durumu alarak güncelle
        final status = SensorService.getTvMemoryStatus();
        setState(() {
          currentChannel = status['channel'] ?? (currentChannel + 1);
        });
      }
    } catch (e) {
      print('Kanal arttırılırken hata: $e');
    }
  }

  // Channel down fonksiyonu
  Future<void> _channelDown() async {
    try {
      bool success = await SensorService.controlTvChannel('down');
      if (success && mounted && currentChannel > 1) {
        // Bellek içindeki durumu alarak güncelle
        final status = SensorService.getTvMemoryStatus();
        setState(() {
          currentChannel = status['channel'] ?? (currentChannel - 1);
        });
      }
    } catch (e) {
      print('Kanal azaltılırken hata: $e');
    }
  }

  Future<void> _launchApp(String appName) async {
    try {
      // Her uygulamayı bir sayı tuşuna eşleştirelim
      int buttonNumber;
      
      // Uygulamayı seçelim
      switch (appName.toLowerCase()) {
        case 'netflix':
          buttonNumber = 4;
          break;
        case 'youtube':
          buttonNumber = 5;
          break;
        case 'prime':
        case 'prime video':
          buttonNumber = 6;
          break;
        case 'disney+':
          buttonNumber = 0;
          break;
        default:
          buttonNumber = 9; // Default olarak 9 tuşunu kullanabiliriz
      }
      
      // Simule edilen uygulama başlatma
      await SensorService.controlTvNumberButton(buttonNumber);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$appName uygulaması başlatıldı'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('TV uygulaması başlatılırken hata: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$appName uygulaması başlatılamadı: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.roomName} - TV Kumandası'),
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).primaryColor.withOpacity(0.2),
              Colors.white,
            ],
          ),
        ),
        child: Column(
          children: [
            // TV Durum Kartı
            Container(
              margin: EdgeInsets.all(16),
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    spreadRadius: 2,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Theme.of(context).primaryColor.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.tv,
                              size: 30,
                              color: isTvOn 
                                  ? Theme.of(context).primaryColor 
                                  : Colors.grey,
                            ),
                          ),
                          SizedBox(width: 16),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Akıllı TV',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                isTvOn ? 'Açık' : 'Kapalı',
                                style: TextStyle(
                                  color: isTvOn 
                                      ? Theme.of(context).primaryColor 
                                      : Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      GestureDetector(
                        onTap: () => _controlTv(isTvOn),
                        child: Container(
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: isTvOn 
                                ? Theme.of(context).primaryColor 
                                : Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(30),
                            boxShadow: [
                              BoxShadow(
                                color: isTvOn 
                                    ? Theme.of(context).primaryColor.withOpacity(0.3) 
                                    : Colors.grey.withOpacity(0.2),
                                blurRadius: 8,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.power_settings_new,
                                color: Colors.white,
                                size: 20,
                              ),
                              SizedBox(width: 6),
                              Text(
                                isTvOn ? 'KAPAT' : 'AÇ',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                              SizedBox(width: 4),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (isTvOn) ...[
                    SizedBox(height: 10),
                  ],
                ],
              ),
            ),
            
            if (isTvOn) Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Kumanda Tuşları
                      Text(
                        'Kumanda',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                      SizedBox(height: 16),
                      
                      // Üst Kontrol Tuşları
                      Container(
                        padding: EdgeInsets.all(15),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.08),
                              blurRadius: 10,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildActionButton(
                              icon: Icons.home,
                              label: 'Ana Menü',
                              onTap: () async {
                                try {
                                  await SensorService.controlTvNumberButton(7);
                                } catch (e) {
                                  print('Ana menü komutu gönderilirken hata: $e');
                                }
                              },
                            ),
                            _buildActionButton(
                              icon: Icons.settings,
                              label: 'Ayarlar',
                              onTap: () async {
                                try {
                                  await SensorService.controlTvNumberButton(8);
                                } catch (e) {
                                  print('Ayarlar komutu gönderilirken hata: $e');
                                }
                              },
                            ),
                            _buildActionButton(
                              icon: Icons.info_outline,
                              label: 'Bilgi',
                              onTap: () async {
                                try {
                                  await SensorService.controlTvNumberButton(9);
                                } catch (e) {
                                  print('Bilgi komutu gönderilirken hata: $e');
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                      
                      SizedBox(height: 32),
                      
                      // Ok Tuşları (Yön)
                      Center(
                        child: Container(
                          padding: EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.08),
                                blurRadius: 10,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              _buildDirectionButton(
                                icon: Icons.keyboard_arrow_up,
                                onTap: () async {
                                  await SensorService.controlTvDirection('up');
                                },
                                color: Theme.of(context).primaryColor.withOpacity(0.1),
                                iconColor: Theme.of(context).primaryColor,
                              ),
                              SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  _buildDirectionButton(
                                    icon: Icons.keyboard_arrow_left,
                                    onTap: () async {
                                      await SensorService.controlTvDirection('left');
                                    },
                                    color: Theme.of(context).primaryColor.withOpacity(0.1),
                                    iconColor: Theme.of(context).primaryColor,
                                  ),
                                  SizedBox(width: 10),
                                  _buildCenterButton(
                                    onTap: () async {
                                      await SensorService.controlTvOkButton();
                                    },
                                  ),
                                  SizedBox(width: 10),
                                  _buildDirectionButton(
                                    icon: Icons.keyboard_arrow_right,
                                    onTap: () async {
                                      await SensorService.controlTvDirection('right');
                                    },
                                    color: Theme.of(context).primaryColor.withOpacity(0.1),
                                    iconColor: Theme.of(context).primaryColor,
                                  ),
                                ],
                              ),
                              SizedBox(height: 8),
                              _buildDirectionButton(
                                icon: Icons.keyboard_arrow_down,
                                onTap: () async {
                                  await SensorService.controlTvDirection('down');
                                },
                                color: Theme.of(context).primaryColor.withOpacity(0.1),
                                iconColor: Theme.of(context).primaryColor,
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                      SizedBox(height: 32),
                      
                      // Alt Kontrol Tuşları
                      Container(
                        padding: EdgeInsets.all(15),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.08),
                              blurRadius: 10,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildMediaButton(
                              icon: Icons.fast_rewind,
                              label: 'Geri',
                              onTap: () async {
                                try {
                                  await SensorService.controlTvNumberButton(1);
                                } catch (e) {
                                  print('Geri sar komutu gönderilirken hata: $e');
                                }
                              },
                            ),
                            _buildMediaButton(
                              icon: Icons.play_arrow,
                              label: 'Oynat',
                              isMain: true,
                              onTap: () async {
                                try {
                                  await SensorService.controlTvNumberButton(2);
                                } catch (e) {
                                  print('Oynat komutu gönderilirken hata: $e');
                                }
                              },
                            ),
                            _buildMediaButton(
                              icon: Icons.fast_forward,
                              label: 'İleri',
                              onTap: () async {
                                try {
                                  await SensorService.controlTvNumberButton(3);
                                } catch (e) {
                                  print('İleri sar komutu gönderilirken hata: $e');
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                      
                      SizedBox(height: 32),
                      
                      // Gelişmiş Ses Kontrol Tuşları
                      Container(
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(15),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 8,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Ses Kontrolü',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context).primaryColor,
                                  ),
                                ),
                                GestureDetector(
                                  onTap: _toggleMute,
                                  child: Container(
                                    padding: EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: isMuted ? Colors.red.withOpacity(0.1) : Theme.of(context).primaryColor.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          isMuted ? Icons.volume_off : Icons.volume_up,
                                          color: isMuted ? Colors.red : Theme.of(context).primaryColor,
                                          size: 20,
                                        ),
                                        SizedBox(width: 4),
                                        Text(
                                          isMuted ? 'Sessiz' : 'Sesli',
                                          style: TextStyle(
                                            color: isMuted ? Colors.red : Theme.of(context).primaryColor,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '0',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Expanded(
                                  child: SliderTheme(
                                    data: SliderThemeData(
                                      activeTrackColor: Theme.of(context).primaryColor,
                                      thumbColor: Theme.of(context).primaryColor,
                                      inactiveTrackColor: Colors.grey.shade300,
                                      trackHeight: 6,
                                      thumbShape: RoundSliderThumbShape(enabledThumbRadius: 8),
                                    ),
                                    child: Slider(
                                      value: currentVolume.toDouble(),
                                      min: 0,
                                      max: 100,
                                      onChanged: (value) => _setVolume(value.round()),
                                    ),
                                  ),
                                ),
                                Text(
                                  '100',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _buildVolumeControlButton(
                                  icon: Icons.volume_mute,
                                  label: 'Sessiz',
                                  isActive: isMuted,
                                  onTap: _toggleMute,
                                ),
                                _buildVolumeControlButton(
                                  icon: Icons.remove,
                                  label: 'Azalt',
                                  isActive: false,
                                  onTap: () async {
                                    await SensorService.controlTvVolume('down');
                                    if (mounted) {
                                      // Bellek içindeki durumu alarak güncelle
                                      final status = SensorService.getTvMemoryStatus();
                                      setState(() {
                                        currentVolume = status['volume'] ?? (currentVolume - 5).clamp(0, 100);
                                      });
                                    }
                                  },
                                ),
                                _buildVolumeControlButton(
                                  icon: Icons.add,
                                  label: 'Arttır',
                                  isActive: false,
                                  onTap: () async {
                                    await SensorService.controlTvVolume('up');
                                    if (mounted) {
                                      // Bellek içindeki durumu alarak güncelle
                                      final status = SensorService.getTvMemoryStatus();
                                      setState(() {
                                        currentVolume = status['volume'] ?? (currentVolume + 5).clamp(0, 100);
                                        isMuted = status['isMuted'] ?? false;
                                      });
                                    }
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      
                      SizedBox(height: 32),
                      
                      // Kanal Değiştirme Tuşları
                      Container(
                        padding: EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.08),
                              blurRadius: 10,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Text(
                              'Kanal Kontrolü',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).primaryColor,
                              ),
                            ),
                            SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _buildChannelControlButton(
                                  icon: Icons.keyboard_arrow_down,
                                  onTap: _channelDown,
                                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                                  iconColor: Theme.of(context).primaryColor,
                                ),
                                SizedBox(width: 16),
                                Container(
                                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).primaryColor,
                                    borderRadius: BorderRadius.circular(15),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Theme.of(context).primaryColor.withOpacity(0.3),
                                        blurRadius: 8,
                                        spreadRadius: 1,
                                      ),
                                    ],
                                  ),
                                  child: Text(
                                    'Kanal $currentChannel',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                                SizedBox(width: 16),
                                _buildChannelControlButton(
                                  icon: Icons.keyboard_arrow_up,
                                  onTap: _channelUp,
                                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                                  iconColor: Theme.of(context).primaryColor,
                                ),
                              ],
                            ),
                            SizedBox(height: 20),
                            // Sayısal tuşlar - modern tasarım
                            Container(
                              padding: EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Theme.of(context).primaryColor.withOpacity(0.05),
                                borderRadius: BorderRadius.circular(15),
                              ),
                              child: Wrap(
                                alignment: WrapAlignment.center,
                                spacing: 15,
                                runSpacing: 15,
                                children: List.generate(10, (index) {
                                  // 0 tuşunun en sona (9'dan sonra) yerleştirilmesi için düzenleme
                                  final number = (index == 9) ? 0 : index + 1;
                                  return _buildNumberButton(
                                    number: number,
                                    onTap: () async {
                                      await SensorService.controlTvNumberButton(number);
                                      if (mounted) {
                                        // Bellek içindeki durumu alarak güncelle
                                        final status = SensorService.getTvMemoryStatus();
                                        setState(() {
                                          currentChannel = status['channel'] ?? number;
                                        });
                                      }
                                    },
                                  );
                                }),
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      SizedBox(height: 30),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChannelButton(String channelName, int channelNumber) {
    bool isActive = currentChannel == channelNumber;
    
    return GestureDetector(
      onTap: () => _changeChannel(channelNumber),
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 8),
        width: 80,
        decoration: BoxDecoration(
          color: isActive ? Theme.of(context).primaryColor : Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              spreadRadius: isActive ? 2 : 0,
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              channelName,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isActive ? Colors.white : Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 4),
            Text(
              '$channelNumber',
              style: TextStyle(
                color: isActive ? Colors.white : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRemoteButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 5,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              icon,
              color: Theme.of(context).primaryColor,
              size: 24,
            ),
          ),
          SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDirectionButton({
    required IconData icon,
    required VoidCallback onTap,
    required Color color,
    required Color iconColor,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 5,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Icon(
          icon,
          color: iconColor,
          size: 28,
        ),
      ),
    );
  }

  Widget _buildCenterButton({
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Theme.of(context).primaryColor,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).primaryColor.withOpacity(0.3),
              blurRadius: 8,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Text(
          'OK',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildVolumeButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 5,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Icon(
          icon,
          color: Theme.of(context).primaryColor,
          size: 28,
        ),
      ),
    );
  }

  Widget _buildAppButton({
    required String appName,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.3),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Center(
              child: Text(
                appName[0],
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                ),
              ),
            ),
          ),
          SizedBox(height: 8),
          Text(
            appName,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildChannelControlButton({
    required IconData icon,
    required VoidCallback onTap,
    required Color color,
    required Color iconColor,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 5,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Icon(
          icon,
          color: iconColor,
          size: 28,
        ),
      ),
    );
  }

  Widget _buildVolumeControlButton({
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isActive 
                  ? Theme.of(context).primaryColor 
                  : (label == 'Sessiz' ? Colors.red.withOpacity(0.1) : Theme.of(context).primaryColor.withOpacity(0.1)),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 5,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              icon,
              color: isActive 
                  ? Colors.white 
                  : (label == 'Sessiz' ? Colors.red : Theme.of(context).primaryColor),
              size: 28,
            ),
          ),
          SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              color: isActive 
                  ? Theme.of(context).primaryColor
                  : (label == 'Sessiz' ? Colors.red : Colors.grey[700]),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNumberButton({
    required int number,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: Text(
            '$number',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: Theme.of(context).primaryColor,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMediaButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isMain = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(isMain ? 16 : 12),
            decoration: BoxDecoration(
              color: isMain 
                  ? Theme.of(context).primaryColor
                  : Theme.of(context).primaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: isMain
                      ? Theme.of(context).primaryColor.withOpacity(0.3)
                      : Colors.black.withOpacity(0.05),
                  blurRadius: isMain ? 10 : 5,
                  spreadRadius: isMain ? 2 : 1,
                ),
              ],
            ),
            child: Icon(
              icon,
              color: isMain ? Colors.white : Theme.of(context).primaryColor,
              size: isMain ? 30 : 24,
            ),
          ),
          SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isMain ? FontWeight.bold : FontWeight.normal,
              color: isMain ? Theme.of(context).primaryColor : Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 80,
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: Theme.of(context).primaryColor,
                size: 24,
              ),
            ),
            SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.grey[800],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
} 