import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

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
      setState(() {
        _scrollProgress = (_scrollController.offset / _scrollController.position.maxScrollExtent).clamp(0, 1);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F5FF),
      body: Stack(
        children: [
          // Arka Plan Süslemesi
          Positioned(
            top: -100,
            right: -100,
            child: CircleAvatar(radius: 200, backgroundColor: const Color(0xFF6C5CE7).withOpacity(0.05)),
          ),

          CustomScrollView(
            controller: _scrollController,
            physics: const BouncingScrollPhysics(),
            slivers: [
              _buildModernAppBar(),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
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
                        color: const Color(0xFF74B9FF),
                        delay: 300,
                      ),
                      _buildMissionCard(
                        title: "Dijital Zırhını Kuşan!",
                        subtitle: "Siber Güvenlik",
                        desc: "Şifrelerin senin evin anahtarı gibidir. En yakın arkadaşınla bile paylaşma! Tanımadığın kişilerden gelen linklere tıklamak, evinin kapısını yabancılara açmak gibidir.",
                        tip: "Görev: Şifreni sayılar ve sembollerle güçlendir!",
                        icon: Icons.vibration_rounded,
                        color: const Color(0xFFA29BFE),
                        delay: 500,
                      ),
                      _buildMissionCard(
                        title: "Yardım İstemek Kahramanlıktır!",
                        subtitle: "Destek Almak",
                        desc: "Kötü bir durum yaşadığında bunu tek başına çözmek zorunda değilsin. Ailen, öğretmenlerin veya Siber Asistan her zaman seni dinlemeye hazır.",
                        tip: "Önemli: Sessiz kalmak zorbalığın devam etmesine neden olur.",
                        icon: Icons.volunteer_activism_rounded,
                        color: const Color(0xFF55E6C1),
                        delay: 700,
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Üstteki İlerleme Çubuğu
          Positioned(
            top: MediaQuery.of(context).padding.top + 56,
            left: 0,
            right: 0,
            child: LinearProgressIndicator(
              value: _scrollProgress,
              backgroundColor: Colors.transparent,
              color: const Color(0xFF6C5CE7),
              minHeight: 4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernAppBar() {
    return SliverAppBar(
      expandedHeight: 120,
      floating: false,
      pinned: true,
      elevation: 0,
      backgroundColor: Colors.white.withOpacity(0.9),
      flexibleSpace: const FlexibleSpaceBar(
        centerTitle: true,
        title: Text("KAHRAMAN REHBERİ",
            style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF2D3436), fontSize: 18)),
      ),
    );
  }

  Widget _buildInfoBanner() {
    return Container(
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF6C5CE7), Color(0xFF8E44AD)]),
        borderRadius: BorderRadius.circular(35),
        boxShadow: [
          BoxShadow(color: const Color(0xFF6C5CE7).withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10))
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.stars_rounded, color: Colors.amber, size: 50)
              .animate(onPlay: (c) => c.repeat())
              .shimmer(duration: 2.seconds),
          const SizedBox(width: 15),
          const Expanded(
            child: Text(
              "Güvenlik rozetini kazanmak için tüm görevleri oku!",
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
            ),
          ),
        ],
      ),
    );
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
      margin: const EdgeInsets.only(bottom: 25),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(color: color.withOpacity(0.1), blurRadius: 15, offset: const Offset(0, 10)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: IntrinsicHeight(
          child: Row(
            children: [
              Container(width: 8, color: color), // Yan renk şeridi
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(icon, color: color, size: 28),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(subtitle.toUpperCase(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color, letterSpacing: 1.2)),
                              Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF2D3436))),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 15),
                      Text(desc, style: TextStyle(color: Colors.blueGrey.shade800, fontSize: 14, height: 1.5, fontWeight: FontWeight.w500)),
                      const SizedBox(height: 15),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: color.withOpacity(0.05), borderRadius: BorderRadius.circular(15)),
                        child: Row(
                          children: [
                            Icon(Icons.lightbulb_outline_rounded, size: 18, color: color),
                            const SizedBox(width: 10),
                            Expanded(child: Text(tip, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color.withOpacity(0.8)))),
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
    ).animate(delay: delay.ms).fadeIn().slideX(begin: 0.1, curve: Curves.easeOutBack);
  }
}