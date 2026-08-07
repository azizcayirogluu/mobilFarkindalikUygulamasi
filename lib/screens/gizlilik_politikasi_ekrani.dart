import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:zorbalik_uygulamasi/app_theme.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:math' as math;

class GizlilikPolitikasiEkrani extends StatelessWidget {
  const GizlilikPolitikasiEkrani({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    const Color backgroundSubtle = Color(0xFFF0F9FF); // Akıcı bulut mavisi zemin

    return Scaffold(
      backgroundColor: backgroundSubtle,
      appBar: AppBar(
        title: const Text(
          "GÜVENLİK MERKEZİ",
          style: TextStyle(
            color: Color(0xFF0F172A),
            fontWeight: FontWeight.w900,
            fontSize: 18,
            letterSpacing: -0.5,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 3)),
              ],
            ),
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: Color(0xFF334155)),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          // Arka plan sevimli dekoratif halkalar
          Positioned(
            top: -20,
            right: -40,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(shape: BoxShape.circle, color: const Color(0xFF3B82F6).withOpacity(0.04)),
            ),
          ),
          Positioned(
            bottom: -30,
            left: -30,
            child: Transform.rotate(
              angle: math.pi / 4,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(30), color: Colors.lightGreenAccent.withOpacity(0.03)),
              ),
            ),
          ),

          SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(24, 10, 24, 30),
            child: Column(
              children: [
                // Üst Kısım: Güven Veren Kahramanlık Rozet Alanı
                _buildHeaderArea(),
                const SizedBox(height: 25),

                // Akordeon Tasarımlı Gizlilik Maddeleri
                _buildAccordionSection(
                  title: "📋 Genel Bilgi",
                  content: "Siber Kahraman, çocuk ve ergenlere yönelik zorbalık farkındalığı oluşturmak amacıyla geliştirilmiş eğitici bir mobil uygulamadır. Bu gizlilik politikası, uygulamamızın kullanıcılardan hangi verileri topladığını, bu verilerin nasıl kullanıldığını ve korunduğunu açıklamaktadır.",
                  accentColor: const Color(0xFF3B82F6),
                  delay: 100.ms,
                ),

                _buildAccordionSection(
                  title: "👤 Toplanan Veriler",
                  content: "• Kullanıcı Adı (takma ad — gerçek isim değil)\n"
                      "• Yaş grubu bilgisi (6-12 veya 13-18)\n"
                      "• Uygulama içi ilerleme verileri (puan, rozet, tamamlanan görevler)\n"
                      "• Yapay zeka asistanı ile yapılan sohbet geçmişi\n"
                      "• Eğitim modüllerindeki cevaplar ve hatalar\n"
                      "• Cihaz bildirim token'ı (push bildirimler için)\n\n"
                      "🚨 Gerçek isim, e-posta adresi, telefon numarası veya konum bilgisi KESİNLİKLE TOPLANMAZ.",
                  accentColor: const Color(0xFF6366F1),
                  delay: 200.ms,
                ),

                _buildAccordionSection(
                  title: "🔒 Verilerin Korunması",
                  content: "• Tüm veriler Google Firebase altyapısında şifreli olarak saklanır.\n"
                      "• API anahtarları Google Cloud Secret Manager ile güvenli ortamda tutulur.\n"
                      "• Kullanıcı verileri sadece hesap sahibi ve yetkilendirilmiş yöneticiler tarafından erişilebilir.\n"
                      "• Firestore güvenlik kuralları ile yetkisiz erişim engellenir.",
                  accentColor: const Color(0xFF10B981),
                  delay: 300.ms,
                ),

                _buildAccordionSection(
                  title: "🤖 Yapay Zeka Kullanımı",
                  content: "• Uygulama, Google Gemini ve Groq (Llama) yapay zeka modellerini eğitim ve destek amaçlı kullanır.\n"
                      "• Siber zorbalığı önlemek amacıyla, mesajlar yapay zeka destekli güvenlik analizi ile taranabilir.\n"
                      "• Risk tespiti durumunda, sistem sadece gerekli güvenlik uyarılarını oluşturur.\n"
                      "• AI çıktıları sunucu tarafında filtrelenerek çocuklara uygun olmayan içerikler engellenir.\n"
                      "• AI verileri asla reklam amaçlı kullanılmaz ve üçüncü şahıslarla paylaşılmaz.",
                  accentColor: const Color(0xFF8E2DE2),
                  delay: 400.ms,
                ),

                _buildAccordionSection(
                  title: "👶 Çocuk Gizliliği (KVKK)",
                  content: "• Uygulama, 6-18 yaş arası kullanıcılar için tasarlanmıştır.\n"
                      "• Çocukların kişisel bilgileri toplanmaz; sadece takma ad kullanılır.\n"
                      "• Sohbet geçmişi, çocuğun güvenliğini sağlamak amacıyla yetkili eğitimciler tarafından incelenebilir.\n"
                      "• Uygulama, KVKK (Kişisel Verilerin Korunması Kanunu) ve çocuk gizliliği ilkelerine tamamen uygun olarak geliştirilmiştir.",
                  accentColor: const Color(0xFFF59E0B),
                  delay: 500.ms,
                ),

                _buildAccordionSection(
                  title: "📊 Verilerin Kullanım Amaçları",
                  content: "• Kullanıcının eğitim ilerlemesini takip etmek\n"
                      "• Kişiselleştirilmiş öğrenme deneyimi sunmak\n"
                      "• Olası zorbalık veya risk durumlarını tespit etmek\n"
                      "• Uygulama performansını iyileştirmek\n"
                      "• İstatistiksel raporlama (anonim ve toplu veriler)",
                  accentColor: const Color(0xFF06B6D4),
                  delay: 600.ms,
                ),

                _buildAccordionSection(
                  title: "🗑️ Veri Silme Hakkı",
                  content: "Kullanıcılar, profil ayarlarından hesaplarını ve tüm verilerini kalıcı olarak silebilir. Hesap silindiğinde tüm kişisel veriler, ilerleme kayıtları ve sohbet geçmişi sistemden tamamen kaldırılır.",
                  accentColor: const Color(0xFFEF4444),
                  delay: 700.ms,
                ),

                _buildAccordionSection(
                  title: "🔄 Politika Güncellemeleri",
                  content: "Bu gizlilik politikası zaman zaman güncellenebilir. Önemli değişiklikler uygulama içi sevimli bildirimlerle kahramanlarımıza duyurulacaktır.",
                  accentColor: const Color(0xFF64748B),
                  delay: 800.ms,
                ),

                const SizedBox(height: 10),
                _buildContactCard(),
                const SizedBox(height: 20),

                Text(
                  "Son güncelleme: Mayıs 2026",
                  style: TextStyle(
                    color: Colors.blueGrey.shade300,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    fontStyle: FontStyle.italic,
                  ),
                ).animate().fadeIn(delay: 950.ms),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderArea() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(35),
        boxShadow: [
          BoxShadow(color: const Color(0xFF3B82F6).withOpacity(0.06), blurRadius: 20, offset: const Offset(0, 10)),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 65,
            height: 65,
            decoration: BoxDecoration(
              color: const Color(0xFF3B82F6).withOpacity(0.12),
              borderRadius: BorderRadius.circular(22),
            ),
            child: const Icon(Icons.verified_user_rounded, size: 34, color: Color(0xFF3B82F6)),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Güvenliğin Bize Emanet! 🛡️",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF1E293B), letterSpacing: -0.3),
                ),
                SizedBox(height: 4),
                Text(
                  "Kişisel verilerini toplamıyor, gizliliğini en yüksek standartta koruyoruz.",
                  style: TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w600, height: 1.3),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.1, curve: Curves.easeOut);
  }

  // Yenilenen Genişletilebilir Akordeon Kart Yapısı
  Widget _buildAccordionSection({
    required String title,
    required String content,
    required Color accentColor,
    required Duration delay,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: accentColor.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Theme(
        data: ThemeData().copyWith(dividerColor: Colors.transparent), // Alt çizgileri kaldırır
        child: ExpansionTile(
          iconColor: accentColor,
          collapsedIconColor: Colors.blueGrey.shade300,
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.shield_rounded,
              size: 18,
              color: accentColor,
            ),
          ),
          title: Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w900,
              color: Color(0xFF1E293B),
              letterSpacing: -0.2,
            ),
          ),
          childrenPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.blueGrey.shade50),
              ),
              child: Text(
                content,
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF475569),
                  fontWeight: FontWeight.w600,
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: delay, duration: 450.ms).slideY(begin: 0.08, curve: Curves.easeOutBack);
  }

  Widget _buildContactCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 20, offset: const Offset(0, 10)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.mail_outline_rounded, color: Colors.amber, size: 22),
              SizedBox(width: 8),
              Text(
                "İletişim & Sorular",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            "Gizlilik politikamızla ilgili aklına takılan her şeyi bize sormaktan çekinme Kahraman!",
            style: TextStyle(fontSize: 13, color: Color(0xFF94A3B8), fontWeight: FontWeight.w500, height: 1.4),
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: _launchEmail,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withOpacity(0.15)),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "siberkahramanapp@gmail.com",
                    style: TextStyle(
                      color: Colors.amber,
                      fontWeight: FontWeight.w900,
                      fontSize: 13,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                  SizedBox(width: 8),
                  Icon(Icons.open_in_new_rounded, color: Colors.amber, size: 14),
                ],
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(color: Colors.white10),
          ),
          const Text(
            "🚀 Proje: TÜBİTAK Siber Zorbalık Farkındalık Projesi",
            style: TextStyle(fontSize: 12, color: Colors.white70, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 900.ms, duration: 400.ms);
  }

  Future<void> _launchEmail() async {
    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: 'siberkahramanapp@gmail.com',
      query: 'subject=Gizlilik Politikası Hakkında Soru',
    );
    if (await canLaunchUrl(emailLaunchUri)) {
      await launchUrl(emailLaunchUri);
    }
  }
}