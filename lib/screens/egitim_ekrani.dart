import 'package:flutter/material.dart';
import 'package:zorbalik_uygulamasi/app_theme.dart';
import 'package:zorbalik_uygulamasi/screens/hikaye_listeleme_ekrani.dart';
import 'package:zorbalik_uygulamasi/screens/senaryo_listeleme_ekrani.dart';
import 'package:zorbalik_uygulamasi/screens/video_listeleme_ekrani.dart';

class EgitimEkrani extends StatelessWidget {
  const EgitimEkrani({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final double paddingValue = size.width * 0.05;

    return Scaffold(
      backgroundColor: AppColors.zemin,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            expandedHeight: 80.0,
            floating: false,
            pinned: true,
            backgroundColor: AppColors.zemin,
            elevation: 0,
            automaticallyImplyLeading: false,
            centerTitle: true,
            title: const Text(
              "KEŞFET VE ÖĞREN",
              style: TextStyle(
                color: AppColors.yaziRengi,
                fontWeight: FontWeight.w900,
                fontSize: 18,
                letterSpacing: 1.2,
              ),
            ),
          ),
          SliverPadding(
            padding: EdgeInsets.symmetric(horizontal: paddingValue, vertical: 10),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                const Text(
                  "Hangi görevle başlamak istersin? 🛡️",
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),

                _buildGamifiedCard(
                  context,
                  size: size,
                  title: "Senaryo Çöz",
                  desc: "Gerçek hayat durumlarında doğru kararı ver.",
                  icon: Icons.psychology_rounded,
                  colors: [const Color(0xFF9575CD), const Color(0xFF673AB7)],
                  label: "GÖREV",
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SenaryoListelemeEkrani())),
                  imagePath: "assets/scenarios.png",
                ),

                _buildGamifiedCard(
                  context,
                  size: size,
                  title: "Hikaye Oku",
                  desc: "Eğitici öykülerle dünyayı tanı.",
                  icon: Icons.auto_stories_rounded,
                  colors: [const Color(0xFFFFB74D), const Color(0xFFF57C00)],
                  label: "BİLGİ",
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HikayeListelemeEkrani())),
                  imagePath: "assets/history.jpg",
                ),

                _buildGamifiedCard(
                  context,
                  size: size,
                  title: "Video İzle",
                  desc: "Akranlarından altın ipuçları al.",
                  icon: Icons.play_circle_filled_rounded,
                  colors: [const Color(0xFFE57373), const Color(0xFFD32F2F)],
                  label: "İZLE",
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const VideoListelemeEkrani())),
                  imagePath: "assets/videos.jpg",
                ),

                const SizedBox(height: 100),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGamifiedCard(
      BuildContext context, {
        required Size size,
        required String title,
        required String desc,
        required IconData icon,
        required List<Color> colors,
        required String label,
        required VoidCallback onTap,
        required String imagePath,
      }) {
    double cardHeight = size.height * 0.16;
    if (cardHeight < 135) cardHeight = 135;
    if (cardHeight > 165) cardHeight = 165;

    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      height: cardHeight,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: colors.last.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: InkWell(
          onTap: onTap,
          child: Stack(
            children: [
              // 1. KATMAN: Ana Renk Gradyanı
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: colors,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                ),
              ),

              // 2. KATMAN: Arka Plan Resmi (%25 Opaklık ve Harmanlama)
              Positioned.fill(
                child: Opacity(
                  opacity: 0.25,
                  child: Image.asset(
                    imagePath,
                    fit: BoxFit.cover,
                    colorBlendMode: BlendMode.multiply,
                  ),
                ),
              ),

              // 3. KATMAN: Okunabilirlik İçin Siyah Gradyan (Overlay)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.black.withOpacity(0.5),
                        Colors.transparent,
                        Colors.black.withOpacity(0.2),
                      ],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                  ),
                ),
              ),

              // 4. KATMAN: Dekoratif Büyük İkon
              Positioned(
                bottom: -20,
                right: -10,
                child: Icon(
                  icon,
                  size: cardHeight * 0.9,
                  color: Colors.white.withOpacity(0.15),
                ),
              ),

              // 5. KATMAN: İçerik (Yazılar ve Etiket)
              Padding(
                padding: EdgeInsets.symmetric(horizontal: size.width * 0.06),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
                      ),
                      child: Text(
                        label,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      title,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: size.width > 600 ? 26 : 22,
                        fontWeight: FontWeight.w900,
                        shadows: [
                          Shadow(
                            color: Colors.black.withOpacity(0.3),
                            offset: const Offset(0, 2),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      desc,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: size.width > 600 ? 14 : 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}