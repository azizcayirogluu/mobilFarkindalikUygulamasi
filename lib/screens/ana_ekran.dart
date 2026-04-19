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
  int _toplamGorevSayisi = 0; // Toplam Senaryo Bölümleri + Hikayeler

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
      default: return Icons.stars_rounded;
    }
  }

  String _ilerlemeMesaji(double ilerleme) {
    int yuzde = (ilerleme * 100).toInt();
    if (yuzde == 0) return "Maceraya atılmaya hazır mısın? İlk görevini seç!";
    if (yuzde < 40) return "Harika bir başlangıç! Siber dünya seni tanımaya başlıyor. 🌟";
    if (yuzde < 80) return "Mükemmel ilerleme! Rozetlerine çok az kaldı. ✨";
    if (yuzde < 100) return "Neredeyse başardın! Son adımları atmaya hazır mısın? 🔥";
    return "Tebrikler Kahraman! Tüm görevleri başarıyla tamamladın! 🎉";
  }

  Future<void> _initData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      int toplamBolumler = 0;
      int toplamHikayeler = 0;

      // 1. Tüm senaryoları kısıtlama olmadan çek (Toplam bölüm sayısı için)
      final sSnap = await FirebaseFirestore.instance.collection('scenarios').get();
      List<Map<String, dynamic>> senaryoOnerileri = [];
      for (var d in sSnap.docs) {
        final data = d.data();
        final bolumler = (data['bolumler'] as List?) ?? [];
        toplamBolumler += bolumler.length;
        
        if (senaryoOnerileri.length < 5) {
          senaryoOnerileri.add({
            "id": d.id, "tip": "SENARYO", "baslik": data['baslik'] ?? "Senaryo",
            "altBaslik": data['altBaslik'] ?? "Kararlarınla yönet.",
            "renk": _hexToColor(data['renk']), "ikon": _getIcon(data['ikon']), "data": data,
          });
        }
      }

      // 2. Tüm hikayeleri çek
      final hSnap = await FirebaseFirestore.instance.collection('stories').get();
      toplamHikayeler = hSnap.docs.length;
      List<Map<String, dynamic>> hikayeOnerileri = [];
      for (var d in hSnap.docs.take(5)) {
        final data = d.data();
        hikayeOnerileri.add({
          "id": d.id, "tip": "HİKAYE", "baslik": data['baslik'] ?? "Hikaye",
          "altBaslik": data['altBaslik'] ?? "Gerçek deneyimler.",
          "renk": _hexToColor(data['renk'] ?? "0xFFFFB74D"), "ikon": _getIcon("auto_stories"), "data": data,
        });
      }

      // 3. Videoları çek
      final vSnap = await FirebaseFirestore.instance.collection('videos').limit(5).get();
      List<Map<String, dynamic>> videoOnerileri = [];
      for (var d in vSnap.docs) {
        final data = d.data();
        videoOnerileri.add({
          "id": d.id, "tip": "VİDEO", "baslik": data['baslik'] ?? "Video",
          "altBaslik": data['altBaslik'] ?? "İzle ve öğren.",
          "renk": _hexToColor(data['renk'] ?? "0xFFE57373"), "ikon": _getIcon("play"), "data": data,
        });
      }

      List<Map<String, dynamic>> finalHavuz = [...senaryoOnerileri, ...hikayeOnerileri, ...videoOnerileri];
      finalHavuz.shuffle();

      if (mounted) {
        setState(() {
          _toplamGorevSayisi = toplamBolumler + toplamHikayeler;
          _kesifHavuzu = finalHavuz.take(4).toList();
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
    final paddingValue = size.width * 0.05;
    final String uid = _currentUser!.uid;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance.collection('usersProgress').doc(uid).snapshots(),
          builder: (context, snap) {
            int puan = 0;
            int tamamlananSayisi = 0;
            if (snap.hasData && snap.data!.exists) {
              final data = snap.data!.data() as Map<String, dynamic>;
              puan = data['toplam_puan'] ?? 0;
              List bitti = data['tamamlanan_bolumler'] as List? ?? [];
              List okundu = data['okunan_hikayeler'] as List? ?? [];
              tamamlananSayisi = bitti.length + okundu.length;
            }

            double ilerleme = _toplamGorevSayisi > 0 
                ? (tamamlananSayisi / _toplamGorevSayisi).clamp(0.0, 1.0) 
                : 0.0;

            return RefreshIndicator(
              onRefresh: _initData,
              child: CustomScrollView(
                slivers: [
                  _buildAppBar(_currentUser!.displayName ?? "Kahraman", paddingValue),
                  SliverToBoxAdapter(child: Padding(
                    padding: EdgeInsets.all(paddingValue),
                    child: _buildProgressCard(tamamlananSayisi, puan, ilerleme, size),
                  )),
                  _buildSectionTitle("Senin İçin Önerilenler", paddingValue),
                  _isLoading 
                    ? const SliverFillRemaining(child: Center(child: CircularProgressIndicator()))
                    : SliverPadding(
                        padding: EdgeInsets.symmetric(horizontal: paddingValue),
                        sliver: SliverList(delegate: SliverChildBuilderDelegate((c, i) => _buildModernContentCard(_kesifHavuzu[i], size), childCount: _kesifHavuzu.length)),
                      ),
                  const SliverToBoxAdapter(child: SizedBox(height: 100)),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildAppBar(String ad, double padding) {
    return SliverAppBar(
      floating: true, backgroundColor: Colors.transparent, elevation: 0, toolbarHeight: 80,
      title: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text("İyi günler,", style: TextStyle(color: Colors.blueGrey.shade400, fontSize: 13)),
          Text("$ad 👋", style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
        ]),
        GestureDetector(onTap: widget.onProfileTap, child: const CircleAvatar(radius: 25, backgroundImage: AssetImage("assets/boy.png"))),
      ]),
    );
  }

  Widget _buildProgressCard(int tamamlanan, int puan, double ilerleme, Size size) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.anaGradient,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [BoxShadow(color: AppColors.anaMavi.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text("GELİŞİM MERKEZİ", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10, letterSpacing: 1.2)),
            Text("$puan TP", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ]),
          const SizedBox(height: 15),
          Row(children: [
            Text("${(ilerleme * 100).toInt()}%", style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900)),
            const SizedBox(width: 15),
            Expanded(child: Text(_ilerlemeMesaji(ilerleme), style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600))),
          ]),
          const SizedBox(height: 15),
          LinearProgressIndicator(value: ilerleme, backgroundColor: Colors.white.withOpacity(0.2), valueColor: const AlwaysStoppedAnimation(Colors.white), minHeight: 8),
          const SizedBox(height: 10),
          Text("$tamamlanan / $_toplamGorevSayisi Görev Bitti", style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 11, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildModernContentCard(Map item, Size size) {
    final Color color = item['renk'];
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(25), boxShadow: [BoxShadow(color: color.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 5))]),
      child: ListTile(
        onTap: () => _route(item),
        leading: Container(width: 50, height: 50, decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(15)), child: Icon(item['ikon'], color: color)),
        title: Text(item['baslik'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        subtitle: Text(item['altBaslik'], style: const TextStyle(fontSize: 12)),
        trailing: const Icon(Icons.chevron_right_rounded),
      ),
    );
  }

  Widget _buildSectionTitle(String title, double padding) {
    return SliverToBoxAdapter(child: Padding(padding: EdgeInsets.all(padding), child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold))));
  }

  void _route(Map item) {
    final data = item['data'];
    if (item['tip'] == "SENARYO") {
      Navigator.push(context, MaterialPageRoute(builder: (_) => SenaryoDetayEkrani(docId: item['id'], bolumIndex: 0)));
    } else if (item['tip'] == "HİKAYE") {
      Navigator.push(context, MaterialPageRoute(builder: (_) => HikayeDetayEkrani(baslik: data['baslik'], gorselYolu: data['gorselYolu'], temaRengi: item['renk'], hikayeMetni: data['hikayeMetni'], feedbackMessage: data['feedbackMessage'])));
    } else if (item['tip'] == "VİDEO") {
      Navigator.push(context, MaterialPageRoute(builder: (_) => VideoDetayEkrani(baslik: data['baslik'], youtubeId: data['youtubeId'], tumVideolarJson: _kesifHavuzu)));
    }
  }
}
