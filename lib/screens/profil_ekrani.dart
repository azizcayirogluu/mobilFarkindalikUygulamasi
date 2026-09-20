import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:zorbalik_uygulamasi/app_theme.dart';
import 'package:zorbalik_uygulamasi/screens/karsilama_ekrani.dart';
import 'package:zorbalik_uygulamasi/admin_panel/admin_home.dart';
import 'package:zorbalik_uygulamasi/admin_panel/admin_guard.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'guvenlik_rehberi_ekrani.dart';
import 'hakkinda_ekrani.dart';
import 'gizlilik_politikasi_ekrani.dart';
import 'siber_imdat_ekrani.dart';
import 'package:zorbalik_uygulamasi/services/storage_service.dart';

class ProfilEkrani extends StatefulWidget {
  final String kullaniciAdi;
  final VoidCallback? onRozetTap;

  const ProfilEkrani({super.key, required this.kullaniciAdi, this.onRozetTap});

  @override
  State<ProfilEkrani> createState() => _ProfilEkraniState();
}

class _ProfilEkraniState extends State<ProfilEkrani> {
  bool _bildirimlerAcik = true;
  bool _isDeleting = false;
  User? _user;
  Future<Map<String, dynamic>>? _statsFuture;
  String _currentAvatar = "assets/image/boy.png";
  String _currentYasGrubu = "6-12";

  @override
  void initState() {
    super.initState();
    _user = FirebaseAuth.instance.currentUser;
    _verileriYukle();
    _statsFuture = _user != null
        ? _getStats(_user!.uid)
        : Future.value({'isAdmin': false, 'toplamGorev': 1});
  }

