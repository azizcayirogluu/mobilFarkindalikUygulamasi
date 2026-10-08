import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class HakkindaEkrani extends StatelessWidget {
  const HakkindaEkrani({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final paddingValue = size.width > 600 ? 32.0 : 20.0;
    const Color backgroundSubtle = Color(0xFFF8FAFC);

    return Scaffold(
      backgroundColor: backgroundSubtle,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "Uygulama Hakkında",
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
                padding: EdgeInsets.fromLTRB(paddingValue, 15, paddingValue, 20),
                child: _buildHeroSection(),
              ),
            ),
            _buildSectionHeader("KAHRAMAN GÜÇLERİN 🛡️", paddingValue),
            SliverPadding(
              padding: EdgeInsets.symmetric(horizontal: paddingValue),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _buildModernInfoCard(
                    icon: Icons.auto_awesome_rounded,
                    title: "Cesaret Elçisi",
                    content: "Sessiz kalmak değil, durumu paylaşmak gerçek bir kahramanlıktır. Yardım istemekten korkma!",
                    color: const Color(0xFF6366F1),
                  ).animate().fadeIn(delay: 50.ms).slideY(begin: 0.05),
                  
                  _buildModernInfoCard(
                    icon: Icons.security_rounded,
                    title: "Güvenlik Kalkanı",
                    content: "Zorbalığa karşı en büyük silahın bilgindir. İnternette ve hayatta güvenliğin bize emanet!",
                    color: const Color(0xFFEC4899),
                  ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.05),

                  _buildModernInfoCard(
                    icon: Icons.sentiment_very_satisfied_rounded,
                    title: "Nezaket Maskotu",
                    content: "Kelimelerin sandığından çok daha güçlü! İnterneti nezaketinle aydınlatmaya hazır mısın?",
                    color: const Color(0xFF10B981),
                  ).animate().fadeIn(delay: 150.ms).slideY(begin: 0.05),

                  const SizedBox(height: 30),
                  _buildFooter(),
                  const SizedBox(height: 40),
                ]),
              ),
            ),
          ],
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
            decoration: const BoxDecoration(
              color: Color(0x1F3B82F6),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.shield_rounded,
              size: 40,
              color: Color(0xFF3B82F6),
            ),
          ).animate(onPlay: (c) => c.repeat(reverse: true)).moveY(begin: -5, end: 5, duration: 2.seconds),
          const SizedBox(height: 20),
          const Text(
            "SANA NELER KATACAĞIZ?",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: Color(0xFF1E293B),
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            "Zorbalıkla karşılaştığında ne yapacağını bilmen, internetin güvenli sularında yüzmen ve her zaman nazik bir dil kullanman için yanındayız. Bu yolculuğun sonunda gerçek bir siber kahraman olacaksın!",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              height: 1.6,
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
        padding: EdgeInsets.fromLTRB(padding, 10, padding, 15),
        child: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 14,
            color: Color(0xFF64748B),
            letterSpacing: 1,
          ),
        ),
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
            child: Icon(icon, size: 24, color: color),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
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
      ],
    );
  }
}
