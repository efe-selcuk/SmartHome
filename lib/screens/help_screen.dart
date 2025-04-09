import 'package:flutter/material.dart';

class HelpScreen extends StatelessWidget {
  final List<Map<String, String>> faqs = const [
    {
      'question': 'Oda nasıl eklenir?',
      'answer':
          'Ana ekranda "Oda Ekle" butonuna tıklayarak yeni bir oda ekleyebilirsiniz. Açılan menüden oda tipini seçin ve odanızı oluşturun.',
    },
    {
      'question': 'Cihaz nasıl kontrol edilir?',
      'answer':
          'Oda detay ekranında bulunan cihazların yanındaki açma/kapama düğmelerini kullanarak cihazları kontrol edebilirsiniz.',
    },
    {
      'question': 'Güvenlik sistemi nasıl çalışır?',
      'answer':
          'Güvenlik ekranından alarm sistemini aktif edebilir, kamera görüntülerini izleyebilir ve hareket sensörlerini yönetebilirsiniz.',
    },
    {
      'question': 'Şifremi unuttum ne yapmalıyım?',
      'answer':
          'Giriş ekranındaki "Şifremi Unuttum" seçeneğini kullanarak e-posta adresinize sıfırlama bağlantısı gönderebilirsiniz.',
    },
  ];

  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      appBar: AppBar(
        title: Text('Yardım'),
        backgroundColor: Theme.of(context).primaryColor,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Arama Çubuğu
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Nasıl yardımcı olabiliriz?',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: isDark ? Colors.grey[800] : Colors.grey[100],
                ),
              ),
            ),

            // Hızlı Yardım Kartları
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Hızlı Yardım',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ),
            SizedBox(height: 16),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  _buildQuickHelpCard(
                    context,
                    'Başlangıç Rehberi',
                    Icons.play_circle_outline,
                    Colors.blue,
                  ),
                  _buildQuickHelpCard(
                    context,
                    'Oda Yönetimi',
                    Icons.room_preferences,
                    Colors.green,
                  ),
                  _buildQuickHelpCard(
                    context,
                    'Cihaz Bağlantısı',
                    Icons.devices_other,
                    Colors.purple,
                  ),
                ],
              ),
            ),

            // Sık Sorulan Sorular
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Sık Sorulan Sorular',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ),
            ListView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: faqs.length,
              itemBuilder: (context, index) {
                return _buildFAQCard(
                  context,
                  faqs[index]['question']!,
                  faqs[index]['answer']!,
                );
              },
            ),
            SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickHelpCard(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      width: 160,
      margin: EdgeInsets.only(right: 16),
      decoration: BoxDecoration(
        color: isDark ? Color(0xFF2C2C2C) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {},
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: 24,
                  ),
                ),
                SizedBox(height: 12),
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFAQCard(
    BuildContext context,
    String question,
    String answer,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? Color(0xFF2C2C2C) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: ExpansionTile(
        title: Text(
          question,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        collapsedIconColor: isDark ? Colors.white70 : Colors.grey[700],
        iconColor: Theme.of(context).primaryColor,
        children: [
          Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              answer,
              style: TextStyle(
                color: isDark ? Colors.white70 : Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
} 