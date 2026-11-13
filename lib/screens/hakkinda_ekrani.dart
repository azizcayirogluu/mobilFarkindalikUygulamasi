import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class HakkindaEkrani extends StatelessWidget {
  const HakkindaEkrani({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final paddingValue = size.width > 600 ? 32.0 : 20.0;
    const Color backgroundSubtle = Color(0xFFF8FAFC);
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      backgroundColor: backgroundSubtle,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "Kahraman Dostum Hakkında",
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
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
        bottom: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(paddingValue, 15, paddingValue, 20),
                    child: _buildHeroSection(),
                  ),
                ),

                _buildSectionHeader("SANA NELER KATACAK? 🚀", paddingValue),
                SliverPadding(
                  padding: EdgeInsets.symmetric(horizontal: paddingValue),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      _buildFeatureCard(
                        icon: Icons.psychology_rounded,
                        title: "Akran Zorbalığını Tanı",
                        description: "Fiziksel, sözel, siber veya ilişkisel zorbalığı fark etmeyi ve kendine güvenle sınır çizmeyi öğren.",
                        badge: "Farkındalık",
                        color: const Color(0xFF6366F1),
                      ).animate().fadeIn(delay: 50.ms).slideY(begin: 0.05),

                      _buildFeatureCard(
                        icon: Icons.shield_rounded,
                        title: "Siber Dünyada Güvende Kal",
                        description: "Kişisel bilgilerini koru, şifre güvenliğini sağla ve internetteki tuzaklara karşı kalkan oluştur.",
                        badge: "Güvenlik",
                        color: const Color(0xFFEC4899),
                      ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.05),

                      _buildFeatureCard(
                        icon: Icons.sentiment_very_satisfied_rounded,
                        title: "Nezaket ve Empati Yay",
                        description: "Kelimelerinin gücünü keşfet. Dijital dünyayı nazik ve destekleyici bir topluluğa dönüştür.",
                        badge: "Nezaket",
                        color: const Color(0xFF10B981),
                      ).animate().fadeIn(delay: 150.ms).slideY(begin: 0.05),
                    ]),
                  ),
                ),

                _buildSectionHeader("UYGULAMADA SENİ NELER BEKLİYOR? 🧩", paddingValue),
                SliverPadding(
                  padding: EdgeInsets.symmetric(horizontal: paddingValue),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      _buildModuleGrid(),
                    ]),
                  ),
                ),

                _buildSectionHeader("SİBER KAHRAMANIN 3 ALTIN KURALI 🌟", paddingValue),
                SliverPadding(
                  padding: EdgeInsets.symmetric(horizontal: paddingValue),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      _buildRuleItem("1", "Sırlarını Sakla 🔒", "Gerçek adını, ev adresini, okulunu ve şifrelerini kimseyle paylaşma."),
                      _buildRuleItem("2", "Tartışma, Engelle 🛑", "Sana kötü davranan kişilerle kavga etme; ekran görüntüsü al ve engelle."),
                      _buildRuleItem("3", "Sessiz Kalma, Paylaş 🗣️", "Korkma veya utanma! Güvendiğin bir ebeveyn, öğretmen veya yetişkinle konuş."),
                    ]),
                  ),
                ),

                _buildSectionHeader("GİZLİLİK VE GÜVENLİK SÖZÜMÜZ 🛡️", paddingValue),
                SliverPadding(
                  padding: EdgeInsets.symmetric(horizontal: paddingValue),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      _buildTrustBanner(),
                      const SizedBox(height: 30),
                      _buildFooter(),
                      SizedBox(height: bottomInset + 40),
                    ]),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeroSection() {
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
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF3B82F6).withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.shield_rounded,
              size: 44,
              color: Color(0xFF3B82F6),
            ),
          ).animate(onPlay: (c) => c.repeat(reverse: true)).moveY(begin: -5, end: 5, duration: 2.seconds),
          const SizedBox(height: 18),
          const Text(
            "SENİN CESARETİN, SENİN DÜNYAN!",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: Color(0xFF1E293B),
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            "Kahraman Dostum; çocukların ve gençlerin her türlü zorbalığa karşı bilinçlenmesi, haklarını öğrenmesi ve güvenli bir dijital iz bırakması için tasarlanmış bağımsız eğitici farkındalık platformudur.",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13.5,
              height: 1.55,
              color: Color(0xFF475569),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, double padding) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: EdgeInsets.fromLTRB(padding, 20, padding, 12),
        child: Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 13,
            color: Color(0xFF64748B),
            letterSpacing: 1.1,
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureCard({
    required IconData icon,
    required String title,
    required String description,
    required String badge,
    required Color color,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
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
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 24, color: color),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        badge,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: color,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: Color(0xFF475569),
                    fontWeight: FontWeight.w500,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModuleGrid() {
    final modules = [
      (
        icon: Icons.psychology_rounded,
        title: "Senaryolar",
        subtitle: "Karar Ver & Öğren",
        color: const Color(0xFF6366F1),
      ),
      (
        icon: Icons.auto_awesome_rounded,
        title: "Siber Dost",
        subtitle: "AI Asistan Danışman",
        color: const Color(0xFFEC4899),
      ),
      (
        icon: Icons.search_rounded,
        title: "Siber Dedektif",
        subtitle: "Güvenlik Oyunu",
        color: const Color(0xFFF59E0B),
      ),
      (
        icon: Icons.menu_book_rounded,
        title: "Hikayeler",
        subtitle: "Oku & Keşfet",
        color: const Color(0xFF10B981),
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.4,
      ),
      itemCount: modules.length,
      itemBuilder: (context, index) {
        final m = modules[index];
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
            boxShadow: const [
              BoxShadow(
                color: Color(0x04000000),
                blurRadius: 8,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: m.color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(m.icon, color: m.color, size: 22),
              ),
              const SizedBox(height: 10),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  m.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                    color: Color(0xFF1E293B),
                  ),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                m.subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 11,
                  color: Color(0xFF64748B),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRuleItem(String number, String title, String detail) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: Color(0xFFEEF2FF),
              shape: BoxShape.circle,
            ),
            child: Text(
              number,
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                color: Color(0xFF4F46E5),
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  detail,
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: Color(0xFF475569),
                    height: 1.4,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrustBanner() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFEEF2FF),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFC7D2FE)),
      ),
      child: const Row(
        children: [
          Icon(Icons.verified_user_rounded, color: Color(0xFF4F46E5), size: 32),
          SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Çocuk ve Aile Dostu Mimarisi 🔒",
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 13.5,
                    color: Color(0xFF1E1B4B),
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  "Gerçek e-posta veya hassas kişisel veriler istenmez. Sohbet verileri veritabanında saklanmaz. 6-12 yaş grubu ebeveyn onayına tabidir.",
                  style: TextStyle(
                    fontSize: 11.5,
                    color: Color(0xFF3730A3),
                    height: 1.4,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Column(
      children: [
        const Text("🤝", style: TextStyle(fontSize: 40))
            .animate(onPlay: (c) => c.repeat(reverse: true))
            .scale(begin: const Offset(1, 1), end: const Offset(1.1, 1.1), duration: 1.seconds),
        const SizedBox(height: 12),
        const Text(
          "Gelecek, Senin Cesaretinle Güzel!",
          textAlign: TextAlign.center,
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 16,
            color: Color(0xFF3B82F6),
            letterSpacing: -0.2,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          "Kahraman Dostum © 2026 • Güvenli ve Bilinçli Gelecek",
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 11,
            color: Color(0xFF94A3B8),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
