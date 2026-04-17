import 'package:flutter/material.dart';
import 'package:zorbalik_uygulamasi/app_theme.dart';
import 'package:zorbalik_uygulamasi/screens/hikaye_listeleme_ekrani.dart';
import 'package:zorbalik_uygulamasi/screens/senaryo_listeleme_ekrani.dart';
import 'package:zorbalik_uygulamasi/screens/video_listeleme_ekrani.dart';
import 'package:zorbalik_uygulamasi/screens/siber_dedektif_oyunu.dart';
import 'package:flutter_animate/flutter_animate.dart';

class EgitimEkrani extends StatelessWidget {
  const EgitimEkrani({super.key});

  @override
  Widget build(BuildContext context) {
    // Ekran boyutuna göre dinamik padding hesapla
    final size = MediaQuery.of(context).size;
    final double paddingValue = size.width * 0.06;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFF),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildSliverAppBar(),
          SliverPadding(
            padding: EdgeInsets.fromLTRB(paddingValue, 5, paddingValue, 20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildWelcomeHeader(),
                const SizedBox(height: 25),

                // Eğitim modüllerini temsil eden animasyonlu kartlar
                _egitimKartlari(
                  context,
                  title: "Senaryo Çöz",
                  desc: "Zor anlarda en doğru kararı sen ver, puanları topla!",
                  icon: Icons.psychology_rounded,
                  gradient: const LinearGradient(
                    colors: [Color(0xFF8E2DE2), Color(0xFF4A00E0)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  label: "GÖREV",
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const SenaryoListelemeEkrani())),
                  imagePath: "assets/scenarios.png",
                  delay: 250.ms,
                ),

                _egitimKartlari(
                  context,
                  title: "Siber Dedektif",
                  desc: "Olayları incele, güvenli mi yoksa tehlikeli mi karar ver!",
                  icon: Icons.search_rounded,
                  gradient: const LinearGradient(
                    colors: [Color(0xFF00C9FF), Color(0xFF92FE9D)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  label: "OYUN",
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const SiberDedektifOyunu())),
                  imagePath: "assets/detective.jpg",
                  delay: 150.ms,
                ),

                _egitimKartlari(
                  context,
                  title: "Hikaye Oku",
                  desc: "Eğitici öykülerle zorbalığın kahramanı ol.",
                  icon: Icons.auto_stories_rounded,
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFF9966), Color(0xFFFF5E62)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  label: "BİLGİ",
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const HikayeListelemeEkrani())),
                  imagePath: "assets/history.jpg",
                  delay: 350.ms,
                ),

                _egitimKartlari(
                  context,
                  title: "Video İzle",
                  desc: "Eğlenceli videolarla en pratik ipuçlarını öğren.",
                  icon: Icons.play_circle_filled_rounded,
                  gradient: const LinearGradient(
                    colors: [Color(0xFF00B4DB), Color(0xFF0083B0)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  label: "İZLE",
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const VideoListelemeEkrani())),
                  imagePath: "assets/videos.jpg",
                  delay: 450.ms,
                ),

                const SizedBox(height: 120),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  // Kaydırıldığında küçülen veya sabitlenen esnek başlık çubuğu
  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 80.0,
      floating: true,
      pinned: true,
      backgroundColor: const Color(0xFFF8FAFF),
      elevation: 0,
      centerTitle: true,
      title: const Text(
        "KAHRAMANLIK AKADEMİSİ",
        style: TextStyle(
          color: AppColors.yaziRengi,
          fontWeight: FontWeight.w900,
          fontSize: 20,
          letterSpacing: 1.5,
        ),
      ),
    );
  }

  Widget _buildWelcomeHeader() {
    return Column(
      children: [
        const Text(
          "Bugün Hangi Gücünü Geliştireceksin? 🛡️",
          style: TextStyle(
            fontSize: 16,
            color: Colors.blueGrey,
            fontWeight: FontWeight.w800,
          ),
          textAlign: TextAlign.center,
        ).animate().fadeIn(duration: 600.ms).slideY(begin: -0.2),
        const SizedBox(height: 8),
        Container(
          width: 20,
          height: 4,
          decoration: BoxDecoration(
            color: AppColors.anaMavi.withOpacity(0.3),
            borderRadius: BorderRadius.circular(10),
          ),
        ).animate().scaleX(duration: 800.ms),
      ],
    );
  }

  Widget _egitimKartlari(
      BuildContext context, {
        required String title,
        required String desc,
        required IconData icon,
        required Gradient gradient,
        required String label,
        required VoidCallback onTap,
        required String imagePath,
        required Duration delay,
      }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 22),
      constraints: const BoxConstraints(minHeight: 160),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          // Gradyanın son rengine göre gölge oluşturarak derinlik algısı sağlar
          BoxShadow(
            color: (gradient as LinearGradient).colors.last.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            child: Stack(
              children: [
                // Arka plan gradyanı
                Positioned.fill(child: Container(decoration: BoxDecoration(gradient: gradient))),

                // Sağ üstteki dekoratif halka efekti
                Positioned(
                  top: -20, right: -20,
                  child: CircleAvatar(radius: 60, backgroundColor: Colors.white.withOpacity(0.1)),
                ),

                // Hafifçe görünen arka plan görseli
                Positioned.fill(
                  child: Opacity(
                    opacity: 0.1,
                    child: imagePath.contains("assets/") ? Image.asset(imagePath, fit: BoxFit.cover, errorBuilder: (c, e, s) => const SizedBox(),) : const SizedBox(),
                  ),
                ),

                // Sağ alttaki büyük transparan ikon dekorasyonu
                Positioned(
                  bottom: -15, right: -10,
                  child: Icon(icon, size: 110, color: Colors.white.withOpacity(0.15)),
                ),

                // Kart içeriği: Etiket, Başlık ve Açıklama
                Padding(
                  padding: const EdgeInsets.all(25.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white30),
                        ),
                        child: Text(
                          label,
                          style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.2),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        desc,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ).animate().fadeIn(delay: delay, duration: 600.ms).slideX(begin: 0.1, curve: Curves.easeOutBack);
  }
}