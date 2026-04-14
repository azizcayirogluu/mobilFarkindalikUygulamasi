import 'package:flutter/material.dart';
import 'package:zorbalik_uygulamasi/app_theme.dart';
import 'package:flutter_animate/flutter_animate.dart';

class HakkindaEkrani extends StatelessWidget {
  const HakkindaEkrani({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.zemin,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildSliverAppBar(context),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  const SizedBox(height: 30),
                  _buildHeroSection(), // Hedefimiz Kısmı
                  const SizedBox(height: 40),
                  _buildSectionHeader("KAHRAMAN GÜÇLERİN"),
                  const SizedBox(height: 20),
                  _buildValueCard(
                    Icons.auto_awesome_rounded,
                    "Cesaret Elçisi",
                    "Sessiz kalmak değil, durumu paylaşmak gerçek bir kahramanlıktır. Yardım istemekten korkma!",
                    const Color(0xFF6C63FF),
                  ),
                  _buildValueCard(
                    Icons.security_rounded,
                    "Güvenlik Kalkanı",
                    "Zorbalığa karşı en büyük silahın bilgindir. İnternette ve hayatta güvenliğin bize emanet!",
                    const Color(0xFFFF6584),
                  ),
                  _buildValueCard(
                    Icons.sentiment_very_satisfied_rounded,
                    "Nezaket Maskotu",
                    "Kelimelerin sandığından çok daha güçlü! İnterneti nezaketinle aydınlatmaya hazır mısın?",
                    const Color(0xFF4CAF50),
                  ),
                  _buildFooter(),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 340,
      pinned: true,
      stretch: true,
      backgroundColor: AppColors.anaMavi,
      elevation: 0,
      leading: Padding(
        padding: const EdgeInsets.all(8.0),
        child: CircleAvatar(
          backgroundColor: Colors.white24,
          child: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
            onPressed: () => Navigator.pop(context),
          ),
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Arka Plan Gradiyenti
            Container(decoration: const BoxDecoration(gradient: AppColors.anaGradient)),

            // Hareketli Baloncuklar
            _buildAnimatedBubble(top: 40, left: -20, size: 120, color: Colors.white10),
            _buildAnimatedBubble(top: 180, right: -30, size: 160, color: Colors.blueAccent.withOpacity(0.1)),
            _buildAnimatedBubble(bottom: 50, left: 40, size: 80, color: Colors.white12),

            SafeArea(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo Alanı
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 30, offset: const Offset(0, 15)),
                      ],
                    ),
                    child: const Icon(Icons.shield_rounded, size: 65, color: AppColors.anaMavi),
                  ).animate(onPlay: (c) => c.repeat(reverse: true)).moveY(begin: -8, end: 8, duration: 2.seconds, curve: Curves.easeInOut),

                  const SizedBox(height: 20),
                  const Text(
                    "SİBER KAHRAMAN",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 32,
                      letterSpacing: 2,
                    ),
                  ).animate().fadeIn(delay: 200.ms).scale(begin: const Offset(0.9, 0.9)),

                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(20)),
                    child: const Text(
                      "Güçlü, Bilinçli ve Güvende!",
                      style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                  ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.5),
                ],
              ),
            ),

            // Yumuşak Geçiş (Bottom Curve)
            Positioned(
              bottom: -1,
              left: 0,
              right: 0,
              child: Container(
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.zemin,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(35),
        boxShadow: [
          BoxShadow(color: AppColors.anaMavi.withOpacity(0.08), blurRadius: 30, offset: const Offset(0, 15)),
        ],
      ),
      child: Column(
        children: [
          const Text("✨", style: TextStyle(fontSize: 40))
              .animate(onPlay: (c) => c.repeat())
              .shimmer(duration: 2.seconds),
          const SizedBox(height: 10),
          const Text(
            "SANA NELER KATACAĞIZ?",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.anaMavi),
          ),
          const SizedBox(height: 15),
          Text(
            "Zorbalıkla karşılaştığında ne yapacağını bilmen, internetin tehlikeli sularında güvenle yüzmen ve her zaman nazik bir dil kullanman için yanındayız. Bu yolculuğun sonunda gerçek bir siber kahraman olacaksın!",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 15, height: 1.6, color: Colors.grey.shade700, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: 0.2);
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 10),
      child: Row(
        children: [
          const Text("🔥", style: TextStyle(fontSize: 24)),
          const SizedBox(width: 10),
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.yaziRengi, letterSpacing: 1),
          ),
        ],
      ),
    );
  }

  Widget _buildValueCard(IconData icon, String title, String desc, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: color.withOpacity(0.1), width: 2),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(icon, color: color, size: 30),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: AppColors.yaziRengi)),
                const SizedBox(height: 4),
                Text(desc, style: TextStyle(fontSize: 13, color: Colors.grey.shade600, height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn().slideX(begin: 0.1);
  }

  Widget _buildFooter() {
    return Column(
      children: [
        const Text("🤝", style: TextStyle(fontSize: 50)).animate(onPlay: (c) => c.repeat(reverse: true)).scale(duration: 1.5.seconds),
        const SizedBox(height: 15),
        const Text(
          "Gelecek, Senin Cesaretinle Güzel!",
          textAlign: TextAlign.center,
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.anaMavi),
        ),
        const SizedBox(height: 10),
      ],
    );
  }

  Widget _buildAnimatedBubble({double? top, double? bottom, double? left, double? right, required double size, required Color color}) {
    return Positioned(
      top: top, bottom: bottom, left: left, right: right,
      child: Container(
        width: size, height: size,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
    ).animate(onPlay: (c) => c.repeat(reverse: true)).scale(begin: const Offset(1, 1), end: const Offset(1.3, 1.3), duration: 4.seconds).moveY(begin: 0, end: 30, duration: 5.seconds);
  }
}