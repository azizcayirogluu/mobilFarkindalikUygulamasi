import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:zorbalik_uygulamasi/app_theme.dart';
import 'package:zorbalik_uygulamasi/screens/senaryo_detay_ekrani.dart';
import 'package:zorbalik_uygulamasi/screens/hikaye_detay_ekrani.dart';
import 'package:zorbalik_uygulamasi/screens/video_detay_ekrani.dart';
import 'package:zorbalik_uygulamasi/screens/siber_dedektif_oyunu.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:zorbalik_uygulamasi/services/content_service.dart';

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
  int _toplamGorevSayisi = 0;

  final User? _currentUser = FirebaseAuth.instance.currentUser;
  final ContentService _contentService = ContentService();

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
      case 'psychology':
        return Icons.psychology_alt_rounded;
      case 'auto_stories':
        return Icons.auto_stories_rounded;
      case 'play':
        return Icons.play_circle_filled_rounded;
      case 'search':
        return Icons.search_rounded;
      default:
        return Icons.stars_rounded;
    }
  }

  String _ilerlemeMesaji(double ilerleme) {
    int yuzde = (ilerleme * 100).toInt();
    if (yuzde == 0) return "Maceraya atılmaya hazır mısın?";
    if (yuzde < 40) return "Harika bir başlangıç yapıyorsun! 🌟";
    if (yuzde < 80) return "Gerçek bir siber koruyucu oluyorsun! 🛡️";
    return "Neredeyse efsanevi bir kahramansın! 🔥";
  }

  Future<void> _initData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final data = await _contentService.fetchDiscoveryData();

      if (mounted) {
        setState(() {
          _toplamGorevSayisi = data['toplamGorevSayisi'];
          List<Map<String, dynamic>> rawHavuz = List<Map<String, dynamic>>.from(
            data['kesifHavuzu'],
          );
          _kesifHavuzu = rawHavuz.map((item) {
            item['renk'] = _hexToColor(item['renkStr']);
            item['ikon'] = _getIcon(item['ikonStr']);
            return item;
          }).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Veri yükleme hatası (AnaSayfa): $e");
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("İçerikler yüklenirken bir hata oluştu."),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_currentUser == null)
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    final size = MediaQuery.of(context).size;
    final paddingValue = size.width * 0.05;
    final String uid = _currentUser.uid;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(uid)
              .snapshots(),
          builder: (context, userSnap) {
            String aktifAd = widget.kullaniciAdi;
            String aktifAvatar = "assets/image/boy.png";

            if (userSnap.hasData && userSnap.data!.exists) {
              final uData = userSnap.data!.data() as Map<String, dynamic>;
              aktifAd = uData['kullaniciAdi'] ?? aktifAd;
              String? dbAvatar = uData['avatarUrl'];
              if (dbAvatar != null && dbAvatar.isNotEmpty) {
                // GÜVENLİK: Eğer path yanlışsa (image/ eksikse) otomatik düzelt
                if (dbAvatar.startsWith("assets/") &&
                    !dbAvatar.startsWith("assets/image/")) {
                  aktifAvatar = dbAvatar.replaceFirst(
                    "assets/",
                    "assets/image/",
                  );
                } else {
                  aktifAvatar = dbAvatar;
                }
              }
            }

            return StreamBuilder<DocumentSnapshot>(
              stream: _contentService.getUserProgressStream(uid),
              builder: (context, snap) {
                int puan = 0;
                int tamamlananSayisi = 0;
                if (snap.hasData && snap.data!.exists) {
                  final data = snap.data!.data() as Map<String, dynamic>;
                  puan = data['toplam_puan'] ?? 0;
                  List bitti = data['tamamlanan_bolumler'] as List? ?? [];
                  List okundu = data['okunan_hikayeler'] as List? ?? [];
                  List dedektif =
                      data['bilinen_dedektif_sorulari'] as List? ?? [];

                  // ÇÖZÜM: Senaryo ID'lerini güvenli şekilde ayır ve SET yap
                  Set<String> tamamlananSenaryoIdleri = {};
                  for (var item in bitti) {
                    String s = item.toString();
                    if (s.contains('_')) {
                      tamamlananSenaryoIdleri.add(s.split('_')[0]);
                    } else {
                      tamamlananSenaryoIdleri.add(s);
                    }
                  }

                  tamamlananSayisi =
                      tamamlananSenaryoIdleri.length +
                      okundu.length +
                      dedektif.length;
                }
                double ilerleme = _toplamGorevSayisi > 0
                    ? (tamamlananSayisi / _toplamGorevSayisi).clamp(0.0, 1.0)
                    : 0.0;

                return RefreshIndicator(
                  onRefresh: _initData,
                  color: AppColors.anaMavi,
                  child: CustomScrollView(
                    physics: const BouncingScrollPhysics(),
                    slivers: [
                      _buildAppBar(aktifAd, aktifAvatar, paddingValue),
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(
                            paddingValue,
                            10,
                            paddingValue,
                            20,
                          ),
                          child: _buildProgressCard(
                            tamamlananSayisi,
                            puan,
                            ilerleme,
                          ),
                        ),
                      ),
                      _buildSectionTitle("Günün Önerileri 🚀🎓", paddingValue),
                      _isLoading
                          ? const SliverFillRemaining(
                              child: Center(child: CircularProgressIndicator()),
                            )
                          : SliverPadding(
                              padding: EdgeInsets.symmetric(
                                horizontal: paddingValue,
                              ),
                              sliver: SliverList(
                                delegate: SliverChildBuilderDelegate(
                                  (c, i) =>
                                      _buildModernContentCard(
                                            _kesifHavuzu[i],
                                          )
                                          .animate(delay: (i * 30).ms)
                                          .fadeIn(duration: 300.ms)
                                          .slideY(
                                            begin: 0.05,
                                            curve: Curves.easeOutQuad,
                                          ),
                                  childCount: _kesifHavuzu.length,
                                ),
                              ),
                            ),
                      const SliverToBoxAdapter(child: SizedBox(height: 120)),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildAppBar(String ad, String avatarPath, double padding) {
    return SliverAppBar(
      floating: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      toolbarHeight: 90, // AppBar yüksekliği artırıldı
      titleSpacing: 0,
      title: Padding(
        padding: EdgeInsets.fromLTRB(padding, 20, padding, 8), // Üstten boşluk eklendi
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "KAHRAMAN GÜNLÜĞÜ 🧾",
                    style: TextStyle(
                      color: Colors.indigo.shade300,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    "Selam, $ad! ✨",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.indigo.shade900,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: widget.onProfileTap,
              child: Hero(
                tag: 'profile_avatar',
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.indigo.withOpacity(0.1),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                    border: Border.all(color: Colors.indigo.shade50, width: 2),
                  ),
                  child: CircleAvatar(
                    radius: 28,
                    backgroundColor: Colors.white,
                    backgroundImage: AssetImage(avatarPath),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressCard(
    int tamamlanan,
    int puan,
    double ilerleme,
  ) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 160),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(35),
        color: Colors.white.withOpacity(0.45),
        border: Border.all(color: Colors.white.withOpacity(0.6), width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.purple.withOpacity(0.08),
            blurRadius: 25,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(35),
        child: Stack(
          children: [
            _buildBlob(
              right: -20,
              top: -20,
              color: Colors.pink.shade100,
              size: 120,
            ),
            _buildBlob(
              left: -30,
              bottom: -40,
              color: Colors.yellow.shade100,
              size: 140,
            ),
            _buildBlob(
              right: 40,
              bottom: -20,
              color: Colors.blue.shade100,
              size: 80,
            ),

            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 22,
                vertical: 18,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 15,
                    runSpacing: 10,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.8),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.orange.withOpacity(0.2),
                                  blurRadius: 8,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.auto_awesome,
                              color: Colors.orangeAccent,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 15),
                          Flexible(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  "MACERA SEVİYESİ",
                                  style: TextStyle(
                                    color: Colors.indigo.shade900.withOpacity(
                                      0.5,
                                    ),
                                    fontSize: 10,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1.5,
                                  ),
                                ),
                                Text(
                                  "${(ilerleme * 100).toInt()}% Tamamlandı! ✨",
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: Colors.indigo.shade900,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      _buildPointBadge(puan),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildLinearProgress(ilerleme),
                  const SizedBox(height: 10),
                  Text(
                    _ilerlemeMesaji(ilerleme),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.indigo.shade700,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBlob({
    double? top,
    double? bottom,
    double? left,
    double? right,
    required Color color,
    required double size,
  }) {
    return Positioned(
      top: top,
      bottom: bottom,
      left: left,
      right: right,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withOpacity(0.5),
        ),
      ),
    );
  }

  Widget _buildPointBadge(int puan) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.indigo.shade900,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.indigo.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.stars, color: Colors.amber, size: 16),
          const SizedBox(width: 6),
          Text(
            "$puan",
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLinearProgress(double value) {
    return Container(
      height: 14,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.6),
        borderRadius: BorderRadius.circular(20),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Stack(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 800),
                curve: Curves.elasticOut,
                height: 14,
                width: constraints.maxWidth * value.clamp(0.0, 1.0),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF818CF8), Color(0xFFC084FC)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildModernContentCard(Map item,) {
    final Color color = item['renk'];
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withOpacity(0.1), width: 1.5),
      ),
      child: InkWell(
        onTap: () => _route(item),
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(item['ikon'], color: color, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      item['tip'],
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.w900,
                        fontSize: 10,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item['baslik'],
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                        color: Color(0xFF1E293B),
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item['tip'] == "HİKAYE"
                          ? (item['data']['feedbackMessage'] != null &&
                                    item['data']['feedbackMessage']
                                        .toString()
                                        .isNotEmpty
                                ? item['data']['feedbackMessage']
                                : "Kahramanlık yolunda yeni bir öykü! ✨")
                          : item['altBaslik'],
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blueGrey.shade300,
                        fontWeight: FontWeight.w500,
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.arrow_forward_ios_rounded,
                color: color.withOpacity(0.2),
                size: 14,
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
        padding: EdgeInsets.fromLTRB(padding, 20, padding, 15),
        child: Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: Color(0xFF1E293B),
            letterSpacing: -0.5,
          ),
        ),
      ),
    );
  }

  Future<void> _route(Map item) async {
    final data = item['data'];
    if (item['tip'] == "SENARYO") {
      final docId = (item['id'] ?? '').toString().trim();
      if (docId.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Bu öneri artık geçersiz. Liste yenileniyor..."),
          ),
        );
        await _initData();
        return;
      }

      try {
        final doc = await FirebaseFirestore.instance
            .collection('scenarios')
            .doc(docId)
            .get();
        if (!doc.exists) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                "Bu senaryo artık mevcut değil. Diğer önerilere bakıyoruz...",
              ),
            ),
          );
          await _initData();
          return;
        }
      } catch (_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Senaryo bilgisi yüklenirken bir sorun oluştu."),
          ),
        );
        return;
      }

      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => SenaryoDetayEkrani(docId: docId, bolumIndex: 0),
        ),
      );
      return;
    } else if (item['tip'] == "HİKAYE") {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => HikayeDetayEkrani(
            baslik: data['baslik'],
            gorselYolu: data['gorselYolu'],
            temaRengi: item['renk'],
            hikayeMetni: data['hikayeMetni'],
            feedbackMessage: data['feedbackMessage'],
          ),
        ),
      );
    } else if (item['tip'] == "VİDEO") {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => VideoDetayEkrani(
            baslik: data['baslik'],
            youtubeId: data['youtubeId'],
            tumVideolarJson: _kesifHavuzu,
          ),
        ),
      );
    } else if (item['tip'] == "SİBER DEDEKTİF") {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const SiberDedektifOyunu(),
        ),
      );
    }
  }
}
