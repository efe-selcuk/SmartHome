import 'package:flutter/material.dart';
import 'package:smarthome/services/sensor_service.dart';
import 'package:smarthome/services/database_service.dart';

class AutomationScreen extends StatefulWidget {
  const AutomationScreen({super.key});

  @override
  _AutomationScreenState createState() => _AutomationScreenState();
}

class _AutomationScreenState extends State<AutomationScreen> {
  final DatabaseService _databaseService = DatabaseService();
  bool isLoading = true;
  List<String> rooms = [];
  Map<String, AutomationRule> automationRules = {};

  @override
  void initState() {
    super.initState();
    _loadRooms();
  }

  Future<void> _loadRooms() async {
    setState(() {
      isLoading = true;
    });

    try {
      // Odaları yükle
      List<String> loadedRooms = await _databaseService.loadRoomNames();

      // Her oda için otomasyon kurallarını yükle
      Map<String, AutomationRule> loadedRules = {};
      for (String room in loadedRooms) {
        final roomData = await _databaseService.loadRoomData(room);
        if (roomData != null && roomData.containsKey('automationRule')) {
          Map<String, dynamic> ruleData = roomData['automationRule'];
          loadedRules[room] = AutomationRule.fromMap(ruleData);
        } else {
          // Varsayılan kural oluştur
          loadedRules[room] = AutomationRule(
            isEnabled: false,
            temperatureThreshold: 25,
            humidityThreshold: 60,
            targetTemperature: 22,
          );
        }
      }

      setState(() {
        rooms = loadedRooms;
        automationRules = loadedRules;
        isLoading = false;
      });
    } catch (e) {
      print('Odalar ve otomasyon kuralları yüklenirken hata: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _saveAutomationRule(String room, AutomationRule rule) async {
    try {
      await _databaseService.saveRoomData(room, {
        'automationRule': rule.toMap(),
        'lastUpdated': DateTime.now().millisecondsSinceEpoch,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Otomasyon kuralı kaydedildi'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      print('Otomasyon kuralı kaydedilirken hata: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Otomasyon kuralı kaydedilemedi: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Otomasyon Ayarları'),
        backgroundColor: Theme.of(context).primaryColor,
        elevation: 0,
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : rooms.isEmpty
              ? _buildEmptyState()
              : _buildRoomList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.home_work_outlined,
            size: 60,
            color: Colors.grey[400],
          ),
          SizedBox(height: 24),
          Text(
            'Henüz oda eklenmemiş',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[800],
            ),
          ),
          SizedBox(height: 12),
          Text(
            'Otomasyon ayarları için önce ana ekrandan oda eklemelisiniz',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              color: Colors.grey[600],
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoomList() {
    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: rooms.length,
      itemBuilder: (context, index) {
        final room = rooms[index];
        final rule = automationRules[room] ??
            AutomationRule(
              isEnabled: false,
              temperatureThreshold: 25,
              humidityThreshold: 60,
              targetTemperature: 22,
            );

        return Card(
          margin: EdgeInsets.only(bottom: 16),
          elevation: 2,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color:
                                Theme.of(context).primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.meeting_room,
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                        SizedBox(width: 12),
                        Text(
                          room,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Switch(
                      value: rule.isEnabled,
                      activeColor: Theme.of(context).primaryColor,
                      onChanged: (value) {
                        setState(() {
                          automationRules[room] =
                              rule.copyWith(isEnabled: value);
                        });
                        _saveAutomationRule(room, automationRules[room]!);
                      },
                    ),
                  ],
                ),
                SizedBox(height: 16),
                Text(
                  'Otomasyon Kuralları',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                  ),
                ),
                SizedBox(height: 8),
                _buildRuleSection(
                  'Sıcaklık eşiği (°C)',
                  rule.temperatureThreshold.toString(),
                  Icons.thermostat,
                  () => _showTemperatureThresholdDialog(room, rule),
                ),
                _buildRuleSection(
                  'Nem eşiği (%)',
                  rule.humidityThreshold.toString(),
                  Icons.water_drop,
                  () => _showHumidityThresholdDialog(room, rule),
                ),
                _buildRuleSection(
                  'Hedef sıcaklık (°C)',
                  rule.targetTemperature.toString(),
                  Icons.ac_unit,
                  () => _showTargetTemperatureDialog(room, rule),
                ),
                SizedBox(height: 16),
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: rule.isEnabled
                        ? Colors.green.withOpacity(0.1)
                        : Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        rule.isEnabled ? Icons.check_circle : Icons.info,
                        color: rule.isEnabled ? Colors.green : Colors.grey,
                        size: 20,
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          rule.isEnabled
                              ? 'Oda sıcaklığı ${rule.temperatureThreshold}°C ${rule.isTemperatureAbove ? 'üzerine çıktığında' : 'altına düştüğünde'} veya nem oranı %${rule.humidityThreshold} ${rule.isHumidityAbove ? 'üzerine çıktığında' : 'altına düştüğünde'} klima ${rule.targetTemperature}°C ayarında otomatik olarak açılacak.'
                              : 'Otomatik klima kontrolü devre dışı.',
                          style: TextStyle(
                            fontSize: 14,
                            color: rule.isEnabled
                                ? Colors.green[800]
                                : Colors.grey[700],
                          ),
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
    );
  }

  Widget _buildRuleSection(
      String title, String value, IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: Theme.of(context).primaryColor,
                size: 18,
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.grey[800],
                ),
              ),
            ),
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).primaryColor,
              ),
            ),
            SizedBox(width: 8),
            Icon(
              Icons.chevron_right,
              color: Colors.grey[400],
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  void _showTemperatureThresholdDialog(String room, AutomationRule rule) {
    double tempValue = rule.temperatureThreshold.toDouble();
    bool isAbove = rule.isTemperatureAbove;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Sıcaklık Eşiği Ayarla'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            StatefulBuilder(
              builder: (context, setDialogState) {
                return Column(
                  children: [
                    // Karşılaştırma türü seçimi
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Klima, oda sıcaklığı bu değerin'),
                      ],
                    ),
                    SizedBox(height: 8),
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isAbove
                                ? Theme.of(context).primaryColor
                                : Colors.grey[300],
                            foregroundColor:
                                isAbove ? Colors.white : Colors.black87,
                            padding: EdgeInsets.symmetric(
                                horizontal: 10, vertical: 8),
                          ),
                          onPressed: () {
                            setDialogState(() {
                              isAbove = true;
                            });
                          },
                          child: Text('Üzerine Çıktığında',
                              style: TextStyle(fontSize: 13)),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: !isAbove
                                ? Theme.of(context).primaryColor
                                : Colors.grey[300],
                            foregroundColor:
                                !isAbove ? Colors.white : Colors.black87,
                            padding: EdgeInsets.symmetric(
                                horizontal: 10, vertical: 8),
                          ),
                          onPressed: () {
                            setDialogState(() {
                              isAbove = false;
                            });
                          },
                          child: Text('Altına Düştüğünde',
                              style: TextStyle(fontSize: 13)),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text(
                      'otomatik olarak açılacak:',
                      style: TextStyle(fontSize: 14),
                    ),
                    SizedBox(height: 16),
                    Text(
                      '${tempValue.round()}°C',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                    Slider(
                      value: tempValue,
                      min: 20,
                      max: 35,
                      divisions: 15,
                      activeColor: Theme.of(context).primaryColor,
                      onChanged: (value) {
                        setDialogState(() {
                          tempValue = value;
                        });
                      },
                    ),
                  ],
                );
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('İptal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
            ),
            onPressed: () {
              setState(() {
                automationRules[room] = rule.copyWith(
                  temperatureThreshold: tempValue.round(),
                  isTemperatureAbove: isAbove,
                );
              });
              _saveAutomationRule(room, automationRules[room]!);
              Navigator.pop(context);
            },
            child: Text('Kaydet'),
          ),
        ],
      ),
    );
  }

  void _showHumidityThresholdDialog(String room, AutomationRule rule) {
    double humidityValue = rule.humidityThreshold.toDouble();
    bool isAbove = rule.isHumidityAbove;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Nem Eşiği Ayarla'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            StatefulBuilder(
              builder: (context, setDialogState) {
                return Column(
                  children: [
                    // Karşılaştırma türü seçimi
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Klima, oda nem oranı bu değerin'),
                      ],
                    ),
                    SizedBox(height: 8),
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isAbove
                                ? Theme.of(context).primaryColor
                                : Colors.grey[300],
                            foregroundColor:
                                isAbove ? Colors.white : Colors.black87,
                            padding: EdgeInsets.symmetric(
                                horizontal: 10, vertical: 8),
                          ),
                          onPressed: () {
                            setDialogState(() {
                              isAbove = true;
                            });
                          },
                          child: Text('Üzerine Çıktığında',
                              style: TextStyle(fontSize: 13)),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: !isAbove
                                ? Theme.of(context).primaryColor
                                : Colors.grey[300],
                            foregroundColor:
                                !isAbove ? Colors.white : Colors.black87,
                            padding: EdgeInsets.symmetric(
                                horizontal: 10, vertical: 8),
                          ),
                          onPressed: () {
                            setDialogState(() {
                              isAbove = false;
                            });
                          },
                          child: Text('Altına Düştüğünde',
                              style: TextStyle(fontSize: 13)),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text(
                      'otomatik olarak açılacak:',
                      style: TextStyle(fontSize: 14),
                    ),
                    SizedBox(height: 16),
                    Text(
                      '%${humidityValue.round()}',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                    Slider(
                      value: humidityValue,
                      min: 40,
                      max: 90,
                      divisions: 50,
                      activeColor: Theme.of(context).primaryColor,
                      onChanged: (value) {
                        setDialogState(() {
                          humidityValue = value;
                        });
                      },
                    ),
                  ],
                );
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('İptal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
            ),
            onPressed: () {
              setState(() {
                automationRules[room] = rule.copyWith(
                  humidityThreshold: humidityValue.round(),
                  isHumidityAbove: isAbove,
                );
              });
              _saveAutomationRule(room, automationRules[room]!);
              Navigator.pop(context);
            },
            child: Text('Kaydet'),
          ),
        ],
      ),
    );
  }

  void _showTargetTemperatureDialog(String room, AutomationRule rule) {
    double tempValue = rule.targetTemperature.toDouble();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Hedef Sıcaklık Ayarla'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Klima otomatik olarak açıldığında ayarlanacak sıcaklık:',
              style: TextStyle(fontSize: 14),
            ),
            SizedBox(height: 16),
            StatefulBuilder(
              builder: (context, setDialogState) {
                return Column(
                  children: [
                    Text(
                      '${tempValue.round()}°C',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                    Slider(
                      value: tempValue,
                      min: 17,
                      max: 30,
                      divisions: 13,
                      activeColor: Theme.of(context).primaryColor,
                      onChanged: (value) {
                        setDialogState(() {
                          tempValue = value;
                        });
                      },
                    ),
                  ],
                );
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('İptal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
            ),
            onPressed: () {
              setState(() {
                automationRules[room] = rule.copyWith(
                  targetTemperature: tempValue.round(),
                );
              });
              _saveAutomationRule(room, automationRules[room]!);
              Navigator.pop(context);
            },
            child: Text('Kaydet'),
          ),
        ],
      ),
    );
  }
}

