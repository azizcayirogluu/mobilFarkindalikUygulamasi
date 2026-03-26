import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:zorbalik_uygulamasi/app_theme.dart';
import 'package:zorbalik_uygulamasi/screens/senaryo_detay_ekrani.dart';
import 'package:zorbalik_uygulamasi/screens/hikaye_detay_ekrani.dart';
import 'package:zorbalik_uygulamasi/screens/video_detay_ekrani.dart';

class AnaSayfa extends StatefulWidget {
  final VoidCallback onProfileTap;
  final Function(int) onTabChanged;
  final String kullaniciAdi;

  const AnaSayfa({
    super.key,
    required this.onProfileTap,
    required this.onTabChanged,
    required this.kullaniciAdi,
  });

  @override
  State<AnaSayfa> createState() => _AnaSayfaState();
}

class _AnaSayfaState extends State<AnaSayfa> {
  List<Map<String, dynamic>> _kesifHavuzu = [];
  bool _isLoading = true;
  int _toplamBolum = 0;

  final User? _currentUser = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    _initData();
  }

  Color _hexToColor(String? hexString) {
    if (hexString == null || hexString.isEmpty) return AppColors.anaMavi;
    try {
      final buffer = StringBuffer();
      String cleanHex = hexString.replaceFirst('#', '').replaceFirst('0x', '');
      if (cleanHex.length == 6) buffer.write('ff');
      buffer.write(cleanHex);
      return Color(int.parse(buffer.toString(), radix: 16));
    } catch (e) {
      return AppColors.anaMavi;
    }
  }

  IconData _getIcon(String? iconName) {
    switch (iconName) {
      case 'psychology': return Icons.psychology_alt_rounded;
      case 'auto_stories': return Icons.auto_stories_rounded;
      case 'play': return Icons.play_circle_filled_rounded;
      case 'security': return Icons.security_rounded;
      case 'bolt': return Icons.bolt_rounded;
      case 'favorite': return Icons.favorite_rounded;
      case 'visibility': return Icons.visibility_rounded;
      case 'people': return Icons.people_alt_rounded;
      case 'star': return Icons.star_rounded;
      default: return Icons.stars_rounded;
    }
  }

  String _getDinamikMesaj(double ilerleme) {
    int yuzde = (ilerleme * 100).toInt();
    if (yuzde == 0) return "Maceraya atılmaya hazır mısın? İlk görevini seç!";
    if (yuzde < 20) return "Harika bir başlangıç! Siber dünya seni tanımaya başlıyor. 🌟";
    if (yuzde < 40) return "Yolun üçte biri bitti! Bilgin her geçen gün artıyor. 💪";
    if (yuzde < 60) return "Yarı yolu geçtin! Gerçek bir siber koruyucu oluyorsun. 🛡️";
    if (yuzde < 80) return "Mükemmel ilerleme! Rozetlerine çok az kaldı. ✨";
    if (yuzde < 100) return "Neredeyse başardın! Son adımları atmaya hazır mısın? 🔥";
    return "Tebrikler Kahraman! Tüm görevleri başarıyla tamamladın! 🎉";
  }

  Future<void> _initData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      List<Map<String, dynamic>> senaryoListesi = [];
      List<Map<String, dynamic>> hikayeListesi = [];
      List<Map<String, dynamic>> videoListesi = [];
      int toplam = 0;

      final sSnap = await FirebaseFirestore.instance.collection('scenarios').get();
      for (var d in sSnap.docs) {
        final data = d.data();
        final bolumler = (data['bolumler'] as List?) ?? [];
        toplam += bolumler.length;
        senaryoListesi.add({
          "id": d.id,
          "tip": "SENARYO",
          "baslik": data['baslik'] ?? "Zorbalık Senaryosu",
          "altBaslik": data['altBaslik'] ?? "Kararlarınla hikayeyi yönet.",
          "renk": _hexToColor(data['renk'] ?? "0xFF9575CD"),
          "ikon": _getIcon(data['ikon'] ?? "psychology"),
          "data": data,
        });
      }

      final hSnap = await FirebaseFirestore.instance.collection('stories').limit(5).get();
      for (var d in hSnap.docs) {
        final data = d.data();
        hikayeListesi.add({
          "id": d.id,
          "tip": "HİKAYE",
          "baslik": data['baslik'] ?? "Eğitici Öykü",
          "altBaslik": data['altBaslik'] ?? "Gerçek deneyimleri oku.",
          "renk": _hexToColor(data['renk'] ?? "0xFFFFB74D"),
          "ikon": _getIcon(data['ikon'] ?? "auto_stories"),
          "data": data,
        });
      }

      final vSnap = await FirebaseFirestore.instance.collection('videos').limit(5).get();
      for (var d in vSnap.docs) {
        final data = d.data();
        videoListesi.add({
          "id": d.id,
          "tip": "VİDEO",
          "baslik": data['baslik'] ?? "Video Rehber",
          "altBaslik": data['altBaslik'] ?? "İzle ve farkındalık kazan.",
          "renk": _hexToColor(data['renk'] ?? "0xFFE57373"),
          "ikon": _getIcon(data['ikon'] ?? "play"),
          "data": data,
        });
      }

      List<Map<String, dynamic>> finalHavuz = [];
      senaryoListesi.shuffle();
      hikayeListesi.shuffle();
      videoListesi.shuffle();

      if (senaryoListesi.isNotEmpty) finalHavuz.add(senaryoListesi.removeAt(0));
      if (hikayeListesi.isNotEmpty) finalHavuz.add(hikayeListesi.removeAt(0));
      if (videoListesi.isNotEmpty) finalHavuz.add(videoListesi.removeAt(0));

      List<Map<String, dynamic>> kalanlar = [...senaryoListesi, ...hikayeListesi, ...videoListesi];
      kalanlar.shuffle();

      if (kalanlar.isNotEmpty && finalHavuz.length < 4) {
        finalHavuz.add(kalanlar.first);
      }

      finalHavuz.shuffle();

      if (mounted) {
        setState(() {
          _toplamBolum = toplam == 0 ? 1 : toplam;
          _kesifHavuzu = finalHavuz;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Veri çekme hatası: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_currentUser == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    final size = MediaQuery.of(context).size;
    final double paddingValue = size.width * 0.05;

    final String ad = _currentUser!.displayName ?? widget.kullaniciAdi;
    final String uid = _currentUser!.uid;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Stack(
        children: [
          Positioned(top: -100, right: -100, child: _decorCircle(size.width * 0.7, AppColors.anaMavi.withOpacity(0.03))),
          SafeArea(
            child: StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance.collection('usersProgress').doc(uid).snapshots(),
              builder: (context, snap) {
                int puan = 0;
                List tamamlananlar = [];
                if (snap.hasData && snap.data!.exists) {
                  final data = snap.data!.data() as Map<String, dynamic>;
                  puan = data['toplam_puan'] ?? 0;
                  tamamlananlar = data['tamamlanan_bolumler'] as List? ?? [];
                }
                return RefreshIndicator(
                  onRefresh: _initData,
                  displacement: 20,
                  color: AppColors.anaMavi,
                  child: CustomScrollView(
                    physics: const BouncingScrollPhysics(),
                    slivers: [
                      _buildAppBar(ad, paddingValue),
                      SliverPadding(
                        padding: EdgeInsets.fromLTRB(paddingValue, 10, paddingValue, 20),
                        sliver: SliverToBoxAdapter(child: _buildProgressCard(tamamlananlar, puan, size)),
                      ),
                      _buildSectionTitle("Senin İçin Önerilenler", paddingValue),
                      _isLoading
                          ? const SliverFillRemaining(child: Center(child: CircularProgressIndicator()))
                          : SliverPadding(
                        padding: EdgeInsets.symmetric(horizontal: paddingValue),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                                (c, i) => _buildModernContentCard(_kesifHavuzu[i], size),
                            childCount: _kesifHavuzu.length,
                          ),
                        ),
                      ),
                      const SliverToBoxAdapter(child: SizedBox(height: 120)),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar(String ad, double padding) {
    return SliverAppBar(
      floating: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      toolbarHeight: 90,
      title: Padding(
        padding: EdgeInsets.symmetric(horizontal: padding / 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("İyi günler,", style: TextStyle(color: Colors.blueGrey.shade400, fontSize: 14, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 2),
                  Text("$ad 👋",
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xFF0F172A), letterSpacing: -0.5),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Hero(
              tag: 'profile_hero',
              child: GestureDetector(
                onTap: widget.onProfileTap,
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(colors: [AppColors.anaMavi, AppColors.anaMavi.withOpacity(0.4)]),
                    boxShadow: [BoxShadow(color: AppColors.anaMavi.withOpacity(0.2), blurRadius: 15, offset: const Offset(0, 5))],
                  ),
                  child: const CircleAvatar(
                      radius: 28,
                      backgroundColor: Colors.white,
                      backgroundImage: AssetImage("assets/boy.png")
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildProgressCard(List tamamlananlar, int puan, Size size) {
    double ilerleme = _toplamBolum > 0
        ? (tamamlananlar.length / _toplamBolum).clamp(0.0, 1.0)
        : 0.0;
    double cardWidth = size.width;
    String dinamikMesaj = _getDinamikMesaj(ilerleme);

    return Container(
      width: cardWidth,
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
              color: AppColors.anaMavi.withOpacity(0.35),
              blurRadius: 25,
              offset: const Offset(0, 10)
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: Stack(
          children: [
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.anaMavi, AppColors.anaMavi.withBlue(230)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: Opacity(
                opacity: 0.15,
                child: Image.asset("assets/isilti.jpg", fit: BoxFit.cover, colorBlendMode: BlendMode.screen),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(cardWidth * 0.055),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.stars_rounded, color: Colors.amberAccent, size: 16),
                          const SizedBox(width: 6),
                          const Text("GELİŞİM MERKEZİ",
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: 1.1)),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white.withOpacity(0.2)),
                        ),
                        child: Text("$puan TP",
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 11)),
                      )
                    ],
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Text("${(ilerleme * 100).toInt()}%",
                          style: const TextStyle(color: Colors.white, fontSize: 38, fontWeight: FontWeight.w900, letterSpacing: -1.5)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(dinamikMesaj,
                            style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600, height: 1.2)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Stack(
                    children: [
                      Container(
                        height: 10,
                        decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
                      ),
                      LayoutBuilder(
                        builder: (context, constraints) => Container(
                          height: 10,
                          width: constraints.maxWidth * ilerleme,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            gradient: const LinearGradient(colors: [Colors.white, Color(0xFFB3E5FC)]),
                            boxShadow: [BoxShadow(color: Colors.white.withOpacity(0.4), blurRadius: 8)],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("${tamamlananlar.length} / $_toplamBolum Görev Bitti",
                          style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 11, fontWeight: FontWeight.w800)),
                      Icon(ilerleme == 1.0 ? Icons.verified : Icons.check_circle_outline,
                          color: Colors.white.withOpacity(0.5), size: 18),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernContentCard(Map<String, dynamic> item, Size size) {
    final Color color = item['renk'];

    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(35),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.12),
            blurRadius: 25,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => _route(item),
        borderRadius: BorderRadius.circular(35),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(35),
          child: Stack(
            children: [
              Positioned(
                right: -20,
                bottom: -20,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.08),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Container(
                      width: 75,
                      height: 85,
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: Icon(item['ikon'], color: color, size: 35),
                    ),
                    const SizedBox(width: 18),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                            child: Text(item['tip'], style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: 0.8)),
                          ),
                          const SizedBox(height: 6),
                          Text(item['baslik'], style: const TextStyle(color: AppColors.yaziRengi, fontWeight: FontWeight.w900, fontSize: 17), maxLines: 1, overflow: TextOverflow.ellipsis),
                          const SizedBox(height: 2),
                          Text(item['altBaslik'], style: TextStyle(color: AppColors.yaziRengi.withOpacity(0.5), fontWeight: FontWeight.w500, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right_rounded, color: color.withOpacity(0.4), size: 26),
                    const SizedBox(width: 5),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, double padding) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: EdgeInsets.fromLTRB(padding, 15, padding, 15),
        child: Row(
          children: [
            Container(width: 4, height: 20, decoration: BoxDecoration(color: AppColors.anaMavi, borderRadius: BorderRadius.circular(10))),
            const SizedBox(width: 10),
            Text(title, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900, color: Color(0xFF1E293B))),
          ],
        ),
      ),
    );
  }

  Widget _decorCircle(double size, Color color) {
    return Container(width: size, height: size, decoration: BoxDecoration(color: color, shape: BoxShape.circle));
  }

  void _route(Map item) {
    final data = item['data'];
    switch (item['tip']) {
      case "SENARYO":
        Navigator.push(context, MaterialPageRoute(builder: (_) => SenaryoDetayEkrani(docId: item['id'], bolumIndex: 0)));
        break;
      case "HİKAYE":
        Navigator.push(context, MaterialPageRoute(builder: (_) => HikayeDetayEkrani(
          baslik: data['baslik'] ?? "Hikaye",
          gorselYolu: data['gorselYolu'] ?? "",
          temaRengi: item['renk'],
          hikayeMetni: data['hikayeMetni'] ?? "",
        )));
        break;
      case "VİDEO":
        Navigator.push(context, MaterialPageRoute(builder: (_) => VideoDetayEkrani(
          baslik: data['baslik'] ?? "Video",
          youtubeId: data['youtubeId'] ?? "",
          tumVideolarJson: _kesifHavuzu,
        )));
        break;
    }
  }
}
