import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:math' as math;
import '../app_theme.dart';

class GizlilikPolitikasiEkrani extends StatelessWidget {
  const GizlilikPolitikasiEkrani({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.zemin,
      appBar: AppBar(
        title: const Text(
          "🛡️ Güvenlik & Gizlilik",
          style: TextStyle(
            color: AppColors.yaziRengi,
            fontWeight: FontWeight.w900,
            fontSize: 20,
            letterSpacing: -0.3,
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
                BoxShadow(
                  color: AppColors.anaMavi.withOpacity(0.15),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: IconButton(
              icon: const Icon(
                Icons.arrow_back_rounded,
                size: 22,
                color: AppColors.anaMavi,
              ),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          // Background Decorative Colorful Bubbles
          _buildBackgroundDecorations(),

          SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
            child: Column(
              children: [
                // Hero Header Banner
                _buildHeroHeader(),
                const SizedBox(height: 20),

                // Categorized Interactive Accordion Sections
                _buildAccordionSection(
                  icon: Icons.info_rounded,
                  title: "📋 Genel Bilgi",
                  content:
                  "Siber Kahraman, çocuk ve ergenlere yönelik zorbalık farkındalığı oluşturmak amacıyla geliştirilmiş neşeli ve eğitici bir mobil uygulamadır.\n\n"
                      "Bu gizlilik politikası, uygulamamızın Seni ve verilerini nasıl koruduğunu anlatır!",
                  accentColor: AppColors.anaMavi,
                  delay: 100.ms,
                ),

                _buildAccordionSection(
                  icon: Icons.face_rounded,
                  title: "👤 Toplanan Veriler",
                  content:
                  "• Kullanıcı Adı (Sadece takma ad — gerçek adın değil! 🎭)\n"
                      "• Yaş grubu bilgisi (6-12 veya 13-18)\n"
                      "• Oyundaki Puanların, Rozetlerin ve Görevlerin 🏆\n"
                      "• Yapay Zeka Siber Asistan ile sohbet geçmişin 💬\n"
                      "• Eğitim modüllerindeki tatlı cevapların 🎯\n\n"
                      "🚨 Gerçek adın, e-posta adresin, telefon numaran veya evinin adresi KESİNLİKLE ALINMAZ!",
                  accentColor: AppColors.eglencePembesi,
                  delay: 150.ms,
                ),

                _buildAccordionSection(
                  icon: Icons.lock_rounded,
                  title: "🔒 Güvenli Süper Kalkan",
                  content:
                  "• Tüm verilerin Google Firebase altyapısında süper şifrelerle saklanır.\n"
                      "• Bilgilerine sadece sen ve yetkili sistem koruyucuları erişebilir.\n"
                      "• Verilerin kilitli dijital kasalarda güvendedir!",
                  accentColor: AppColors.basariYesili,
                  delay: 200.ms,
                ),

                _buildAccordionSection(
                  icon: Icons.smart_toy_rounded,
                  title: "🤖 Dost Canlısı Yapay Zeka",
                  content:
                  "• Yapay Zeka arkadaşımız (Gemini / Groq), sana güvenli rehberlik etmek için var.\n"
                      "• Rahatsız edici veya zorbalık içeren durumları engellemek için mesajları tarar.\n"
                      "• Yapay zeka verileri asla reklam amaçlı kullanılmaz ve kimseyle paylaşılmaz!",
                  accentColor: AppColors.yumusakMor,
                  delay: 250.ms,
                ),

                _buildAccordionSection(
                  icon: Icons.child_care_rounded,
                  title: "👶 Çocuk Dostu İlkeler (KVKK)",
                  content:
                  "• Uygulamamız tam 6-18 yaş arası kahramanlar için özel olarak tasarlandı.\n"
                      "• Kişisel verilerin toplanmaz, gizliliğin tam koruma altındadır.\n"
                      "• KVKK ve Çocuk Gizliliği standartlarına %100 uyumludur.",
                  accentColor: AppColors.uyariTuruncusu,
                  delay: 300.ms,
                ),

                _buildAccordionSection(
                  icon: Icons.stars_rounded,
                  title: "📊 Ne İçin Kullanıyoruz?",
                  content:
                  "• Rozetlerini ve seviyeni takip etmek için 🏅\n"
                      "• Sana özel eğlenceli görevler hazırlamak için 🚀\n"
                      "• Siber zorbalığa karşı seni korumak için 🛡️",
                  accentColor: AppColors.accentMavi,
                  delay: 350.ms,
                ),

                _buildAccordionSection(
                  icon: Icons.delete_forever_rounded,
                  title: "🗑️ Hesabı ve Verileri Silme",
                  content:
                  "İstediğin an profil ayarlarından hesabını tek tıkla silebilirsin! Hesap silindiğinde tüm puanların ve kayıtların sistemimizden tamamen uçup gider.",
                  accentColor: const Color(0xFFFF5252),
                  delay: 400.ms,
                ),

                _buildAccordionSection(
                  icon: Icons.autorenew_rounded,
                  title: "🔄 Kural Güncellemeleri",
                  content:
                  "Gizlilik kuralımız güncellenirse seni uygulama içindeki tatlı mini bildirimlerle hemen haberdar edeceğiz!",
                  accentColor: const Color(0xFF78909C),
                  delay: 450.ms,
                ),

                const SizedBox(height: 15),

                // Kid-friendly Contact Card
                _buildPlayfulContactCard(),

                const SizedBox(height: 25),

                // Footer Info
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.softPurple.withOpacity(0.5)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.stars_rounded, size: 16, color: AppColors.oyunSarisi),
                      SizedBox(width: 6),
                      Text(
                        "Son Güncelleme: Mayıs 2026",
                        style: TextStyle(
                          color: AppColors.yaziRengi,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: 500.ms),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Sevimli Kahraman Header Alanı
  Widget _buildHeroHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: AppColors.anaMavi.withOpacity(0.12),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              gradient: AppColors.anaGradient,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: AppColors.accentMavi.withOpacity(0.4),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(
              Icons.verified_user_rounded,
              size: 40,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Güvenliğin Bize Emanet! 🛡️",
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    color: AppColors.yaziRengi,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  "Kişisel verilerini toplamıyor, seni ve gizliliğini tam kalkanla koruyoruz!",
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w600,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: -0.1, curve: Curves.easeOutBack);
  }

  // Renkli, Yuvarlatılmış Bubbly Akordeon Kart Yapısı
  Widget _buildAccordionSection({
    required IconData icon,
    required String title,
    required String content,
    required Color accentColor,
    required Duration delay,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: accentColor.withOpacity(0.2), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: accentColor.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Theme(
        data: ThemeData().copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          iconColor: accentColor,
          collapsedIconColor: AppColors.yaziRengi.withOpacity(0.4),
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 22,
              color: accentColor,
            ),
          ),
          title: Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w900,
              color: AppColors.yaziRengi,
            ),
          ),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: accentColor.withOpacity(0.04),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: accentColor.withOpacity(0.1)),
              ),
              child: Text(
                content,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.yaziRengi,
                  fontWeight: FontWeight.w600,
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: delay, duration: 250.ms).slideY(begin: 0.08, curve: Curves.easeOutBack);
  }

  // Çocuklar İçin Renkli & Neşeli İletişim Kartı
  Widget _buildPlayfulContactCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF8E2DE2), Color(0xFF4A00E0)], // Soft Neşeli Mor Geçiş
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: AppColors.yumusakMor.withOpacity(0.35),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: AppColors.oyunSarisi,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.mail_rounded, color: AppColors.yaziRengi, size: 20),
              ),
              const SizedBox(width: 12),
              const Text(
                "İletişim & Sorular 💌",
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            "Aklına takılan bir şey mi var Kahraman? Bize istediğin zaman e-posta atabilirsin!",
            style: TextStyle(
              fontSize: 13,
              color: Colors.white,
              fontWeight: FontWeight.w600,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          Material(
            color: Colors.transparent,
            child: InkWell(
              child: GestureDetector(
                onTap: _launchEmail,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.mark_email_read_rounded, color: AppColors.yumusakMor, size: 18),
                      SizedBox(width: 8),
                      Text(
                        "siberkahramanapp@gmail.com",
                        style: TextStyle(
                          color: AppColors.yumusakMor,
                          fontWeight: FontWeight.w900,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 14),
            child: Divider(color: Colors.white24, thickness: 1),
          ),
          const Row(
            children: [
              Icon(Icons.military_tech_rounded, color: AppColors.oyunSarisi, size: 18),
              SizedBox(width: 6),
              Expanded(
                child: Text(
                  "TÜBİTAK Siber Zorbalık Farkındalık Projesi",
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(delay: 500.ms, duration: 300.ms);
  }

  // Arka Plan Dekoratif Yumuşak Baloncuklar
  Widget _buildBackgroundDecorations() {
    return Stack(
      children: [
        Positioned(
          top: -20,
          right: -30,
          child: Container(
            width: 160,
            height: 160,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.anaMavi.withOpacity(0.06),
            ),
          ),
        ),
        Positioned(
          top: 250,
          left: -40,
          child: Container(
            width: 130,
            height: 130,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.eglencePembesi.withOpacity(0.05),
            ),
          ),
        ),
        Positioned(
          bottom: 50,
          right: -20,
          child: Transform.rotate(
            angle: math.pi / 6,
            child: Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30),
                color: AppColors.oyunSarisi.withOpacity(0.08),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _launchEmail() async {
    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: 'siberkahramanapp@gmail.com',
      query: 'subject=Siber Kahraman - Gizlilik Hakkında Soru',
    );
    if (await canLaunchUrl(emailLaunchUri)) {
      await launchUrl(emailLaunchUri);
    }
  }
}