class AutomationRule {
  final bool isEnabled;
  final int temperatureThreshold;
  final int humidityThreshold;
  final int targetTemperature;
  final bool
      isTemperatureAbove; // Sıcaklık eşiği için karşılaştırma türü (true: büyükse, false: küçükse)
  final bool
      isHumidityAbove; // Nem eşiği için karşılaştırma türü (true: büyükse, false: küçükse)

  AutomationRule({
    required this.isEnabled,
    required this.temperatureThreshold,
    required this.humidityThreshold,
    required this.targetTemperature,
    this.isTemperatureAbove = true, // Varsayılan olarak büyükse
    this.isHumidityAbove = true, // Varsayılan olarak büyükse
  });

  Map<String, dynamic> toMap() {
    return {
      'isEnabled': isEnabled,
      'temperatureThreshold': temperatureThreshold,
      'humidityThreshold': humidityThreshold,
      'targetTemperature': targetTemperature,
      'isTemperatureAbove': isTemperatureAbove,
      'isHumidityAbove': isHumidityAbove,
    };
  }

  factory AutomationRule.fromMap(Map<String, dynamic> map) {
    return AutomationRule(
      isEnabled: map['isEnabled'] ?? false,
      temperatureThreshold: map['temperatureThreshold'] ?? 25,
      humidityThreshold: map['humidityThreshold'] ?? 60,
      targetTemperature: map['targetTemperature'] ?? 22,
      isTemperatureAbove: map['isTemperatureAbove'] ?? true,
      isHumidityAbove: map['isHumidityAbove'] ?? true,
    );
  }

  AutomationRule copyWith({
    bool? isEnabled,
    int? temperatureThreshold,
    int? humidityThreshold,
    int? targetTemperature,
    bool? isTemperatureAbove,
    bool? isHumidityAbove,
  }) {
    return AutomationRule(
      isEnabled: isEnabled ?? this.isEnabled,
      temperatureThreshold: temperatureThreshold ?? this.temperatureThreshold,
      humidityThreshold: humidityThreshold ?? this.humidityThreshold,
      targetTemperature: targetTemperature ?? this.targetTemperature,
      isTemperatureAbove: isTemperatureAbove ?? this.isTemperatureAbove,
      isHumidityAbove: isHumidityAbove ?? this.isHumidityAbove,
    );
  }
}
