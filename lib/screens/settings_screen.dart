import 'package:flutter/material.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool isDarkMode = false;
  bool isNotificationsEnabled = true;
  bool isLocationEnabled = true;
  String selectedLanguage = 'Türkçe';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Ayarlar'),
        backgroundColor: Theme.of(context).primaryColor,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Genel Ayarlar
            _buildSectionHeader('Genel'),
            _buildSettingSwitch(
              'Karanlık Mod',
              'Uygulamanın karanlık temasını etkinleştir',
              Icons.dark_mode,
              isDarkMode,
              (value) {
                setState(() {
                  isDarkMode = value;
                });
              },
            ),
            _buildSettingSwitch(
              'Bildirimler',
              'Uygulama bildirimlerini yönet',
              Icons.notifications_none,
              isNotificationsEnabled,
              (value) {
                setState(() {
                  isNotificationsEnabled = value;
                });
              },
            ),
            _buildSettingSwitch(
              'Konum',
              'Konum servislerini etkinleştir',
              Icons.location_on_outlined,
              isLocationEnabled,
              (value) {
                setState(() {
                  isLocationEnabled = value;
                });
              },
            ),

            // Dil Ayarları
            _buildSectionHeader('Dil'),
            _buildLanguageSelector(),

            // Güvenlik Ayarları
            _buildSectionHeader('Güvenlik'),
            _buildSettingTile(
              'PIN Değiştir',
              'Uygulama kilit PIN kodunu değiştir',
              Icons.lock_outline,
              () {
                // PIN değiştirme işlemi
              },
            ),
            _buildSettingTile(
              'Biyometrik Kimlik',
              'Parmak izi veya yüz tanıma ile giriş',
              Icons.fingerprint,
              () {
                // Biyometrik ayarlar
              },
            ),

            // Veri ve Depolama
            _buildSectionHeader('Veri ve Depolama'),
            _buildSettingTile(
              'Veri Kullanımı',
              'Uygulama veri kullanımını görüntüle',
              Icons.data_usage,
              () {
                // Veri kullanımı detayları
              },
            ),
            _buildSettingTile(
              'Önbelleği Temizle',
              'Uygulama önbelleğini temizle',
              Icons.cleaning_services_outlined,
              () {
                // Önbellek temizleme
              },
            ),

            // Hakkında
            _buildSectionHeader('Hakkında'),
            _buildSettingTile(
              'Uygulama Versiyonu',
              '1.0.0',
              Icons.info_outline,
              () {
                // Versiyon detayları
              },
            ),
            _buildSettingTile(
              'Lisanslar',
              'Açık kaynak lisansları',
              Icons.description_outlined,
              () {
                // Lisans detayları
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).primaryColor,
        ),
      ),
    );
  }

  Widget _buildSettingSwitch(
    String title,
    String subtitle,
    IconData icon,
    bool value,
    Function(bool) onChanged,
  ) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        leading: Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: Theme.of(context).primaryColor,
          ),
        ),
        title: Text(title),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 12,
          ),
        ),
        trailing: Switch(
          value: value,
          onChanged: onChanged,
          activeColor: Theme.of(context).primaryColor,
        ),
      ),
    );
  }

  Widget _buildSettingTile(
    String title,
    String subtitle,
    IconData icon,
    VoidCallback onTap,
  ) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        leading: Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: Theme.of(context).primaryColor,
          ),
        ),
        title: Text(title),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 12,
          ),
        ),
        trailing: Icon(
          Icons.chevron_right,
          color: Colors.grey[400],
        ),
        onTap: onTap,
      ),
    );
  }

  Widget _buildLanguageSelector() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        leading: Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.language,
            color: Theme.of(context).primaryColor,
          ),
        ),
        title: Text('Dil'),
        subtitle: Text(
          'Uygulama dilini değiştir',
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 12,
          ),
        ),
        trailing: DropdownButton<String>(
          value: selectedLanguage,
          underline: Container(),
          items: [
            DropdownMenuItem(
              value: 'Türkçe',
              child: Text('Türkçe'),
            ),
            DropdownMenuItem(
              value: 'English',
              child: Text('English'),
            ),
          ],
          onChanged: (value) {
            setState(() {
              selectedLanguage = value!;
            });
          },
        ),
      ),
    );
  }
} 