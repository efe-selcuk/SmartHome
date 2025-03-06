import 'package:flutter/material.dart';

class HelpScreen extends StatelessWidget {
  final List<Map<String, String>> faqs = const [
    const {
      'question': 'Oda nasıl eklenir?',
      'answer':
          'Ana ekranda sağ üst köşedeki "+" butonuna tıklayarak yeni bir oda ekleyebilirsiniz. Açılan menüden oda tipini seçin ve odanızı oluşturun.',
    },
    const {
      'question': 'Cihaz nasıl kontrol edilir?',
      'answer':
          'Oda detay ekranında bulunan cihazların yanındaki açma/kapama düğmelerini kullanarak cihazları kontrol edebilirsiniz.',
    },
    const {
      'question': 'Güvenlik sistemi nasıl çalışır?',
      'answer':
          'Güvenlik ekranından alarm sistemini aktif edebilir, kamera görüntülerini izleyebilir ve hareket sensörlerini yönetebilirsiniz.',
    },
    const {
      'question': 'Bildirimler nasıl özelleştirilir?',
      'answer':
          'Ayarlar > Bildirimler menüsünden hangi olaylar için bildirim almak istediğinizi seçebilirsiniz.',
    },
    const {
      'question': 'Şifremi unuttum ne yapmalıyım?',
      'answer':
          'Giriş ekranındaki "Şifremi Unuttum" seçeneğini kullanarak e-posta adresinize sıfırlama bağlantısı gönderebilirsiniz.',
    },
  ];

  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
                  fillColor: Colors.grey[100],
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
                    'Sorun Giderme',
                    Icons.build_outlined,
                    Colors.orange,
                  ),
                  _buildQuickHelpCard(
                    context,
                    'Güvenlik İpuçları',
                    Icons.security,
                    Colors.green,
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

            // İletişim Seçenekleri
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'İletişime Geçin',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            _buildContactOption(
              context,
              'E-posta ile Destek',
              'support@chakra.com',
              Icons.email_outlined,
              () {
                // E-posta gönderme işlemi
              },
            ),
            _buildContactOption(
              context,
              'Canlı Destek',
              '7/24 Destek Hattı',
              Icons.chat_outlined,
              () {
                // Canlı destek başlatma
              },
            ),
            _buildContactOption(
              context,
              'Telefon ile Ara',
              '+90 850 123 45 67',
              Icons.phone_outlined,
              () {
                // Telefon araması başlatma
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
    return Container(
      width: 160,
      margin: EdgeInsets.only(right: 16),
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
      child: ExpansionTile(
        title: Text(
          question,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        children: [
          Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              answer,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactOption(
    BuildContext context,
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