import 'package:flutter/material.dart';
import 'package:zorbalik_uygulamasi/app_theme.dart';
import 'package:zorbalik_uygulamasi/screens/hikaye_listeleme_ekrani.dart';
import 'package:zorbalik_uygulamasi/screens/senaryo_listeleme_ekrani.dart';
import 'package:zorbalik_uygulamasi/screens/video_listeleme_ekrani.dart';
import 'package:zorbalik_uygulamasi/screens/siber_dedektif_oyunu.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:math' as math; // Dekoratif arka plan dalgaları için

class EgitimEkrani extends StatelessWidget {
  const EgitimEkrani({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final double paddingValue = size.width * 0.06;
    const Color backgroundSubtle = Color(0xFFF0F9FF);

    return Scaffold(
      backgroundColor: backgroundSubtle,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildSliverAppBar(backgroundSubtle),
          SliverPadding(
            padding: EdgeInsets.fromLTRB(paddingValue, 10, paddingValue, 20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildWelcomeHeader(),
                const SizedBox(height: 25),

                _buildKidEgitimCard(
                  context,
                  title: "Senaryo Çöz 🧠",
                  desc: "Zor durumlar karşısında en doğru kararı sen ver, kahraman ol!",
                  icon: Icons.psychology_alt_rounded,
                  accentColor: const Color(0xFF6366F1),
                  label: "KAHRAMANLUK GÖREVİ",
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const SenaryoListelemeEkrani())),
                  delay: 0.ms,
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

                const SizedBox(height: 130),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar(Color bgColor) {
    return SliverAppBar(
      expandedHeight: 90.0,
      floating: true,
      pinned: false,
      backgroundColor: bgColor,
      elevation: 0,
      centerTitle: true,
      flexibleSpace: FlexibleSpaceBar(
        centerTitle: true,
        title: Text(
          "KAHRAMANLIK AKADEMİSİ",
          style: TextStyle(
            color: const Color(0xFF2C3E50),
            fontWeight: FontWeight.w900,
            fontSize: 14,
            letterSpacing: 1,
            shadows: [
              Shadow(
                color: Colors.black.withOpacity(0.05),
                offset: const Offset(0, 2),
                blurRadius: 2,
              )
            ],
          ),
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
            fontSize: 16,
            color: Color(0xFF475569),
            fontWeight: FontWeight.w700,
          ),
          textAlign: TextAlign.center,
        ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.05, curve: Curves.easeOutQuad),
        const SizedBox(height: 10),
        Container(
          width: 35,
          height: 5,
          decoration: BoxDecoration(
            color: const Color(0xFF3B82F6).withOpacity(0.4),
            borderRadius: BorderRadius.circular(10),
          ),
        ).animate().scaleX(duration: 400.ms, curve: Curves.easeOutQuad),
      ],
    );
  }

  // Yenilenen, Beyaz ve Temiz Çocuksu Eğitim Kart Tasarımı
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
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: accentColor.withOpacity(0.06),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Container(
                    width: 75,
                    height: 75,
                    decoration: BoxDecoration(
                      color: accentColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Icon(
                      icon,
                      size: 36,
                      color: accentColor,
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            color: Color(0xFF1E293B),
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          desc,
                          style: const TextStyle(
                            color: Color(0xFF64748B),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            height: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: accentColor.withOpacity(0.3),
                    size: 14,
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
