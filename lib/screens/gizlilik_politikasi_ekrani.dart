import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../app_theme.dart';

class GizlilikPolitikasiEkrani extends StatelessWidget {
  const GizlilikPolitikasiEkrani({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final paddingValue = size.width > 600 ? 32.0 : 20.0;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "Güvenlik & Gizlilik",
          style: TextStyle(
            color: Color(0xFF1E293B),
            fontWeight: FontWeight.w900,
            fontSize: 20,
            letterSpacing: -0.5,
          ),
        ),
        leading: Padding(
          padding: const EdgeInsets.only(left: 12),
          child: Center(
            child: Container(
              width: 38,
              height: 38,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Color(0x0F4F46E5),
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: IconButton(
                padding: EdgeInsets.zero,
                icon: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: 16,
                  color: Color(0xFF475569),
                ),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  paddingValue,
                  15,
                  paddingValue,
                  20,
                ),
                child: _buildHeroBanner(),
              ),
            ),

            SliverPadding(
              padding: EdgeInsets.symmetric(horizontal: paddingValue),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _buildModernInfoCard(
                    icon: Icons.face_rounded,
                    title: "Hangi Bilgileri Kullanıyoruz? 🎭",
                    content:
                        "Hesap açarken kullanıcı adını, yaş grubunu (6-12 veya 13-18) ve giriş için 6 rakamlı PIN'ini girersin. Gerçek adını, gerçek e-posta adresini, telefonunu veya ev adresini istemeyiz. Firebase giriş hesabı için kullanıcı adından bir tanımlayıcı oluşturulur; bu gerçek bir e-posta adresi değildir. Seçtiğin avatar, ilerlemen ve rozetlerin de hesabında saklanır. DiceBear avatarları internetten yüklenir; genel seed kullanılır, kullanıcı adın avatar isteğine eklenmez.",
                    color: AppColors.anaMavi,
                  ).animate().fadeIn(delay: 50.ms).slideY(begin: 0.05),

                  _buildModernInfoCard(
                    icon: Icons.shield_rounded,
                    title: "Güvenli Süper Kalkan 🔒",
                    content:
                        "Hesap ve ilerleme bilgilerin uygulamanın çalışması için Firebase hizmetlerinde saklanır. Uygulama hatalarını incelemek için teknik tanılama kayıtları da işlenebilir. Bu hizmetler bilgileri korumak ve uygulamayı çalıştırmak için kullanılır; ayrıntılar için aşağıdaki e-posta adresinden bize ulaşabilirsin.",
                    color: AppColors.basariYesili,
                  ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.05),

                  _buildModernInfoCard(
                    icon: Icons.smart_toy_rounded,
                    title: "Dost Canlısı Yapay Zeka 🤖",
                    content:
                        "Siber Asistan yanıt vermek için mesajlarını, sohbet geçmişini ve yaş grubunu Google Gemini hizmetine gönderir; profilde ad bilgisi varsa bu da kullanılabilir. Sohbet geçmişin hesabında saklanır ve asistan ekranındaki silme düğmesiyle temizlenebilir. Gerçek adını, okulunu, adresini veya telefonunu mesajlara yazma. İsteğe bağlı ödüllü reklamlar Google AdMob tarafından sunulur.",
                    color: AppColors.yumusakMor,
                  ).animate().fadeIn(delay: 150.ms).slideY(begin: 0.05),

                  _buildModernInfoCard(
                    icon: Icons.child_care_rounded,
                    title: "Çocuk Dostu Kurallar ✨",
                    content:
                        "Kayıt sırasında 6-12 veya 13-18 yaş grubunu seçersin. 6-12 yaş grubundaysan kayıt adımında bir yetişkinden yardım iste. İnternette kendini tanıtabilecek bilgileri paylaşmamaya dikkat et.",
                    color: AppColors.uyariTuruncusu,
                  ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.05),

                  _buildModernInfoCard(
                    icon: Icons.delete_forever_rounded,
                    title: "Verilerini İstediğin An Sil 🗑️",
                    content:
                        "Profil ayarlarından hesap silmeyi seçip onaylayabilirsin. İşlem tamamlandığında uygulama hesabın ve ilişkili ilerleme kayıtların silinir. Google gibi hizmet sağlayıcıların güvenlik kayıtları kendi saklama kurallarına tabi olabilir.",
                    color: const Color(0xFFEF4444),
                  ).animate().fadeIn(delay: 250.ms).slideY(begin: 0.05),

                  const SizedBox(height: 10),

                  _buildMinimalContactCard(),

                  const SizedBox(height: 20),

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
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A4F46E5),
            blurRadius: 16,
            offset: Offset(0, 8),
          ),
        ],
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.anaMavi.withAlpha(25),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.verified_user_rounded,
              size: 30,
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
                    fontSize: 17,
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
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
        boxShadow: const [
          BoxShadow(
            color: Color(0x05000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withAlpha(20),
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
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
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
                  Icon(
                    Icons.mail_outline_rounded,
                    color: Color(0xFF475569),
                    size: 18,
                  ),
                  SizedBox(width: 8),
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
        const SizedBox(height: 8),
        Text(
          "Son Güncelleme: 2026",
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
