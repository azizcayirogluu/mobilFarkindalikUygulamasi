import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../app_theme.dart';

class GizlilikPolitikasiEkrani extends StatelessWidget {
  const GizlilikPolitikasiEkrani({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final paddingValue = size.width * 0.05;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC), // Ultra temiz ve ferah zemin
      appBar: AppBar(
        toolbarHeight: 90,
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: const Padding(
          padding: EdgeInsets.only(top: 25),
          child: Text(
            "Güvenlik & Gizlilik",
            style: TextStyle(
              color: Color(0xFF1E293B),
              fontWeight: FontWeight.w900,
              fontSize: 22,
              letterSpacing: -0.5,
            ),
          ),
        ),
        leading: Padding(
          padding: const EdgeInsets.only(left: 16, top: 25),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.indigo.withOpacity(0.06),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: IconButton(
              icon: const Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 18,
                color: Color(0xFF475569),
              ),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // Üst Bilgi Kartı
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(paddingValue, 15, paddingValue, 20),
                child: _buildHeroBanner(),
              ),
            ),

            // Bilgi Maddeleri (Artık akordeon değil, direkt okunabilir ferah kartlar)
            SliverPadding(
              padding: EdgeInsets.symmetric(horizontal: paddingValue),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _buildModernInfoCard(
                    icon: Icons.face_rounded,
                    title: "Hangi Bilgileri Kullanıyoruz? 🎭",
                    content: "Sadece oyundaki takma adını, yaş grubunu ve kazandığın harika rozetleri biliyoruz. Gerçek adın, e-posta adresin veya ev adresin gibi gizli bilgilerini KESİNLİKLE istemiyoruz!",
                    color: AppColors.anaMavi,
                  ).animate().fadeIn(delay: 50.ms).slideY(begin: 0.05),
                  
                  _buildModernInfoCard(
                    icon: Icons.shield_rounded,
                    title: "Güvenli Süper Kalkan 🔒",
                    content: "Bütün verilerin dünyanın en güvenli dijital kasalarında saklanır. Bilgilerine senden ve sistem koruyucularından başka hiç kimse asla erişemez.",
                    color: AppColors.basariYesili,
                  ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.05),

                  _buildModernInfoCard(
                    icon: Icons.smart_toy_rounded,
                    title: "Dost Canlısı Yapay Zeka 🤖",
                    content: "Siber Asistan arkadaşımız, sana en doğru tavsiyeleri vermek için çalışır. Sohbetleriniz tamamen gizli kalır ve asla reklamcılarla paylaşılmaz.",
                    color: AppColors.yumusakMor,
                  ).animate().fadeIn(delay: 150.ms).slideY(begin: 0.05),

                  _buildModernInfoCard(
                    icon: Icons.child_care_rounded,
                    title: "Çocuk Dostu Kurallar ✨",
                    content: "Uygulamamız KVKK ve çocuk gizliliği standartlarına %100 uygundur. Tek amacımız senin dijital dünyada güvenle eğlenmeni sağlamaktır.",
                    color: AppColors.uyariTuruncusu,
                  ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.05),

                  _buildModernInfoCard(
                    icon: Icons.delete_forever_rounded,
                    title: "Verilerini İstediğin An Sil 🗑️",
                    content: "Profil ayarlarından hesabını tek bir tıkla silebilirsin. Sildiğin an tüm puanların ve rozetlerin sistemimizden tamamen uçup gider.",
                    color: const Color(0xFFEF4444),
                  ).animate().fadeIn(delay: 250.ms).slideY(begin: 0.05),

                  const SizedBox(height: 10),
                  
                  // Sadeleştirilmiş, Şık İletişim Alanı
                  _buildMinimalContactCard(),
                  
                  const SizedBox(height: 20),
                  
                  // Alt Kurumsal Bilgi
                  _buildFooterInfo(),
                  
                  const SizedBox(height: 40),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroBanner() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.indigo.withOpacity(0.03),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(color: const Color(0xFFF1F5F9), width: 1.5),
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: AppColors.anaMavi.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.verified_user_rounded,
              size: 32,
              color: AppColors.anaMavi,
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
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF1E293B),
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  "Kişisel verilerini toplamıyor, seni dijital dünyada tam güçle koruyoruz.",
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w500,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernInfoCard({
    required IconData icon,
    required String title,
    required String content,
    required Color color,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF1F5F9), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.01),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 22, color: color),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  content,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF475569),
                    fontWeight: FontWeight.w500,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMinimalContactCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade200, width: 1.5),
      ),
      child: Column(
        children: [
          const Text(
            "Bir sorunuz mu var? 📩",
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w900,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            "Aklınıza takılan her şey için bizimle iletişime geçebilirsiniz.",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 14),
          InkWell(
            onTap: _launchEmail,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.mail_outline_rounded, color: Color(0xFF475569), size: 18),
                  const SizedBox(width: 8),
                  Text(
                    "siberkahramanapp@gmail.com",
                    style: TextStyle(
                      color: Color(0xFF1E293B),
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 300.ms);
  }

  Widget _buildFooterInfo() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.verified, size: 16, color: Colors.blueGrey.shade300),
            const SizedBox(width: 6),
            const Text(
              "TÜBİTAK Siber Zorbalık Farkındalık Projesi",
              style: TextStyle(
                fontSize: 11,
                color: Color(0xFF94A3B8),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          "Son Güncelleme: Mayıs 2026",
          style: TextStyle(
            fontSize: 10,
            color: Colors.blueGrey.shade200,
            fontWeight: FontWeight.bold,
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
    try {
      await launchUrl(emailLaunchUri);
    } catch (_) {}
  }
}
