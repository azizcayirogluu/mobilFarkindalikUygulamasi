import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class GizlilikPolitikasiEkrani extends StatelessWidget {
  const GizlilikPolitikasiEkrani({super.key});

  static const _contactEmail = 'siberkahramanapp@gmail.com';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F9FC),
      appBar: AppBar(
        title: const Text('Gizlilik Politikası'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const _IntroCard(),
          const SizedBox(height: 16),
          const _PolicySection(
            title: 'İşlenen veriler',
            icon: Icons.inventory_2_outlined,
            body: '• Takma ad, Firebase kullanıcı kimliği ve giriş için oluşturulan e-posta takma adı\n'
                '• Seçilen yaş grubu\n'
                '• İlerleme, puan, rozet, görev ve eğitim yanıtları\n'
                '• Yapay zekâ asistanı sohbetleri ile sınırlı sohbet geçmişi\n'
                '• Bildirim izni verilirse cihaz bildirim tokenı\n'
                '• Olay bildirimi gönderilirse başlık, ayrıntı ve kullanıcının yazdığı konum metni\n\n'
                'Lütfen takma ada, sohbete veya rapora gerçek ad, adres, telefon ya da başka kişisel bilgi yazma.',
          ),
          const _PolicySection(
            title: 'Hizmet sağlayıcılar ve kullanım',
            icon: Icons.cloud_outlined,
            body: 'Hesap, profil, ilerleme, sohbet ve rapor verileri Firebase hizmetlerinde işlenir. Sohbet mesajları, yanıt oluşturmak için Firebase Cloud Functions üzerinden Google Gemini hizmetine gönderilir. Uygulama Google Mobile Ads SDK’sı ile ödüllü reklam özelliği de içerir.\n\n'
                'Veriler; yaşa uygun içeriği göstermek, ilerlemeyi kaydetmek, sohbet yanıtı üretmek, olay raporlarını yetkili yöneticilerin incelemesine sunmak ve bildirim/ödül özelliklerini çalıştırmak için kullanılır. Sohbet verileri reklam kişiselleştirmesi amacıyla kullanılmaz.',
          ),
          const _PolicySection(
            title: 'Çocuk gizliliği',
            icon: Icons.family_restroom_outlined,
            body: 'Uygulama 6–18 yaş grubuna yöneliktir ve kayıt sırasında yaş grubu seçilir. Kayıt ekranındaki gizlilik politikası kutucuğu kabul edilmeden hesap oluşturulamaz.\n\n'
                'Bu sürümde doğrulanmış ebeveyn onayı özelliği bulunmaz. 18 yaşından küçük kullanıcıların veli veya vasisiyle birlikte bu metni incelemesi önerilir.',
          ),
          const _PolicySection(
            title: 'Verilerin korunması',
            icon: Icons.lock_outline,
            body: 'Gemini anahtarı uygulama içinde değil, sunucu tarafındaki gizli yapılandırmada tutulur. Firestore kuralları kullanıcıyı kendi verisiyle; yöneticileri yetkili yönetim işlemleriyle sınırlar.\n\n'
                'Hiçbir çevrimiçi sistem mutlak güvenlik garantisi vermez. Güvenlik olayı şüphesinde bizimle iletişime geçebilirsin.',
          ),
          const _PolicySection(
            title: 'Yapay zekâ asistanı',
            icon: Icons.smart_toy_outlined,
            body: 'Yapay zekâ yanıtı otomatik olabilir; acil yardım veya profesyonel destek yerine geçmez. Tehlike anında güvenilir bir yetişkine ve acil yardım hatlarına başvur.\n\n'
                'Sohbet verileri reklam kişiselleştirmesi için kullanılmaz. Firebase ve Gemini hizmetlerinin kendi veri işleme koşulları ayrıca geçerlidir.',
          ),
          const _PolicySection(
            title: 'Veri silme',
            icon: Icons.delete_outline,
            body: 'Profil > Hesabı Kalıcı Olarak Sil yolundan hesap silme isteği başlatılabilir. Bu işlem Firebase Auth hesabını, profilini, ilerleme ve sohbet verilerini, uygulamadaki bildirim tokenını ve gönderdiğin olay raporlarını siler.\n\n'
                'Uygulamayı kaldırmış kişiler, herkese açık Hesap Silme Talebi sayfasından e-posta ile talep gönderebilir. Teknik günlükler ve yedekler, hizmet sağlayıcısının sınırlı saklama süresi boyunca kalabilir.',
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Sorular ve silme talepleri',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text('PIN, gerçek ad, adres veya sohbet içeriği göndermeden bizimle iletişime geçebilirsin.'),
                  const SizedBox(height: 10),
                  TextButton.icon(
                    onPressed: _emailPrivacyTeam,
                    icon: const Icon(Icons.email_outlined),
                    label: const Text(_contactEmail),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Center(
            child: Text(
              'Son güncelleme: 9 Ağustos 2026',
              style: TextStyle(color: Colors.blueGrey),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _emailPrivacyTeam() async {
    final uri = Uri(
      scheme: 'mailto',
      path: _contactEmail,
      query: 'subject=Kahraman Dostum Gizlilik Sorusu',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }
}

class _IntroCard extends StatelessWidget {
  const _IntroCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFFEAF4FF),
      child: const Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.privacy_tip_outlined, color: Color(0xFF1565C0), size: 32),
            SizedBox(height: 10),
            Text('Şeffaflık ve Gizlilik', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            SizedBox(height: 6),
            Text('Bu metin, uygulamanın işlediği verileri ve verilerini nasıl sileceğini açıklar.'),
          ],
        ),
      ),
    );
  }
}

class _PolicySection extends StatelessWidget {
  final String title;
  final IconData icon;
  final String body;

  const _PolicySection({
    required this.title,
    required this.icon,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        leading: Icon(icon, color: const Color(0xFF1565C0)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        childrenPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        children: [
          Text(body, style: const TextStyle(height: 1.5)),
        ],
      ),
    );
  }
}