  Future<void> _verileriYukle() async {
    if (_user == null) return;
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(_user!.uid)
          .get();
      if (doc.exists && mounted) {
        String avatar = doc.data()?['avatarUrl'] ?? "assets/image/boy.png";
        if (avatar.startsWith("assets/") && !avatar.startsWith("assets/image/")) {
          avatar = avatar.replaceFirst("assets/", "assets/image/");
        }
        setState(() {
          _currentAvatar = avatar;
          _currentYasGrubu = doc.data()?['yasGrubu'] ?? "6-12";
        });
      }
    } catch (e) {
      debugPrint("Veri yüklenirken hata: $e");
    }
  }

  void _showSnack(String mesaj, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mesaj, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: isError ? Colors.redAccent : AppColors.anaMavi,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  Future<void> _profiliDuzenle() async {
    final TextEditingController nameController = TextEditingController(text: _user?.displayName ?? widget.kullaniciAdi);
    String tempAvatar = _currentAvatar;
    String tempYas = _currentYasGrubu;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
          title: const Row(
            children: [
              Text("🎨", style: TextStyle(fontSize: 24)),
              SizedBox(width: 10),
              Text("Kahramanını Güncelle", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: "Kahraman Adın",
                    prefixIcon: const Icon(Icons.badge_rounded, color: AppColors.anaMavi),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                  ),
                ),
                const SizedBox(height: 16),
                const Text("Yaş Grubun", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _yasSecenek("6-12", tempYas, (val) => setDialogState(() => tempYas = val)),
                    const SizedBox(width: 10),
                    _yasSecenek("13-18", tempYas, (val) => setDialogState(() => tempYas = val)),
                  ],
                ),
                const SizedBox(height: 20),
                const Text("Karakterini Seç", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 10),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 12, runSpacing: 12,
                  children: [
                    _avatarOption("assets/image/boy.png", tempAvatar, (path) => setDialogState(() => tempAvatar = path)),
                    _avatarOption("assets/image/girls-boy.png", tempAvatar, (path) => setDialogState(() => tempAvatar = path)),
                    _avatarOption("assets/image/superhero-man.png", tempAvatar, (path) => setDialogState(() => tempAvatar = path)),
                    _avatarOption("assets/image/superhero-girls.png", tempAvatar, (path) => setDialogState(() => tempAvatar = path)),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Vazgeç", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold))),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.trim().isNotEmpty) {
                  try {
                    await _user?.updateDisplayName(nameController.text.trim());
                    await FirebaseFirestore.instance.collection('users').doc(_user?.uid).set({
                      'kullaniciAdi': nameController.text.trim(),
                      'avatarUrl': tempAvatar,
                      'yasGrubu': tempYas,
                    }, SetOptions(merge: true));
                    await _user?.reload();
                    if (mounted) {
                      setState(() {
                        _user = FirebaseAuth.instance.currentUser;
                        _currentAvatar = tempAvatar;
                        _currentYasGrubu = tempYas;
                      });
                      Navigator.pop(context);
                      _showSnack("Harika! Kahramanın güncellendi. ✨");
                    }
                  } catch (e) { _showSnack("Bir hata oluştu.", isError: true); }
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.anaMavi, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
              child: const Text("Kaydet", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _yasSecenek(String label, String current, Function(String) onSelect) {
    bool isSelected = label == current;
    return Expanded(
      child: GestureDetector(
        onTap: () => onSelect(label),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.anaMavi : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: isSelected ? AppColors.anaMavi : Colors.grey.shade300),
          ),
          child: Text(label, textAlign: TextAlign.center, style: TextStyle(color: isSelected ? Colors.white : Colors.black87, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }

  Widget _avatarOption(String path, String current, Function(String) onSelect) {
    bool isSelected = current == path;
    return GestureDetector(
      onTap: () => onSelect(path),
      child: AnimatedContainer(
        duration: 200.ms,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: isSelected ? AppColors.anaMavi : Colors.transparent, width: 3)),
        child: CircleAvatar(radius: 28, backgroundImage: AssetImage(path)),
      ),
    );
  }

  Future<void> _cikisYap() async {
    bool? onay = await _onayDiyalogu(
      emoji: "👋",
      baslik: "Gidiyor musun?",
      icerik: "Kahramanlık görevine ara mı vermek istiyorsun? Seni özleyeceğiz!",
      butonMetni: "Evet, Dinleneceğim",
      renk: AppColors.anaMavi,
    );
    if (onay == true) {
      await FirebaseAuth.instance.signOut();
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const KarsilamaEkrani()), (route) => false);
    }
  }

  Future<void> _hesabiSil() async {
    if (_user == null) return;
    bool? onay = await _onayDiyalogu(emoji: "🥺", baslik: "Hesabı Kalıcı Sil", icerik: "Tüm rozetlerin ve ilerlemen silinecek. Bu işlem geri alınamaz!", butonMetni: "Evet, Hesabımı Sil", renk: Colors.redAccent);
    if (onay != true) return;
    setState(() => _isDeleting = true);
    try {
      final deleteFn = FirebaseFunctions.instanceFor(region: 'europe-west1').httpsCallable('deleteSelfAccount');
      await deleteFn.call();
      await FirebaseAuth.instance.signOut();
      await StorageService().clearUserData();
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const KarsilamaEkrani()), (route) => false);
    } catch (e) {
      if (mounted) {
        setState(() => _isDeleting = false);
        _showSnack("Hata oluştu. Lütfen tekrar dene.", isError: true);
      }
    }
  }

  Future<Map<String, dynamic>> _getStats(String uid) async {
    try {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      bool admin = userDoc.exists ? (userDoc.data()?['isAdmin'] ?? false) : false;
      final sCountQuery = await FirebaseFirestore.instance.collection('scenarios').count().get();
      final hCountQuery = await FirebaseFirestore.instance.collection('stories').count().get();
      final dCountQuery = await FirebaseFirestore.instance.collection('detective_questions').count().get();
      return {
        'isAdmin': admin,
        'toplamGorev': (sCountQuery.count ?? 0) + (hCountQuery.count ?? 0) + (dCountQuery.count ?? 0),
      };
    } catch (e) { return {'isAdmin': false, 'toplamGorev': 1}; }
  }

  @override
  Widget build(BuildContext context) {
    if (_user == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    final size = MediaQuery.of(context).size;
    final String ekrandaGozukenIsim = _user!.displayName ?? widget.kullaniciAdi;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFF),
        body: _isDeleting
            ? const Center(child: CircularProgressIndicator(color: AppColors.anaMavi))
            : StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance.collection('usersProgress').doc(_user!.uid).snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
  
                  final progressData = snapshot.data?.data() as Map<String, dynamic>? ?? {};
                  final List bitti = progressData['tamamlanan_bolumler'] as List? ?? [];
                  final List okundu = progressData['okunan_hikayeler'] as List? ?? [];
                  final List dedektif = progressData['bilinen_dedektif_sorulari'] as List? ?? [];
                  final List rozetler = progressData['rozetler'] as List? ?? [];
                  final int toplamPuan = progressData['toplam_puan'] ?? 0;
  
                  Set<String> tamamlananSenaryoIdleri = {};
                  for (var item in bitti) {
                    String s = item.toString();
                    if (s.contains('_')) { tamamlananSenaryoIdleri.add(s.split('_')[0]); } else { tamamlananSenaryoIdleri.add(s); }
                  }
                  final int tamamlananToplam = tamamlananSenaryoIdleri.length + okundu.length + dedektif.length;
  
                  return FutureBuilder<Map<String, dynamic>>(
                    future: _statsFuture,
                    builder: (context, statsSnap) {
                      final bool isAdmin = statsSnap.data?['isAdmin'] ?? false;
                      final int toplamGorev = statsSnap.data?['toplamGorev'] ?? 1;
                      final double ilerleme = (tamamlananToplam / toplamGorev).clamp(0.0, 1.0);
                      final int seviye = (tamamlananToplam ~/ 3) + 1;
  
                      return SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        child: Column(
                          children: [
                            _buildHeader(seviye, ekrandaGozukenIsim, size),
                            const SizedBox(height: 20),
                            _buildMaceraKarti(ilerleme, size).animate().fadeIn(duration: 300.ms).slideY(begin: 0.05, curve: Curves.easeOutQuad),
                            const SizedBox(height: 12),
                            _buildStatsRow(tamamlananToplam, rozetler.length, toplamPuan).animate(delay: 50.ms).fadeIn(duration: 300.ms).slideY(begin: 0.05),
                            const SizedBox(height: 16),
                            if (isAdmin) _buildAdminBanner().animate(delay: 100.ms).shimmer(),
                            const SizedBox(height: 6),
                            _buildNotificationCard().animate(delay: 150.ms).fadeIn(),
                            const SizedBox(height: 18),
                            _buildBolumBasligi("KAHRAMANLIK ARAÇLARI 🛠️"),
                            const SizedBox(height: 8),
                            _buildActionGrid(size).animate(delay: 200.ms).fadeIn().slideY(begin: 0.05),
                            const SizedBox(height: 24),
                            _buildDangerZoneZone().animate(delay: 200.ms).fadeIn(),
                            const SizedBox(height: 16),
                            _buildFooter(),
                            const SizedBox(height: 100),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
      )
    );
}

  Widget _buildHeader(int seviye, String isim, Size size) {
    String rutbe() {
      if (seviye <= 1) return "Acemi Muhafız 🛡️";
      if (seviye <= 3) return "Dostluk Elçisi 🤝";
      if (seviye <= 6) return "Gümüş Koruyucu ⚔️";
      return "Efsanevi Kahraman 👑";
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(bottom: 20),
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          // Arka Plan Dekoratif Baloncuklar
          _buildBlob(top: -50, left: -40, color: const Color(0xFFE0F2FE), size: 220),
          _buildBlob(top: -20, right: -60, color: const Color(0xFFF3E8FF), size: 180),

          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 10),
                Stack(
                  alignment: Alignment.bottomCenter,
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 25, offset: Offset(0, 10))]),
                      child: CircleAvatar(radius: 55, backgroundColor: const Color(0xFFF0F9FF), backgroundImage: AssetImage(_currentAvatar)),
                    ),
                    Positioned(
                      bottom: -10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.orange, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white, width: 3),
                          boxShadow: [BoxShadow(color: Colors.orange.withOpacity(0.4), blurRadius: 8)],
                        ),
                        child: Text("SEVİYE $seviye", style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.white, fontSize: 10)),
                      ),
                    ),
                  ],
                ).animate().scale(delay: 200.ms, curve: Curves.elasticOut, duration: 200.ms),
                const SizedBox(height: 18),
                Text(isim.toUpperCase(), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF1E293B), letterSpacing: 1.5)),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(color: const Color(0xFFF0F9FF), borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFFE0F2FE))),
                  child: Text(rutbe(), style: const TextStyle(color: Color(0xFF0284C7), fontWeight: FontWeight.bold, fontSize: 12)),
                ),
              ],
            ),
          ),
          Positioned(
            top: 50, right: 25,
            child: IconButton(
              icon: Container(padding: const EdgeInsets.all(8), decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)]), child: const Icon(Icons.settings_rounded, color: Colors.blueGrey, size: 20)),
              onPressed: _profiliDuzenle,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMaceraKarti(double ilerleme, Size size) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        width: double.infinity,
        height: 150, // Yükseklik azaltıldı
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(35),
          color: Colors.white.withOpacity(0.45),
          border: Border.all(color: Colors.white.withOpacity(0.6), width: 2),
          boxShadow: [BoxShadow(color: Colors.blue.withOpacity(0.08), blurRadius: 25, offset: const Offset(0, 10))],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(35),
          child: Stack(
            children: [
              _buildBlob(right: -20, top: -20, color: Colors.blue.shade100, size: 100),
              _buildBlob(left: -30, bottom: -40, color: Colors.purple.shade100, size: 120),
              Padding(
                padding: const EdgeInsets.all(22),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("KAHRAMANLIK YOLU 🗺️", style: TextStyle(fontWeight: FontWeight.w900, color: Colors.indigo, fontSize: 10, letterSpacing: 1.5)),
                        Text("%${(ilerleme * 100).toInt()}", style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.indigo, fontSize: 14)),
                      ],
                    ),
                    const SizedBox(height: 18),
                    _buildLinearProgress(ilerleme),
                    const SizedBox(height: 12),
                    Text("Harika ilerliyorsun, süper kahraman! 🚀", style: TextStyle(color: Colors.indigo.shade700, fontSize: 12, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBlob({double? top, double? bottom, double? left, double? right, required Color color, required double size}) {
    return Positioned(
      top: top, bottom: bottom, left: left, right: right,
      child: Container(width: size, height: size, decoration: BoxDecoration(shape: BoxShape.circle, color: color.withOpacity(0.4))),
    );
  }

  Widget _buildLinearProgress(double value) {
    final safeValue = value.clamp(0.0, 1.0);
    return Container(
      height: 12, width: double.infinity, clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.6), borderRadius: BorderRadius.circular(20)),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final progressWidth = constraints.maxWidth * safeValue;
          return Align(
            alignment: Alignment.centerLeft,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300), curve: Curves.easeOutCubic,
              height: 12, width: progressWidth.clamp(0.0, constraints.maxWidth),
              decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)]), borderRadius: BorderRadius.circular(20)),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatsRow(int gorev, int rozet, int puan) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          _statCard("GÖREV", gorev.toString(), Icons.track_changes_rounded, Colors.orange),
          const SizedBox(width: 15),
          _statCard("ROZET", rozet.toString(), Icons.emoji_events_rounded, Colors.purple),
          const SizedBox(width: 15),
          _statCard("PUAN", puan.toString(), Icons.stars_rounded, Colors.teal),
        ],
      ),
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(25),
          boxShadow: [BoxShadow(color: color.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 5))],
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 6),
            Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF2D3142))),
            Text(label, style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.grey.shade400)),
          ],
        ),
      ),
    );
  }

  Widget _buildAdminBanner() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: InkWell(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AdminGuard(child: const AdminHome()))),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF232526), Color(0xFF414345)]), borderRadius: BorderRadius.circular(20)),
          child: const Row(
            children: [
              Icon(Icons.admin_panel_settings_rounded, color: Colors.amber, size: 28),
              SizedBox(width: 15),
              Expanded(child: Text("YÖNETİCİ PANELİ", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 1))),
              Icon(Icons.arrow_forward_ios_rounded, color: Colors.white54, size: 14),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(25)),
        child: SwitchListTile.adaptive(
          value: _bildirimlerAcik,
          onChanged: (v) => setState(() => _bildirimlerAcik = v),
          title: const Text("Bildirimler", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
          secondary: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.blue.shade50, shape: BoxShape.circle), child: const Icon(Icons.notifications_active, color: Colors.blue, size: 20)),
          activeColor: Colors.blue,
        ),
      ),
    );
  }

  Widget _buildBolumBasligi(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 30, bottom: 12),
      child: Align(alignment: Alignment.centerLeft, child: Text(text, style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.blueGrey, fontSize: 11, letterSpacing: 1.2))),
    );
  }

  Widget _buildActionGrid(Size size) {
    final items = [
      _AksiyonOge(icon: Icons.emergency_share_rounded, label: "Siber İmdat", color: Colors.redAccent, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SiberImdatEkrani()))),
      _AksiyonOge(icon: Icons.shield_rounded, label: "Rehberim", color: Colors.blue, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const GuvenlikRehberiEkrani()))),
      _AksiyonOge(icon: Icons.info_rounded, label: "Hakkımızda", color: Colors.teal, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HakkindaEkrani()))),
      _AksiyonOge(icon: Icons.privacy_tip_rounded, label: "Gizlilik", color: Colors.indigo, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const GizlilikPolitikasiEkrani()))),
      _AksiyonOge(icon: Icons.email_rounded, label: "Bize Ulaşın", color: Colors.green, onTap: _bizeUlasin),
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 15, mainAxisSpacing: 15, childAspectRatio: 1.8),
        itemCount: items.length,
        itemBuilder: (context, index) => _toolCard(items[index]),
      ),
    );
  }

  Widget _toolCard(_AksiyonOge oge) {
    return InkWell(
      onTap: oge.onTap, borderRadius: BorderRadius.circular(25),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(25)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: oge.color.withOpacity(0.1), shape: BoxShape.circle), child: Icon(oge.icon, color: oge.color, size: 22)),
            const SizedBox(height: 8),
            Text(oge.label, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12, color: Color(0xFF2D3142))),
          ],
        ),
      ),
    );
  }

  Widget _buildDangerZoneZone() {
    return Column(
      children: [
        ElevatedButton(
          onPressed: _cikisYap,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white, foregroundColor: Colors.blue, elevation: 0,
            minimumSize: const Size(200, 50), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15), side: BorderSide(color: Colors.blue.shade100)),
          ),
          child: const Text("OTURUMU KAPAT", style: TextStyle(fontWeight: FontWeight.w900)),
        ),
        const SizedBox(height: 10),
        TextButton(onPressed: _hesabiSil, child: const Text("Hesabı Kalıcı Olarak Sil 🗑️", style: TextStyle(color: Colors.redAccent, fontSize: 13, fontWeight: FontWeight.bold))),
      ],
    );
  }

  Widget _buildFooter() {
    return Column(
      children: [
        Text("Kahraman Dostum v1.2.0", style: TextStyle(color: Colors.grey.shade400, fontSize: 11, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        const Text("TÜBİTAK Akran Zorbalığı Farkındalık Projesi", style: TextStyle(color: Colors.grey, fontSize: 9)),
      ],
    );
  }

  Future<void> _bizeUlasin() async {
    final String isim = _user?.displayName ?? widget.kullaniciAdi;
    final Uri emailLaunchUri = Uri(scheme: 'mailto', path: 'siberkahramanapp@gmail.com', query: 'subject=Kahraman Geri Bildirim | $isim');
    try { if (await canLaunchUrl(emailLaunchUri)) await launchUrl(emailLaunchUri); } catch (e) { debugPrint(e.toString()); }
  }

  Future<bool?> _onayDiyalogu({required String emoji, required String baslik, required String icerik, required String butonMetni, required Color renk}) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        title: Text("$emoji $baslik", style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
        content: Text(icerik),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Vazgeç")),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), style: ElevatedButton.styleFrom(backgroundColor: renk), child: Text(butonMetni, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }
}

class _AksiyonOge {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  _AksiyonOge({required this.icon, required this.label, required this.color, required this.onTap});
}
