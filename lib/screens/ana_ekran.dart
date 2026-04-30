import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:zorbalik_uygulamasi/app_theme.dart';
import 'package:zorbalik_uygulamasi/screens/senaryo_detay_ekrani.dart';
import 'package:zorbalik_uygulamasi/screens/hikaye_detay_ekrani.dart';
import 'package:zorbalik_uygulamasi/screens/video_detay_ekrani.dart';
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
      case 'psychology': return Icons.psychology_alt_rounded;
      case 'auto_stories': return Icons.auto_stories_rounded;
      case 'play': return Icons.play_circle_filled_rounded;
      default: return Icons.stars_rounded;
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
          List<Map<String, dynamic>> rawHavuz = List<Map<String, dynamic>>.from(data['kesifHavuzu']);
          
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
          const SnackBar(content: Text("İçerikler yüklenirken bir hata oluştu.")),
        );
      }
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
      body: Stack(
        children: [
          // Dekoratif Arka Plan Daireleri
          Positioned(top: -50, right: -50, child: Container(width: 200, height: 200, decoration: BoxDecoration(color: AppColors.anaMavi.withOpacity(0.05), shape: BoxShape.circle))),
          Positioned(bottom: 100, left: -80, child: Container(width: 250, height: 250, decoration: BoxDecoration(color: Colors.orange.withOpacity(0.03), shape: BoxShape.circle))),
          
          SafeArea(
            child: StreamBuilder<DocumentSnapshot>(
              stream: _contentService.getUserProgressStream(uid),
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
                  color: AppColors.anaMavi,
                  child: CustomScrollView(
                    physics: const BouncingScrollPhysics(),
                    slivers: [
                      _buildAppBar(_currentUser!.displayName ?? "Kahraman", paddingValue),
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(paddingValue, 10, paddingValue, 20),
                          child: _buildProgressCard(tamamlananSayisi, puan, ilerleme, size),
                        ),
                      ),
                      _buildSectionTitle("Günün Keşifleri 🚀", paddingValue),
                      _isLoading 
                        ? const SliverFillRemaining(child: Center(child: CircularProgressIndicator()))
                        : SliverPadding(
                            padding: EdgeInsets.symmetric(horizontal: paddingValue),
                            sliver: SliverList(
                              delegate: SliverChildBuilderDelegate(
                                (c, i) => _buildModernContentCard(_kesifHavuzu[i], size).animate().fadeIn(delay: (i * 100).ms).slideX(begin: 0.1), 
                                childCount: _kesifHavuzu.length
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
      floating: true, backgroundColor: Colors.transparent, elevation: 0, toolbarHeight: 90,
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text("Hoş geldin,", style: TextStyle(color: Colors.blueGrey.shade400, fontSize: 14, fontWeight: FontWeight.w500)),
              Text(ad, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Color(0xFF0F172A), letterSpacing: -0.5)),
            ]),
          ),
          Hero(
            tag: 'profile_avatar',
            child: GestureDetector(
              onTap: widget.onProfileTap,
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(shape: BoxShape.circle, gradient: AppColors.anaGradient),
                child: const CircleAvatar(radius: 28, backgroundColor: Colors.white, backgroundImage: AssetImage("assets/boy.png")),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressCard(int tamamlanan, int puan, double ilerleme, Size size) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(35),
        gradient: AppColors.anaGradient,
        boxShadow: [
          BoxShadow(
            color: AppColors.anaMavi.withOpacity(0.3),
            blurRadius: 25,
            offset: const Offset(0, 10),
          )
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(35),
        child: Stack(
          children: [
            Positioned.fill(
              child: Opacity(
                opacity: 0.15,
                child: Image.asset(
                  'assets/isilti.jpg',
                  fit: BoxFit.cover,
                ),
              ),
            ),
            Positioned(
              right: -30,
              top: -30,
              child: Icon(
                Icons.shield_rounded,
                size: 150,
                color: Colors.white.withOpacity(0.1),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(25),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          "GELİŞİM MERKEZİ",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 10,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          const Icon(Icons.stars_rounded, color: Colors.amber, size: 20),
                          const SizedBox(width: 5),
                          Text(
                            "$puan TP",
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 25),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        "${(ilerleme * 100).toInt()}%",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 48,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -2,
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: Text(
                            _ilerlemeMesaji(ilerleme),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              height: 1.2,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Stack(
                    children: [
                      Container(
                        height: 12,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      AnimatedContainer(
                        duration: const Duration(seconds: 1),
                        height: 12,
                        // Buradaki padding hesaplaması (90) tasarıma göre değişebilir,
                        // LayoutBuilder kullanmak daha sağlıklı olabilir.
                        width: (size.width - 90) * ilerleme,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Colors.white, Color(0xFFB3E5FC)],
                          ),
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.white.withOpacity(0.5),
                              blurRadius: 5,
                            )
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "$tamamlanan / $_toplamGorevSayisi Görev Tamamlandı",
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
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

  Widget _buildModernContentCard(Map item, Size size) {
    final Color color = item['renk'];
    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [BoxShadow(color: color.withOpacity(0.08), blurRadius: 20, offset: const Offset(0, 8))],
      ),
      child: InkWell(
        onTap: () => _route(item),
        borderRadius: BorderRadius.circular(30),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 70, height: 70,
                decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(22)),
                child: Icon(item['ikon'], color: color, size: 32),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                      child: Text(item['tip'], style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 9, letterSpacing: 0.5)),
                    ),
                    const SizedBox(height: 4),
                    Text(item['baslik'], style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: AppColors.yaziRengi, letterSpacing: -0.2)),
                    Text(item['altBaslik'], style: TextStyle(fontSize: 12, color: Colors.blueGrey.shade300, fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios_rounded, color: Colors.blueGrey.shade100, size: 16),
              const SizedBox(width: 5),
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
        child: Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF1E293B), letterSpacing: -0.5)),
      ),
    );
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
