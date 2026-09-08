import 'package:flutter/material.dart';
import 'package:zorbalik_uygulamasi/app_theme.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:math' as math;

class HakkindaEkrani extends StatelessWidget {
  const HakkindaEkrani({super.key});

  @override
  Widget build(BuildContext context) {
    const Color backgroundSubtle = Color(0xFFF0F9FF); // Akıcı bulut mavisi zemin

    return Scaffold(
      backgroundColor: backgroundSubtle,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildSliverAppBar(context),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(22, 20, 22, 40),
              child: Column(
                children: [
                  const SizedBox(height: 15),
                  _buildHeroSection(), // Uygulamanın amacını anlatan ana kart
                  const SizedBox(height: 35),
                  _buildSectionHeader("KAHRAMAN GÜÇLERİN"),
                  const SizedBox(height: 18),

                  _buildValueCard(
                    Icons.auto_awesome_rounded,
                    "Cesaret Elçisi",
                    "Sessiz kalmak değil, durumu paylaşmak gerçek bir kahramanlıktır. Yardım istemekten korkma!",
                    const Color(0xFF6C63FF),
                    100,
                  ),
                  _buildValueCard(
                    Icons.security_rounded,
                    "Güvenlik Kalkanı",
                    "Zorbalığa karşı en büyük silahın bilgindir. İnternette ve hayatta güvenliğin bize emanet!",
                    const Color(0xFFFF6584),
                    250,
                  ),
                  _buildValueCard(
                    Icons.sentiment_very_satisfied_rounded,
                    "Nezaket Maskotu",
                    "Kelimelerin sandığından çok daha güçlü! İnterneti nezaketinle aydınlatmaya hazır mısın?",
                    const Color(0xFF10B981), // Colors.green yerine modern zümrüt tonu
                    400,
                  ),

                  const SizedBox(height: 20),
                  _buildFooter(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Görsel efektler, logolar ve animasyonlu baloncuklar içeren esnek başlık çubuğu
  Widget _buildSliverAppBar(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 320,
      pinned: true,
      stretch: true,
      backgroundColor: const Color(0xFF3B82F6),
      elevation: 0,
      leading: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white24,
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 16),
            onPressed: () => Navigator.pop(context),
          ),
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Arka Plan Yumuşak Geçişli Gradyant
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),

            // Hareketli Dekoratif Baloncuklar: Arka plana dinamizm katar
            _buildAnimatedBubble(top: 40, left: -20, size: 110, color: Colors.white.withOpacity(0.08)),
            _buildAnimatedBubble(top: 140, right: -40, size: 150, color: Colors.white.withOpacity(0.06)),
            _buildAnimatedBubble(bottom: 80, left: 50, size: 70, color: Colors.white.withOpacity(0.05)),

            SafeArea(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo Alanı: Sürekli yukarı-aşağı süzülme animasyonu içerir
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 25, offset: const Offset(0, 12)),
                      ],
                    ),
                    child: const Icon(Icons.shield_rounded, size: 55, color: Color(0xFF3B82F6)),
                  ).animate(onPlay: (c) => c.repeat(reverse: true)).moveY(begin: -6, end: 6, duration: 1000.ms, curve: Curves.easeInOut),

