import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:smarthome/services/database_service.dart';
import 'dart:async';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final user = FirebaseAuth.instance.currentUser;
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  
  final DatabaseService _databaseService = DatabaseService();
  
  bool _isLoading = false;
  bool _isSaving = false;
  Map<String, bool> notificationPreferences = {
    'pushNotifications': true,
    'emailNotifications': true,
    'activityAlerts': true,
  };

  @override
  void initState() {
    super.initState();
    // Kullanıcı bilgilerini yükle
    _loadUserData();
    if (user != null) {
      _emailController.text = user!.email ?? '';
    }
  }
  
  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Firestore'dan kullanıcı bilgilerini yükle
      Map<String, dynamic>? userData = await _databaseService.getUserProfile();
      
      if (userData != null) {
        setState(() {
          _firstNameController.text = userData['firstName'] ?? '';
          _lastNameController.text = userData['lastName'] ?? '';
          
          // Bildirim tercihlerini yükle
          if (userData.containsKey('notificationPreferences')) {
            Map<String, dynamic> prefs = userData['notificationPreferences'];
            notificationPreferences = {
              'pushNotifications': prefs['pushNotifications'] ?? true,
              'emailNotifications': prefs['emailNotifications'] ?? true,
              'activityAlerts': prefs['activityAlerts'] ?? true,
            };
          }
        });
      }
    } catch (e) {
      _showSnackBar('Kullanıcı bilgileri yüklenirken hata oluştu');
      print('Hata: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  // Profil bilgilerini güncelleyen fonksiyon
  Future<void> _updateProfile() async {
    if (_firstNameController.text.isEmpty || _lastNameController.text.isEmpty) {
      _showSnackBar('Ad ve soyad alanlarını doldurunuz');
      return;
    }
    
    setState(() {
      _isSaving = true;
    });
    
    try {
      Map<String, dynamic> userData = {
        'firstName': _firstNameController.text,
        'lastName': _lastNameController.text,
        'email': user?.email ?? '',
        'updatedAt': FieldValue.serverTimestamp(),
        'notificationPreferences': notificationPreferences,
      };
      
      bool success = await _databaseService.updateUserProfile(userData);
      
      if (success) {
        _showSnackBar('Profil bilgileriniz güncellendi');
      } else {
        _showSnackBar('Profil güncellenirken bir hata oluştu');
      }
    } catch (e) {
      _showSnackBar('Hata: $e');
      print('Hata: $e');
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }
  
  // Şifre değiştirme diyaloğunu göster
  void _showChangePasswordDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => ChangePasswordDialog(
        email: user?.email ?? '',
        onSuccess: (message) {
          _showSnackBar(message);
        },
        onForgotPassword: () {
          Navigator.of(context).pop();
          _showPasswordResetEmailDialog();
        },
      ),
    );
  }
  
  // Şifre sıfırlama e-posta diyaloğunu göster
  void _showPasswordResetEmailDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Şifre Sıfırlama'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Şifrenizi sıfırlamak için e-postanıza bir bağlantı göndereceğiz.',
                style: TextStyle(fontSize: 14),
              ),
              SizedBox(height: 16),
              Text(
                'E-posta: ${user?.email ?? ""}',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('İptal'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                await _sendPasswordResetEmail();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
              ),
              child: Text('Sıfırlama Bağlantısı Gönder'),
            ),
          ],
        );
      },
    );
  }
  
  // Şifre sıfırlama e-postası gönderen fonksiyon
  Future<void> _sendPasswordResetEmail() async {
    if (user?.email == null) {
      _showSnackBar('E-posta adresi bulunamadı');
      return;
    }
    
    try {
      bool success = await _databaseService.sendPasswordResetEmail(user!.email!);
      
      if (success) {
        _showSnackBar('Şifre sıfırlama bağlantısı e-posta adresinize gönderildi');
      } else {
        _showSnackBar('Şifre sıfırlama e-postası gönderilemedi');
      }
    } catch (e) {
      _showSnackBar('Hata: $e');
    }
  }
  
  // Bildirim tercihlerini göster
  void _showNotificationPreferences() {
    showDialog(
      context: context,
      builder: (context) {
        // Geçici değişiklikler için local tercihler
        Map<String, bool> tempPrefs = Map.from(notificationPreferences);
        
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Bildirim Tercihleri'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildSwitchTile(
                    'Push Bildirimleri',
                    'Anlık bildirimler al',
                    tempPrefs['pushNotifications'] ?? true,
                    (value) {
                      setState(() {
                        tempPrefs['pushNotifications'] = value;
                      });
                    },
                  ),
                  _buildSwitchTile(
                    'E-posta Bildirimleri',
                    'Güncellemeler için e-posta al',
                    tempPrefs['emailNotifications'] ?? true,
                    (value) {
                      setState(() {
                        tempPrefs['emailNotifications'] = value;
                      });
                    },
                  ),
                  _buildSwitchTile(
                    'Aktivite Uyarıları',
                    'Evdeki hareketlerde uyarı al',
                    tempPrefs['activityAlerts'] ?? true,
                    (value) {
                      setState(() {
                        tempPrefs['activityAlerts'] = value;
                      });
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: Text('İptal'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    Navigator.pop(context);
                    await _updateNotificationPreferences(tempPrefs);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                  ),
                  child: Text('Kaydet'),
                ),
              ],
            );
          },
        );
      },
    );
  }
  
  // Bildirim tercihlerini güncelleyen fonksiyon
  Future<void> _updateNotificationPreferences(Map<String, bool> prefs) async {
    try {
      bool success = await _databaseService.updateNotificationPreferences(prefs);
      
      if (success) {
        setState(() {
          notificationPreferences = prefs;
        });
        _showSnackBar('Bildirim tercihleri güncellendi');
      } else {
        _showSnackBar('Bildirim tercihleri güncellenirken hata oluştu');
      }
    } catch (e) {
      _showSnackBar('Hata: $e');
    }
  }
  
  // Gizlilik ayarlarını göster
  void _showPrivacySettings() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Gizlilik Ayarları'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: Text('Veri Kullanımı'),
                subtitle: Text('Uygulamanın verilerinizi nasıl kullandığını görüntüleyin'),
                onTap: () {
                  Navigator.pop(context);
                  // Veri kullanım sayfasına yönlendir
                },
              ),
              ListTile(
                title: Text('Hesabı Sil'),
                subtitle: Text('Hesabınızı ve tüm verilerinizi kalıcı olarak silin'),
                onTap: () {
                  Navigator.pop(context);
                  _showDeleteAccountConfirmation();
                },
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
              ),
              child: Text('Kapat'),
            ),
          ],
        );
      },
    );
  }
  
  // Hesap silme onayı
  void _showDeleteAccountConfirmation() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Hesabı Sil'),
          content: Text(
            'Hesabınızı silmek istediğinizden emin misiniz? Bu işlem geri alınamaz ve tüm verileriniz silinecektir.',
            style: TextStyle(fontSize: 14),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('İptal'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                // Hesabı silme işlemini burada yapabilirsiniz
                _showSnackBar('Bu özellik şu anda aktif değil.');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              child: Text('Hesabı Sil'),
            ),
          ],
        );
      },
    );
  }
  
  // Switch düğmesi ile bir ayar satırı oluştur
  Widget _buildSwitchTile(
    String title, 
    String subtitle, 
    bool value, 
    Function(bool) onChanged
  ) {
    return ListTile(
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: Theme.of(context).primaryColor,
      ),
    );
  }
  
  // Snackbar mesajı göster
  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Profil'),
        backgroundColor: Theme.of(context).primaryColor,
      ),
      body: _isLoading 
          ? Center(child: CircularProgressIndicator(color: Theme.of(context).primaryColor))
          : SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Profil Fotoğrafı ve İsim
                  Center(
                    child: Column(
                      children: [
                        Stack(
                          children: [
                            CircleAvatar(
                              radius: 50,
                              backgroundColor: Theme.of(context).primaryColor.withOpacity(0.2),
                              child: Icon(
                                Icons.person,
                                size: 50,
                                color: Theme.of(context).primaryColor,
                              ),
                            ),
                            Positioned(
                              right: 0,
                              bottom: 0,
                              child: Container(
                                padding: EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).primaryColor,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.edit,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 16),
                        Text(
                          user?.email ?? '',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 32),

                  // Kişisel Bilgiler
                  Text(
                    'Kişisel Bilgiler',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 16),
                  _buildTextField(
                    'Ad',
                    _firstNameController,
                    Icons.person_outline,
                  ),
                  SizedBox(height: 16),
                  _buildTextField(
                    'Soyad',
                    _lastNameController,
                    Icons.person_outline,
                  ),
                  SizedBox(height: 32),

                  // Hesap Ayarları
                  Text(
                    'Hesap Ayarları',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 16),
                  _buildSettingCard(
                    'Şifre Değiştir',
                    Icons.lock_outline,
                    _showChangePasswordDialog,
                  ),
                  SizedBox(height: 12),
                  _buildSettingCard(
                    'Bildirim Tercihleri',
                    Icons.notifications_none,
                    _showNotificationPreferences,
                  ),
                  SizedBox(height: 12),
                  _buildSettingCard(
                    'Gizlilik Ayarları',
                    Icons.privacy_tip_outlined,
                    _showPrivacySettings,
                  ),
                  SizedBox(height: 32),

                  // Kaydet Butonu
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _updateProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColor,
                        padding: EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isSaving 
                          ? CircularProgressIndicator(color: Colors.white, strokeWidth: 3)
                          : Text(
                              'Değişiklikleri Kaydet',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller,
    IconData icon,
  ) {
    return Container(
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
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(
            icon,
            color: Theme.of(context).primaryColor,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
        ),
      ),
    );
  }

  Widget _buildSettingCard(
    String title,
    IconData icon,
    VoidCallback onTap,
  ) {
    return Container(
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
            size: 24,
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w500,
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
}

// Diyalog kapandığında controller'ları dispose etmek için ayrı StatefulWidget
class ChangePasswordDialog extends StatefulWidget {
  final String email;
  final Function(String) onSuccess;
  final VoidCallback onForgotPassword;

  const ChangePasswordDialog({
    super.key,
    required this.email,
    required this.onSuccess,
    required this.onForgotPassword,
  });

  @override
  _ChangePasswordDialogState createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends State<ChangePasswordDialog> {
  final currentPasswordController = TextEditingController();
  final newPasswordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  
  bool isObscureCurrentPassword = true;
  bool isObscureNewPassword = true;
  bool isObscureConfirmPassword = true;
  bool isChangingPassword = false;
  String? errorMessage;
  
  final DatabaseService _databaseService = DatabaseService();
  
  @override
  void dispose() {
    // Widget dispose edildiğinde controller'ları temizle
    currentPasswordController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Şifre Değiştir'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (errorMessage != null) ...[
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: Colors.red),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        errorMessage!,
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 16),
            ],
            
            Text('Mevcut E-posta: ${widget.email}'),
            SizedBox(height: 16),
            
            // Mevcut şifre
            TextField(
              controller: currentPasswordController,
              obscureText: isObscureCurrentPassword,
              decoration: InputDecoration(
                labelText: 'Mevcut Şifre',
                border: OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(
                    isObscureCurrentPassword ? Icons.visibility_off : Icons.visibility,
                  ),
                  onPressed: () {
                    setState(() {
                      isObscureCurrentPassword = !isObscureCurrentPassword;
                    });
                  },
                ),
              ),
            ),
            SizedBox(height: 8),
            
            // Şifre sıfırlama linki
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: widget.onForgotPassword,
                child: Text(
                  'Şifremi unuttum',
                  style: TextStyle(
                    color: Theme.of(context).primaryColor,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
            SizedBox(height: 8),
            
            // Yeni şifre
            TextField(
              controller: newPasswordController,
              obscureText: isObscureNewPassword,
              decoration: InputDecoration(
                labelText: 'Yeni Şifre',
                border: OutlineInputBorder(),
                helperText: 'En az 6 karakter olmalı',
                suffixIcon: IconButton(
                  icon: Icon(
                    isObscureNewPassword ? Icons.visibility_off : Icons.visibility,
                  ),
                  onPressed: () {
                    setState(() {
                      isObscureNewPassword = !isObscureNewPassword;
                    });
                  },
                ),
              ),
            ),
            SizedBox(height: 16),
            
            // Şifre onayı
            TextField(
              controller: confirmPasswordController,
              obscureText: isObscureConfirmPassword,
              decoration: InputDecoration(
                labelText: 'Yeni Şifre (Tekrar)',
                border: OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(
                    isObscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
                  ),
                  onPressed: () {
                    setState(() {
                      isObscureConfirmPassword = !isObscureConfirmPassword;
                    });
                  },
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: isChangingPassword ? null : () {
            Navigator.of(context).pop();
          },
          child: Text('İptal'),
        ),
        ElevatedButton(
          onPressed: isChangingPassword ? null : _changePassword,
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).primaryColor,
          ),
          child: isChangingPassword
              ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : Text('Şifreyi Değiştir'),
        ),
      ],
    );
  }
  
  // Şifre değiştirme işlemi
  Future<void> _changePassword() async {
    // Basit doğrulama
    if (currentPasswordController.text.isEmpty) {
      setState(() {
        errorMessage = 'Mevcut şifrenizi girin';
      });
      return;
    }
    
    if (newPasswordController.text.isEmpty) {
      setState(() {
        errorMessage = 'Yeni şifrenizi girin';
      });
      return;
    }
    
    if (newPasswordController.text.length < 6) {
      setState(() {
        errorMessage = 'Şifre en az 6 karakter olmalıdır';
      });
      return;
    }
    
    if (newPasswordController.text != confirmPasswordController.text) {
      setState(() {
        errorMessage = 'Şifreler eşleşmiyor';
      });
      return;
    }
    
    // Şifre değiştirme işlemi
    setState(() {
      isChangingPassword = true;
      errorMessage = null;
    });
    
    try {
      final currentPassword = currentPasswordController.text;
      final newPassword = newPasswordController.text;
      
      Map<String, dynamic> result = await _databaseService.changePassword(
        currentPassword,
        newPassword,
      );
      
      if (result['success']) {
        Navigator.of(context).pop();
        widget.onSuccess(result['message']);
      } else {
        setState(() {
          errorMessage = result['message'];
          isChangingPassword = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Şifre değiştirme işlemi başarısız: $e';
        isChangingPassword = false;
      });
    }
  }
} 