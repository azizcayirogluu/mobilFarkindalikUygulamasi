import 'package:flutter/material.dart';
import 'package:zorbalik_uygulamasi/screens/hikaye_listeleme_ekrani.dart';
import 'package:zorbalik_uygulamasi/screens/senaryo_listeleme_ekrani.dart';
import 'package:zorbalik_uygulamasi/screens/video_listeleme_ekrani.dart';
import 'package:zorbalik_uygulamasi/screens/siber_dedektif_oyunu.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'guvenlik_rehberi_ekrani.dart';

class EgitimEkrani extends StatelessWidget {
  const EgitimEkrani({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final double paddingValue = size.width > 600 ? 32 : 20;
    const Color backgroundSubtle = Color(0xFFF8FAFC);
    final bottomInset = MediaQuery.paddingOf(context).bottom + 80;

    return Scaffold(
      backgroundColor: backgroundSubtle,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildSliverAppBar(backgroundSubtle),
          SliverPadding(
            padding: EdgeInsets.fromLTRB(paddingValue, 10, paddingValue, bottomInset),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildWelcomeHeader(),
                const SizedBox(height: 24),

                _buildKidEgitimCard(
                  context,
                  title: "Zorbalık Rehberi 🛡️",
                  desc: "Zorbalık nedir, nasıl başa çıkılır? Kahramanlık rehberini oku!",
                  icon: Icons.auto_awesome_rounded,
                  accentColor: const Color(0xFF8B5CF6),
                  label: "TEMEL BİLGİLER",
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const GuvenlikRehberiEkrani())),
                  delay: 0.ms,
                ),

                _buildKidEgitimCard(
                  context,
                  title: "Senaryo Çöz 🧠",
                  desc: "Zor durumlar karşısında en doğru kararı sen ver, kahraman ol!",
                  icon: Icons.psychology_alt_rounded,
                  accentColor: const Color(0xFF6366F1),
                  label: "KAHRAMANLIK GÖREVİ",
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const SenaryoListelemeEkrani())),
                  delay: 20.ms,
                ),

                _buildKidEgitimCard(
                  context,
                  title: "Kahraman Dedektif 🔍",
                  desc: "Olayları gizemli bir dedektif gibi incele, tehlikeleri ortaya çıkar!",
                  icon: Icons.search_rounded,
                  accentColor: const Color(0xFF10B981),
                  label: "SÜPER OYUN",
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const SiberDedektifOyunu())),
                  delay: 30.ms,
                ),

                _buildKidEgitimCard(
                  context,
                  title: "Hikaye Oku 📚",
                  desc: "Eğlenceli ve heyecanlı öyküleri oku, yeni taktikler öğren!",
                  icon: Icons.auto_stories_rounded,
                  accentColor: const Color(0xFFF59E0B),
                  label: "GÜÇLÜ BİLGİLER",
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const HikayeListelemeEkrani())),
                  delay: 60.ms,
                ),

                _buildKidEgitimCard(
                  context,
                  title: "Video İzle 🎬",
                  desc: "Harika ve renkli animasyonlarla en pratik ipuçlarını yakala.",
                  icon: Icons.play_circle_filled_rounded,
                  accentColor: const Color(0xFF3B82F6),
                  label: "EĞLENCELİ VİDEO",
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const VideoListelemeEkrani())),
                  delay: 90.ms,
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar(Color bgColor) {
    return SliverAppBar(
      floating: true,
      pinned: false,
      backgroundColor: bgColor,
      elevation: 0,
      centerTitle: true,
      title: const Text(
        "KAHRAMANLIK AKADEMİSİ",
        textAlign: TextAlign.center,
        style: TextStyle(
          color: Color(0xFF1E293B),
          fontWeight: FontWeight.w900,
          fontSize: 16,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildWelcomeHeader() {
    return Column(
      children: [
        const Text(
          "Bugün hangi süper gücünü geliştirmek istersin? 🛡️",
          style: TextStyle(
            fontSize: 15,
            color: Color(0xFF475569),
            fontWeight: FontWeight.w700,
          ),
          textAlign: TextAlign.center,
        ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.05, curve: Curves.easeOutQuad),
        const SizedBox(height: 10),
        Container(
          width: 36,
          height: 4,
          decoration: BoxDecoration(
            color: const Color(0xFF3B82F6).withAlpha(100),
            borderRadius: BorderRadius.circular(10),
          ),
        ).animate().scaleX(duration: 200.ms, curve: Curves.easeOutQuad),
      ],
    );
  }

  Widget _buildKidEgitimCard(
      BuildContext context, {
        required String title,
        required String desc,
        required IconData icon,
        required Color accentColor,
        required String label,
        required VoidCallback onTap,
        required Duration delay,
      }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: accentColor.withAlpha(12),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: accentColor.withAlpha(20),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Icon(
                      icon,
                      size: 32,
                      color: accentColor,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: accentColor.withAlpha(20),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            label,
                            style: TextStyle(
                              color: accentColor,
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFF1E293B),
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          desc,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFF64748B),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            height: 1.25,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: const Color(0xFF94A3B8),
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ).animate(delay: delay).fadeIn(duration: 300.ms).slideY(begin: 0.05, curve: Curves.easeOutQuad);
  }
}