                  const SizedBox(height: 16),
                  Text(
                    "SİBER KAHRAMAN",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 28,
                      letterSpacing: 1.5,
                      shadows: [
                        Shadow(color: Colors.black.withOpacity(0.15), offset: const Offset(0, 3), blurRadius: 4),
                      ],
                    ),
                  ).animate().fadeIn(delay: 150.ms).scale(begin: const Offset(0.95, 0.95)),

                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                    decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.18),
                        borderRadius: BorderRadius.circular(20)
                    ),
                    child: const Text(
                      "Güçlü, Bilinçli ve Güvende! 🛡️",
                      style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 0.2),
                    ),
                  ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.3),
                ],
              ),
            ),

            // Gövde ile başlık arasında pürüzsüz geçiş sağlayan kavisli kenar (Bottom Curve)
            Positioned(
              bottom: -1,
              left: 0,
              right: 0,
              child: Container(
                height: 35,
                decoration: const BoxDecoration(
                  color: Color(0xFFF0F9FF), // backgroundSubtle ile tam eşleşme
                  borderRadius: BorderRadius.vertical(top: Radius.circular(35)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Uygulamanın vizyonunu anlatan parlama (shimmer) efektli kahraman kartı
  Widget _buildHeroSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(color: const Color(0xFF3B82F6).withOpacity(0.06), blurRadius: 25, offset: const Offset(0, 10)),
        ],
      ),
      child: Column(
        children: [
          const Text("✨", style: TextStyle(fontSize: 36))
              .animate(onPlay: (c) => c.repeat())
              .shimmer(duration: 1.8.seconds),
          const SizedBox(height: 6),
          const Text(
            "SANA NELER KATACAĞIZ?",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF3B82F6), letterSpacing: -0.3),
          ),
          const SizedBox(height: 12),
          const Text(
            "Zorbalıkla karşılaştığında ne yapacağını bilmen, internetin tehlikeli sularında güvenle yüzmen ve her zaman nazik bir dil kullanman için yanındayız. Bu yolculuğun sonunda gerçek bir siber kahraman olacaksın!",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13.5, height: 1.55, color: Color(0xFF475569), fontWeight: FontWeight.w600),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 200.ms).slideY(begin: 0.1, curve: Curves.easeOutBack);
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 6),
      child: Row(
        children: [
          const Text("🔥", style: TextStyle(fontSize: 22)),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: Color(0xFF1E293B), letterSpacing: 0.8),
          ),
        ],
      ),
    );
  }

  // Renkli ikonlar, sol şerit koruması ve alt gölgelerle özelleştirilmiş 3D görünümlü bilgi kartı yapısı
  Widget _buildValueCard(IconData icon, String title, String desc, Color color, int delay) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: IntrinsicHeight(
          child: Row(
            children: [
              Container(width: 6, color: color), // Sol şerit vurgusu kartı canlandırır
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(icon, color: color, size: 26),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                                title,
                                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Color(0xFF1E293B), letterSpacing: -0.2)
                            ),
                            const SizedBox(height: 4),
                            Text(
                                desc,
                                style: const TextStyle(fontSize: 13, color: Color(0xFF64748B), height: 1.4, fontWeight: FontWeight.w600)
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ).animate(delay: delay.ms).fadeIn(duration: 200.ms).slideY(begin: 0.1, curve: Curves.easeOutBack);
  }

  // Sayfanın en altındaki motive edici footer alanı
  Widget _buildFooter() {
    return Column(
      children: [
        const SizedBox(height: 10),
        const Text("🤝", style: TextStyle(fontSize: 44))
            .animate(onPlay: (c) => c.repeat(reverse: true))
            .scale(begin: const Offset(1, 1), end: const Offset(1.15, 1.15), duration: 200.ms, curve: Curves.easeInOut),
        const SizedBox(height: 12),
        const Text(
          "Gelecek, Senin Cesaretinle Güzel!",
          textAlign: TextAlign.center,
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: Color(0xFF3B82F6), letterSpacing: -0.2),
        ),
        const SizedBox(height: 4),
        Text(
          "v1.0.0 • TÜBİTAK 2209-A Projesi",
          style: TextStyle(color: Colors.blueGrey.shade300, fontSize: 11, fontWeight: FontWeight.bold, fontStyle: FontStyle.italic),
        ),
      ],
    ).animate().fadeIn(delay: 200.ms);
  }

  // AppBar'daki baloncukların ölçeklenme ve hareket animasyonlarını yöneten yardımcı widget
  Widget _buildAnimatedBubble({double? top, double? bottom, double? left, double? right, required double size, required Color color}) {
    return Positioned(
      top: top, bottom: bottom, left: left, right: right,
      child: Container(
        width: size, height: size,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
    ).animate(onPlay: (c) => c.repeat(reverse: true)).scale(begin: const Offset(1, 1), end: const Offset(1.25, 1.25), duration: 4.seconds).moveY(begin: 0, end: 25, duration: 5.seconds);
  }
}