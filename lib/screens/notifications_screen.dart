import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  _NotificationsScreenState createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  bool _isLoading = true;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Bildirim tercihleri
  bool _allNotificationsEnabled = true;
  Map<String, bool> _notificationPreferences = {
    'security': true,
    'device': true,
    'system': true,
    'temperature': true,
    'batteryLow': true,
  };
  
  bool _disturbeMode = false;
  String _disturbModeTimeRange = '22:00 - 07:00';

  @override
  void initState() {
    super.initState();
    _loadNotificationSettings();
  }
  
  // Kullanıcının bildirim tercihlerini yükle
  Future<void> _loadNotificationSettings() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final userId = _auth.currentUser?.uid;
      if (userId != null) {
        final userDoc = await _firestore.collection('users').doc(userId).get();
        
        if (userDoc.exists) {
          final userData = userDoc.data();
          
          if (userData != null) {
            setState(() {
              _allNotificationsEnabled = userData['notificationsEnabled'] ?? true;
              
              if (userData.containsKey('notificationPreferences') && 
                  userData['notificationPreferences'] is Map) {
                final prefs = userData['notificationPreferences'] as Map;
                
                prefs.forEach((key, value) {
                  if (_notificationPreferences.containsKey(key) && value is bool) {
                    _notificationPreferences[key] = value;
                  }
                });
              }
              
              _disturbeMode = userData['disturbeMode'] ?? false;
              _disturbModeTimeRange = userData['disturbModeTimeRange'] ?? '22:00 - 07:00';
            });
          }
        }
      }
    } catch (e) {
      print('Bildirim ayarları yüklenirken hata: $e');
      _showSnackBar('Bildirim ayarları yüklenemedi');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  // Bildirim ayarlarını kaydet
  Future<void> _saveNotificationSettings() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final userId = _auth.currentUser?.uid;
      if (userId != null) {
        await _firestore.collection('users').doc(userId).update({
          'notificationsEnabled': _allNotificationsEnabled,
          'notificationPreferences': _notificationPreferences,
          'disturbeMode': _disturbeMode,
          'disturbModeTimeRange': _disturbModeTimeRange,
        });
        
        _showSnackBar('Bildirim ayarları kaydedildi');
      }
    } catch (e) {
      print('Bildirim ayarları kaydedilirken hata: $e');
      _showSnackBar('Bildirim ayarları kaydedilemedi');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  // Snackbar mesajı göster
  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
  
  // Zaman aralığı seçme diyaloğunu göster
  Future<void> _showTimeRangePicker() async {
    // Mevcut başlangıç ve bitiş saatlerini ayıkla
    final timeParts = _disturbModeTimeRange.split(' - ');
    TimeOfDay startTime = TimeOfDay(hour: 22, minute: 0);
    TimeOfDay endTime = TimeOfDay(hour: 7, minute: 0);
    
    if (timeParts.length == 2) {
      // Mevcut başlangıç saatini çözümle
      final startParts = timeParts[0].split(':');
      if (startParts.length == 2) {
        startTime = TimeOfDay(
          hour: int.tryParse(startParts[0]) ?? 22, 
          minute: int.tryParse(startParts[1]) ?? 0
        );
      }
      
      // Mevcut bitiş saatini çözümle
      final endParts = timeParts[1].split(':');
      if (endParts.length == 2) {
        endTime = TimeOfDay(
          hour: int.tryParse(endParts[0]) ?? 7, 
          minute: int.tryParse(endParts[1]) ?? 0
        );
      }
    }
    
    // Başlangıç saatini seç
    final TimeOfDay? newStartTime = await showTimePicker(
      context: context,
      initialTime: startTime,
      helpText: 'Başlangıç Saati',
    );
    
    if (newStartTime == null) return;
    
    // Bitiş saatini seç
    final TimeOfDay? newEndTime = await showTimePicker(
      context: context,
      initialTime: endTime,
      helpText: 'Bitiş Saati',
    );
    
    if (newEndTime == null) return;
    
    // Yeni zaman aralığını ayarla
    setState(() {
      _disturbModeTimeRange = '${newStartTime.format(context)} - ${newEndTime.format(context)}';
    });
    
    // Ayarları kaydet
    await _saveNotificationSettings();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Bildirim Ayarları'),
        backgroundColor: Theme.of(context).primaryColor,
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: Theme.of(context).primaryColor,
              ),
            )
          : SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Ana Açıklama
                  Text(
                    'Bildirim Tercihleri',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Hangi bildirimler alacağınızı ve ne zaman alacağınızı ayarlayın.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  SizedBox(height: 24),
                  
                  // Ana Bildirim Açma/Kapama
                  Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: SwitchListTile(
                        title: Text(
                          'Tüm Bildirimler',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        subtitle: Text(
                          _allNotificationsEnabled 
                              ? 'Bildirimler açık' 
                              : 'Bildirimler kapalı',
                        ),
                        value: _allNotificationsEnabled,
                        onChanged: (value) {
                          setState(() {
                            _allNotificationsEnabled = value;
                          });
                          _saveNotificationSettings();
                        },
                        secondary: Container(
                          padding: EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Theme.of(context).primaryColor.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.notifications_active,
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                        activeColor: Theme.of(context).primaryColor,
                      ),
                    ),
                  ),
                  SizedBox(height: 16),
                  
                  // Rahatsız Etmeyin Modu
                  _allNotificationsEnabled ? Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                    child: Column(
                      children: [
                        SwitchListTile(
                          title: Text(
                            'Rahatsız Etme Modu',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          subtitle: Text(
                            _disturbeMode 
                                ? 'Belirli saatlerde bildirim almazsınız' 
                                : 'Tüm saatlerde bildirim alırsınız',
                          ),
                          value: _disturbeMode,
                          onChanged: (value) {
                            setState(() {
                              _disturbeMode = value;
                            });
                            _saveNotificationSettings();
                          },
                          secondary: Container(
                            padding: EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.orange.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.do_not_disturb_on,
                              color: Colors.orange,
                            ),
                          ),
                          activeColor: Theme.of(context).primaryColor,
                        ),
                        if (_disturbeMode) Divider(height: 0),
                        if (_disturbeMode) ListTile(
                          title: Text('Sessiz Saatler'),
                          subtitle: Text(_disturbModeTimeRange),
                          trailing: Icon(Icons.arrow_forward_ios, size: 16),
                          onTap: _showTimeRangePicker,
                        ),
                      ],
                    ),
                  ) : SizedBox.shrink(),
                  
                  SizedBox(height: 16),
                  
                  // Bildirim Kategorileri
                  if (_allNotificationsEnabled) ...[
                    Text(
                      'Bildirim Türleri',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                    SizedBox(height: 12),
                    
                    // Güvenlik Bildirimleri
                    _buildNotificationTypeCard(
                      title: 'Güvenlik Bildirimleri',
                      subtitle: 'Güvenlik uyarıları ve ihlalleri',
                      icon: Icons.security,
                      color: Colors.red,
                      value: _notificationPreferences['security'] ?? true,
                      onChanged: (value) {
                        setState(() {
                          _notificationPreferences['security'] = value;
                        });
                        _saveNotificationSettings();
                      },
                    ),
                    
                    // Cihaz Bildirimleri
                    _buildNotificationTypeCard(
                      title: 'Cihaz Bildirimleri',
                      subtitle: 'Cihaz durumları ve uyarıları',
                      icon: Icons.devices,
                      color: Colors.blue,
                      value: _notificationPreferences['device'] ?? true,
                      onChanged: (value) {
                        setState(() {
                          _notificationPreferences['device'] = value;
                        });
                        _saveNotificationSettings();
                      },
                    ),
                    
                    // Sistem Bildirimleri
                    _buildNotificationTypeCard(
                      title: 'Sistem Bildirimleri',
                      subtitle: 'Güncellemeler ve bakım bildirimleri',
                      icon: Icons.system_update,
                      color: Colors.green,
                      value: _notificationPreferences['system'] ?? true,
                      onChanged: (value) {
                        setState(() {
                          _notificationPreferences['system'] = value;
                        });
                        _saveNotificationSettings();
                      },
                    ),
                    
                    // Sıcaklık Uyarıları
                    _buildNotificationTypeCard(
                      title: 'Sıcaklık Uyarıları',
                      subtitle: 'Sıcaklık değişiklikleri bildirilir',
                      icon: Icons.thermostat,
                      color: Colors.orange,
                      value: _notificationPreferences['temperature'] ?? true,
                      onChanged: (value) {
                        setState(() {
                          _notificationPreferences['temperature'] = value;
                        });
                        _saveNotificationSettings();
                      },
                    ),
                    
                    // Düşük Pil Uyarıları
                    _buildNotificationTypeCard(
                      title: 'Düşük Pil Uyarıları',
                      subtitle: 'Cihazlarınızın pil seviyesi düştüğünde uyarılır',
                      icon: Icons.battery_alert,
                      color: Colors.amber,
                      value: _notificationPreferences['batteryLow'] ?? true,
                      onChanged: (value) {
                        setState(() {
                          _notificationPreferences['batteryLow'] = value;
                        });
                        _saveNotificationSettings();
                      },
                    ),
                  ],
                ],
              ),
            ),
    );
  }
  
  // Bildirim türü kartı
  Widget _buildNotificationTypeCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 1,
      margin: EdgeInsets.only(bottom: 12),
      child: SwitchListTile(
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Text(subtitle),
        value: value,
        onChanged: onChanged,
        secondary: Container(
          padding: EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: color,
          ),
        ),
        activeColor: Theme.of(context).primaryColor,
      ),
    );
  }
} 