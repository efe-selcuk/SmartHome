import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../main.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool isDarkMode = false;
  String selectedLanguage = 'Türkçe';
  String appVersion = '1.0.0';
  String appName = 'Smart Home';
  
  @override
  void initState() {
    super.initState();
    _loadSettings();
    _getAppInfo();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Context hazır olduğunda AppSettings'ten değerleri alabiliriz
    final settings = AppSettings.of(context);
    if (isDarkMode != settings.isDarkMode || selectedLanguage != settings.language) {
      setState(() {
        isDarkMode = settings.isDarkMode;
        selectedLanguage = settings.language;
      });
    }
  }
  
  // Ayarları yükle
  void _loadSettings() {
    setState(() {
      isDarkMode = isDarkMode;
      selectedLanguage = appLanguage;
    });
  }
  
  // Uygulama bilgilerini al
  Future<void> _getAppInfo() async {
    try {
      final PackageInfo info = await PackageInfo.fromPlatform();
      setState(() {
        appName = info.appName;
        appVersion = info.version;
      });
    } catch (e) {
      // Hata durumunda varsayılan değerleri kullan
      print('Uygulama bilgileri alınamadı: $e');
    }
  }
  
  // Karanlık mod değiştiğinde tema değişimini uygula
  void _onDarkModeChanged(bool value) {
    final settings = AppSettings.of(context);
    setState(() {
      isDarkMode = value;
    });
    
    // Ana uygulama temasını güncelle
    settings.updateTheme(value);
    
    // Tema değişimini bildir
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(isDarkMode 
          ? 'Karanlık mod etkinleştirildi'
          : 'Karanlık mod devre dışı bırakıldı'
        ),
        duration: Duration(seconds: 2),
      ),
    );
  }
  
  // Dil değiştiğinde uygula
  void _onLanguageChanged(String? value) {
    if (value != null) {
      final settings = AppSettings.of(context);
      setState(() {
        selectedLanguage = value;
      });
      
      // Ana uygulama dilini güncelle
      settings.updateLanguage(value);
      
      // Dil değişimini bildir
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Dil değiştirildi: $selectedLanguage'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }
  
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
              _onDarkModeChanged,
            ),

            // Dil Ayarları
            _buildSectionHeader('Dil'),
            _buildLanguageSelector(),

            // Hakkında
            _buildSectionHeader('Hakkında'),
            _buildSettingTile(
              'Uygulama Versiyonu',
              appVersion,
              Icons.info_outline,
              _showVersionInfo,
            ),
            _buildSettingTile(
              'Lisanslar',
              'Açık kaynak lisansları',
              Icons.description_outlined,
              _showLicenses,
            ),
          ],
        ),
      ),
    );
  }

  // Versiyon bilgisini göster
  void _showVersionInfo() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        child: Container(
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark ? Color(0xFF2C2C2C) : Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Logo veya ikon
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.home_filled,
                  color: Theme.of(context).primaryColor,
                  size: 40,
                ),
              ),
              SizedBox(height: 20),
              // Uygulama adı
              Text(
                appName,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              SizedBox(height: 8),
              // Versiyon
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: isDark ? Color(0xFF3A3A3A) : Colors.grey[100],
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Versiyon $appVersion',
                  style: TextStyle(
                    color: isDark ? Colors.white70 : Colors.grey[800],
                    fontSize: 14,
                  ),
                ),
              ),
              SizedBox(height: 20),
              Text(
                '© ${DateTime.now().year} Tüm hakları saklıdır',
                style: TextStyle(
                  color: isDark ? Colors.white54 : Colors.grey[600],
                  fontSize: 12,
                ),
              ),
              SizedBox(height: 16),
              // Kapat butonu
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Text('Tamam'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  // Lisans bilgilerini göster
  void _showLicenses() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        child: Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? Color(0xFF2C2C2C) : Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Başlık ve Kapat Buton
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.description_outlined, 
                        color: Theme.of(context).primaryColor
                      ),
                      SizedBox(width: 10),
                      Text(
                        'Lisanslar', 
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.close,
                      color: isDark ? Colors.white70 : Colors.black54,
                    ),
                    onPressed: () => Navigator.pop(context),
                    padding: EdgeInsets.zero,
                    constraints: BoxConstraints(),
                  ),
                ],
              ),
              Divider(color: isDark ? Colors.grey[800] : Colors.grey[300]),
              // İçerik
              Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.4,
                ),
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    Text(
                      'Kullanılan Açık Kaynak Yazılımlar',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: isDark ? Colors.white : Colors.grey[800],
                      ),
                    ),
                    SizedBox(height: 12),
                    _buildLicenseItem('Flutter', 'BSD', 'flutter.dev'),
                    _buildLicenseItem('Firebase', 'Apache 2.0', 'firebase.google.com'),
                    _buildLicenseItem('Package Info Plus', 'BSD', 'pub.dev/packages/package_info_plus'),
                    _buildLicenseItem('Shared Preferences', 'BSD', 'pub.dev/packages/shared_preferences'),
                    _buildLicenseItem('Font Awesome', 'MIT', 'fontawesome.com'),
                  ],
                ),
              ),
              Divider(color: isDark ? Colors.grey[800] : Colors.grey[300]),
              // Alt Bilgi ve Butonlar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '© ${DateTime.now().year} Smart Home',
                    style: TextStyle(
                      fontSize: 11, 
                      color: isDark ? Colors.white54 : Colors.grey[600],
                    ),
                  ),
                  TextButton(
                    onPressed: () => _openFullLicenses(),
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                      minimumSize: Size(0, 0),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      'Tüm Lisanslar',
                      style: TextStyle(
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  // Tüm lisansları görüntülemek için Flutter'ın standart lisans sayfasını aç
  void _openFullLicenses() {
    Navigator.pop(context); // Mevcut dialog'u kapat
    
    showLicensePage(
      context: context,
      applicationName: appName,
      applicationVersion: appVersion,
      applicationLegalese: '© ${DateTime.now().year} All rights reserved',
    );
  }
  
  // Lisans kartı widget'ı
  Widget _buildLicenseItem(String name, String licenseType, String url) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Card(
      elevation: 0,
      margin: EdgeInsets.symmetric(vertical: 4),
      color: isDark ? Color(0xFF383838) : Colors.grey[50],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: isDark ? Colors.grey[700]! : Colors.grey[200]!, 
          width: 1
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              name,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            SizedBox(height: 6),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                licenseType,
                style: TextStyle(
                  color: Theme.of(context).primaryColor,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            SizedBox(height: 6),
            Text(
              url,
              style: TextStyle(
                color: isDark ? Colors.blue[300] : Colors.blue[700],
                fontSize: 11,
                decoration: TextDecoration.underline,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? Theme.of(context).cardTheme.color : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: isDark 
              ? Colors.black.withOpacity(0.2) 
              : Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        leading: Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor.withOpacity(0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: Theme.of(context).primaryColor,
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            color: isDark ? Colors.white70 : Colors.grey[600],
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? Theme.of(context).cardTheme.color : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: isDark 
              ? Colors.black.withOpacity(0.2) 
              : Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        leading: Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor.withOpacity(0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: Theme.of(context).primaryColor,
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            color: isDark ? Colors.white70 : Colors.grey[600],
            fontSize: 12,
          ),
        ),
        trailing: Icon(
          Icons.chevron_right,
          color: isDark ? Colors.white54 : Colors.grey[400],
        ),
        onTap: onTap,
      ),
    );
  }

  Widget _buildLanguageSelector() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? Theme.of(context).cardTheme.color : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: isDark 
              ? Colors.black.withOpacity(0.2) 
              : Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        leading: Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor.withOpacity(0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.language,
            color: Theme.of(context).primaryColor,
          ),
        ),
        title: Text(
          'Dil',
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        subtitle: Text(
          'Uygulama dilini değiştir',
          style: TextStyle(
            color: isDark ? Colors.white70 : Colors.grey[600],
            fontSize: 12,
          ),
        ),
        trailing: Theme(
          data: Theme.of(context).copyWith(
            canvasColor: isDark ? Color(0xFF383838) : Colors.white,
          ),
          child: DropdownButton<String>(
            value: selectedLanguage,
            underline: Container(),
            icon: Icon(
              Icons.arrow_drop_down,
              color: isDark ? Colors.white70 : Colors.grey[700],
            ),
            items: [
              DropdownMenuItem(
                value: 'Türkçe',
                child: Text(
                  'Türkçe',
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ),
              DropdownMenuItem(
                value: 'English',
                child: Text(
                  'English',
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ),
            ],
            onChanged: _onLanguageChanged,
          ),
        ),
      ),
    );
  }
} 