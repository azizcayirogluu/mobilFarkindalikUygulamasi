import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:ui';
import 'dart:math' as math;

class GuvenlikRehberiEkrani extends StatefulWidget {
  const GuvenlikRehberiEkrani({super.key});

  @override
  State<GuvenlikRehberiEkrani> createState() => _GuvenlikRehberiEkraniState();
}

class _GuvenlikRehberiEkraniState extends State<GuvenlikRehberiEkrani> {
  final ScrollController _scrollController = ScrollController();
  double _scrollProgress = 0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      if (_scrollController.hasClients && _scrollController.position.maxScrollExtent > 0) {
        setState(() {
          _scrollProgress = (_scrollController.offset / _scrollController.position.maxScrollExtent).clamp(0, 1);
        });
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const Color backgroundSubtle = Color(0xFFF0F9FF); // Canlı bulut mavisi zemin

    return Scaffold(
      backgroundColor: backgroundSubtle,
      body: Stack(
        children: [
          // Arka Plan Eğlenceli Geometrik Şekiller
          Positioned(
            top: -60,
            left: -60,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF6C5CE7).withOpacity(0.04),
              ),
            ),
          ),
          Positioned(
            bottom: 150,
            right: -40,
            child: Transform.rotate(
              angle: math.pi / 6,
              child: Container(
                width: 130,
                height: 130,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(35),
                  color: const Color(0xFFFF7675).withOpacity(0.03),
                ),
              ),
            ),
          ),

          CustomScrollView(
            controller: _scrollController,
            physics: const BouncingScrollPhysics(),
            slivers: [
              _buildModernAppBar(),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(22, 20, 22, 40),
                  child: Column(
                    children: [
                      _buildInfoBanner(),
                      const SizedBox(height: 30),

                      _buildMissionCard(
                        title: "Bedenim Benim Kalem!",
                        subtitle: "Fiziksel Sınırlar",
                        desc: "Hiç kimse sana istemediğin bir şekilde dokunamaz. Eğer biri seni rahatsız ederse, o ortamdan uzaklaş ve en güvendiğin büyüğüne anlat. 'HAYIR' demek senin en doğal hakkın!",
                        tip: "Unutma: Kimse senden gizli bir şey saklamanı isteyemez.",
                        icon: Icons.shield_rounded,
                        color: const Color(0xFFFF7675),
                        delay: 100,
                      ),
                      _buildMissionCard(
                        title: "Klavye Şövalyesi Olma!",
                        subtitle: "Dijital Nezaket",
                        desc: "İnternette yazdığın her kelime gerçek hayattaki kadar önemlidir. Birine mesaj atmadan önce 'Biri bana bunu yazsa ne hissederdim?' diye düşün.",
                        tip: "İpucu: Ekranın arkasında gerçek bir insan olduğunu unutma.",
                        icon: Icons.auto_awesome_rounded,
                        color: const Color(0xFF3498DB),
                        delay: 250,
                      ),
                      _buildMissionCard(
                        title: "Dijital Zırhını Kuşan!",
                        subtitle: "Siber Güvenlik",
                        desc: "Şifrelerin senin evin anahtarı gibidir. En yakın arkadaşınla bile paylaşma! Tanımadığın kişilerden gelen linklere tıklamak, evinin kapısını yabancılara açmak gibidir.",
                        tip: "Görev: Şifreni sayılar ve sembollerle güçlendir!",
                        icon: Icons.lock_person_rounded,
                        color: const Color(0xFF9B59B6),
                        delay: 400,
                      ),
                      _buildMissionCard(
                        title: "Yardım İstemek Kahramanlıktır!",
                        subtitle: "Destek Almak",
                        desc: "Kötü bir durum yaşadığında bunu tek başına çözmek zorunda değilsin. Ailen, öğretmenlerin veya Siber Asistan her zaman seni dinlemeye hazır.",
                        tip: "Önemli: Sessiz kalmak zorbalığın devam etmesine neden olur.",
                        icon: Icons.volunteer_activism_rounded,
                        color: const Color(0xFF2ECC71),
                        delay: 550,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Üst Kısım: Basitleştirilmiş İlerleme Çubuğu (Blur kaldırıldı - Performans için)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              height: MediaQuery.of(context).padding.top + 6,
              color: Colors.white.withOpacity(0.9),
              alignment: Alignment.bottomCenter,
              child: LinearProgressIndicator(
                value: _scrollProgress,
                backgroundColor: Colors.blueGrey.shade50.withOpacity(0.5),
                color: const Color(0xFF6C5CE7),
                minHeight: 5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernAppBar() {
    return SliverAppBar(
      expandedHeight: 140,
      floating: false,
      pinned: true,
      elevation: 0,
      backgroundColor: Colors.white.withOpacity(0.85),
      leading: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 3)),
            ],
          ),
          child: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: Color(0xFF2D3436)),
            onPressed: () => Navigator.pop(context),
          ),
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        centerTitle: true,
        titlePadding: const EdgeInsets.only(bottom: 14),
        title: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "KAHRAMAN REHBERİ",
              style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF0F172A), fontSize: 16, letterSpacing: -0.5),
            ),
            const SizedBox(height: 2),
            Text(
              "Güvenli Kalma Kuralları",
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey.shade400, fontSize: 9, letterSpacing: 0.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoBanner() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.stars_rounded, color: Colors.amber, size: 36),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Büyük Görev Başladı! 🚀",
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16),
                ),
                SizedBox(height: 3),
                Text(
                  "Güvenlik rozetini kazanmak için tüm maddeleri dikkatlice oku.",
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 11, height: 1.3),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).scale(begin: const Offset(0.9, 0.9), curve: Curves.easeOutBack);
  }

  Widget _buildMissionCard({
    required String title,
    required String subtitle,
    required String desc,
    required String tip,
    required IconData icon,
    required Color color,
    required int delay,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: IntrinsicHeight(
          child: Row(
            children: [
              Container(width: 7, color: color),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(22),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Icon(icon, color: color, size: 24),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                    subtitle.toUpperCase(),
                                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: color, letterSpacing: 1.2)
                                ),
                                const SizedBox(height: 1),
                                Text(
                                    title,
                                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: Color(0xFF1E293B), letterSpacing: -0.3)
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                          desc,
                          style: const TextStyle(color: Color(0xFF475569), fontSize: 13.5, height: 1.5, fontWeight: FontWeight.w600)
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.04),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: color.withOpacity(0.08), width: 1),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.lightbulb_outline_rounded, size: 16, color: color),
                            const SizedBox(width: 8),
                            Expanded(
                                child: Text(
                                    tip,
                                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: color.withOpacity(0.9), height: 1.3)
                                )
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
    ).animate(delay: delay.ms).fadeIn(duration: 500.ms).slideY(begin: 0.12, curve: Curves.easeOutBack);
  }
}