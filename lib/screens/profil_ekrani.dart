import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:zorbalik_uygulamasi/app_theme.dart';
import 'package:zorbalik_uygulamasi/screens/karsilama_ekrani.dart';
import 'package:zorbalik_uygulamasi/admin_panel/admin_home.dart';
import 'package:zorbalik_uygulamasi/screens/siber_imdat_ekrani.dart';
import 'package:zorbalik_uygulamasi/admin_panel/admin_guard.dart';
import 'guvenlik_rehberi_ekrani.dart';
import 'hakkinda_ekrani.dart';
import 'gizlilik_politikasi_ekrani.dart';

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
  String _currentAvatar = "assets/boy.png";

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
      final doc = await FirebaseFirestore.instance.collection('users').doc(_user!.uid).get();
      if (doc.exists && mounted) {
        setState(() {
          _currentAvatar = doc.data()?['avatarUrl'] ?? "assets/boy.png";
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

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
            title: const Row(
              children: [
                Text("🎨", style: TextStyle(fontSize: 24)),
                SizedBox(width: 10),
                Text("Profilini Güncelle", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
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
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide(color: Colors.grey.shade300)),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text("Karakterini Seç", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.yaziRengi)),
                    const SizedBox(height: 12),
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        _avatarOption("assets/boy.png", tempAvatar, (path) => setDialogState(() => tempAvatar = path)),
                        _avatarOption("assets/girls-boy.png", tempAvatar, (path) => setDialogState(() => tempAvatar = path)),
                        _avatarOption("assets/superhero-man.png", tempAvatar, (path) => setDialogState(() => tempAvatar = path)),
                        _avatarOption("assets/superhero-girls.png", tempAvatar, (path) => setDialogState(() => tempAvatar = path)),
                      ],
                    ),
                  ],
                ),
                ),
                actions: [
                TextButton(
                onPressed: () => Navigator.pop(context),
        child: const Text("İptal", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
      ),
      ElevatedButton(
        onPressed: () async {
          if (nameController.text.trim().isNotEmpty) {
            try {
              await _user?.updateDisplayName(nameController.text.trim());
              await FirebaseFirestore.instance.collection('users').doc(_user?.uid).set({
                'kullaniciAdi': nameController.text.trim(),
                'avatarUrl': tempAvatar,
              }, SetOptions(merge: true));
              await _user?.reload();

              if (mounted) {
                setState(() {
                  _user = FirebaseAuth.instance.currentUser;
                  _currentAvatar = tempAvatar;
                });
                Navigator.pop(context);
                _showSnack("Bilgilerin başarıyla güncellendi! ✨");
              }
            } catch (e) {
              _showSnack("Güncellenirken bir hata oluştu.", isError: true);
            }
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.anaMavi,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        ),
        child: const Text("Kaydet", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      ],
    ),
    ),
    );
  }

  Widget _avatarOption(String path, String current, Function(String) onSelect) {
    bool isSelected = current == path;
    return GestureDetector(
      onTap: () => onSelect(path),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: isSelected ? AppColors.anaMavi : Colors.transparent, width: 3.5),
          boxShadow: isSelected ? [BoxShadow(color: AppColors.anaMavi.withOpacity(0.3), blurRadius: 8, spreadRadius: 2)] : [],
        ),
        child: CircleAvatar(
          radius: 28,
          backgroundColor: Colors.grey.shade100,
          backgroundImage: AssetImage(path),
        ),
      ),
    );
  }

  Future<void> _cikisYap() async {
    bool? onay = await _onayDiyalogu(
      emoji: "👋",
      baslik: "Görevden Ayrılıyorsun",
      icerik: "Kahramanlık görevine ara vermek mi istiyorsun?",
      butonMetni: "Evet, Çıkış Yap",
      renk: AppColors.anaMavi,
    );
    if (onay == true) {
      await FirebaseAuth.instance.signOut();
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const HomePages()), (route) => false);
    }
  }

  Future<void> _hesabiSil() async {
    if (_user == null) return;
    bool? onay = await _onayDiyalogu(
      emoji: "🥺",
      baslik: "Hesabı Kalıcı Olarak Sil",
      icerik: "Tüm rozetlerin, puanların ve ilerlemen silinecek. Bu işlem geri alınamaz!",
      butonMetni: "Evet, Hesabımı Sil",
      renk: Colors.redAccent,
    );
    if (onay == true) {
      setState(() => _isDeleting = true);
      try {
        final deleteFn = FirebaseFunctions.instanceFor(region: 'europe-west1').httpsCallable('deleteSelfAccount');
        await deleteFn.call();
        await FirebaseAuth.instance.signOut();
        if (!mounted) return;
        Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const HomePages()), (route) => false);
      } catch (e) {
        if (mounted) {
          setState(() => _isDeleting = false);
          _showSnack("Hata: Lütfen tekrar giriş yapıp tekrar deneyin.", isError: true);
        }
      }
    }
  }

  Future<Map<String, dynamic>> _getStats(String uid) async {
    try {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      bool admin = userDoc.exists ? (userDoc.data()?['isAdmin'] ?? false) : false;
      final sCountQuery = await FirebaseFirestore.instance.collection('scenarios').count().get();
      final hCountQuery = await FirebaseFirestore.instance.collection('stories').count().get();
      return {'isAdmin': admin, 'toplamGorev': (sCountQuery.count ?? 0) + (hCountQuery.count ?? 0)};
    } catch (e) {
      return {'isAdmin': false, 'toplamGorev': 1};
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_user == null) {
      return const Scaffold(body: Center(child: Text("Lütfen giriş yapın.")));
    }

    final size = MediaQuery.of(context).size;
    final String ekrandaGozukenIsim = _user!.displayName ?? widget.kullaniciAdi;

    return Scaffold(
      backgroundColor: AppColors.zemin,
      body: _isDeleting
          ? const Center(child: CircularProgressIndicator(color: AppColors.anaMavi))
          : StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('usersProgress').doc(_user!.uid).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator(color: AppColors.anaMavi));
          }

          final progressData = snapshot.data?.data() as Map<String, dynamic>? ?? {};
          final List bitti = progressData['tamamlanan_bolumler'] as List? ?? [];
          final List okundu = progressData['okunan_hikayeler'] as List? ?? [];
          final List rozetler = progressData['rozetler'] as List? ?? [];
          final int toplamPuan = progressData['toplam_puan'] ?? 0;
          final int tamamlananToplam = bitti.length + okundu.length;

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
                    const SizedBox(height: 55),
                    _buildMaceraKarti(ilerleme, size),
                    const SizedBox(height: 20),
                    _buildStatsRow(tamamlananToplam, rozetler.length, toplamPuan),
                    const SizedBox(height: 24),
                    if (isAdmin) ...[
                      _buildAdminBanner(),
                      const SizedBox(height: 16),
                    ],
                    _buildNotificationCard(),
                    const SizedBox(height: 24),
                    _buildBolumBasligi("MACERAN İÇİN ✨"),
                    const SizedBox(height: 12),
                    _buildActionGrid(size),
                    const SizedBox(height: 32),
                    _buildDangerZone(),
                    const SizedBox(height: 30),
                    _buildFooter(),
                    const SizedBox(height: 110),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildHeader(int seviye, String isim, Size size) {
    String rutbe() {
      if (seviye <= 1) return "Çaylak Koruyucu 🛡️";
      if (seviye <= 3) return "Dostluk Elçisi 🤝";
      if (seviye <= 6) return "Usta Muhafız ⚔️";
      return "Efsanevi Kahraman 👑";
    }

    return Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [
        Container(
          height: 200,
          width: double.infinity,
          decoration: const BoxDecoration(
            gradient: AppColors.anaGradient,
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(36)),
          ),
          child: SafeArea(
            child: Stack(
              children: [
                Positioned(top: 15, left: 24, child: Icon(Icons.star_rounded, color: Colors.white.withOpacity(0.3), size: 26)),
                Positioned(top: 35, right: 36, child: Icon(Icons.star_rounded, color: Colors.white.withOpacity(0.2), size: 18)),
                Positioned(
                  left: 20, right: 20, top: 15,
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Flexible(
                            child: Text(
                              isim.toUpperCase(),
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 1.1),
                            ),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: _profiliDuzenle,
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(color: Colors.white.withOpacity(0.25), shape: BoxShape.circle),
                              child: const Icon(Icons.edit_rounded, color: Colors.white, size: 14),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(rutbe(), style: TextStyle(color: Colors.white.withOpacity(0.9), fontWeight: FontWeight.bold, fontSize: 13)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        Positioned(
          bottom: -45,
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 16, offset: const Offset(0, 6))],
            ),
            child: CircleAvatar(radius: 60, backgroundColor: AppColors.zemin, backgroundImage: AssetImage(_currentAvatar)),
          ),
        ),
        Positioned(
          bottom: -52,
          right: size.width * 0.5 - 95,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.amber.shade700,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white, width: 2.5),
              boxShadow: [BoxShadow(color: Colors.amber.withOpacity(0.4), blurRadius: 8, offset: const Offset(0, 3))],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.bolt_rounded, color: Colors.white, size: 14),
                const SizedBox(width: 3),
                Text("SEVİYE $seviye", style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.white, fontSize: 11)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMaceraKarti(double ilerleme, Size size) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.grey.shade100),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Text("🗺️", style: TextStyle(fontSize: 16)),
                    SizedBox(width: 6),
                    Text("KAHRAMANLIK YOLU", style: TextStyle(fontWeight: FontWeight.w900, color: Colors.grey, fontSize: 11, letterSpacing: 1)),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: AppColors.anaMavi.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                  child: Text("%${(ilerleme * 100).toInt()}", style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.anaMavi, fontSize: 12)),
                ),
              ],
            ),
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: LinearProgressIndicator(
                value: ilerleme,
                backgroundColor: AppColors.anaMavi.withOpacity(0.1),
                valueColor: const AlwaysStoppedAnimation<Color>(AppColors.anaMavi),
                minHeight: 14,
              ),
            ),
            if (ilerleme < 1.0)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Text("Sıradaki seviye için harika ilerliyorsun! 💪", style: TextStyle(color: Colors.grey.shade500, fontSize: 11, fontWeight: FontWeight.bold)),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsRow(int gorev, int rozet, int puan) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          _buildStatCard("GÖREV", gorev.toString(), "🎯", Colors.orangeAccent),
          const SizedBox(width: 12),
          _buildStatCard("ROZET", rozet.toString(), "🏆", Colors.purpleAccent, onTap: widget.onRozetTap),
          const SizedBox(width: 12),
          _buildStatCard("PUAN", puan.toString(), "⭐", Colors.greenAccent),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, String emoji, Color color, {VoidCallback? onTap}) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: color.withOpacity(0.2)),
            boxShadow: [BoxShadow(color: color.withOpacity(0.08), blurRadius: 10, offset: const Offset(0, 4))],
          ),
          child: Column(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 22)),
              const SizedBox(height: 6),
              Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.yaziRengi)),
              const SizedBox(height: 2),
              Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.grey.shade400, letterSpacing: 0.5)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAdminBanner() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GestureDetector(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AdminGuard(child: const AdminHome()))),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Colors.blueGrey, Colors.indigo]),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(color: Colors.blueGrey.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 3))],
          ),
          child: const Row(
            children: [
              Icon(Icons.admin_panel_settings_rounded, color: Colors.white),
              SizedBox(width: 12),
              Expanded(child: Text("Yönetici Paneli", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14))),
              Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: Colors.grey.shade100),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: SwitchListTile(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
          secondary: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: AppColors.anaMavi.withOpacity(0.1), borderRadius: BorderRadius.circular(14)),
            child: const Icon(Icons.notifications_active_rounded, color: AppColors.anaMavi),
          ),
          title: const Text("Bildirimler", style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
          subtitle: const Text("Yeni görevlerden haberin olsun", style: TextStyle(fontSize: 11, color: Colors.grey)),
          value: _bildirimlerAcik,
          onChanged: (v) => setState(() => _bildirimlerAcik = v),
          activeColor: AppColors.anaMavi,
        ),
      ),
    );
  }

  Widget _buildBolumBasligi(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(text, style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.grey, fontSize: 11, letterSpacing: 1)),
      ),
    );
  }

  Widget _buildActionGrid(Size size) {
    final items = <_AksiyonOge>[
      _AksiyonOge(icon: Icons.sos_rounded, label: "Kahraman Hattı", color: Colors.redAccent, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SiberImdatEkrani()))),
      _AksiyonOge(icon: Icons.shield_rounded, label: "Rehberim", color: AppColors.anaMavi, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const GuvenlikRehberiEkrani()))),
      _AksiyonOge(icon: Icons.cake_rounded, label: "Yaş Grubu", color: Colors.orange, onTap: () => _showSnack("Yaş grubu güncelleme yakında aktif olacak! ✨")),
      _AksiyonOge(icon: Icons.info_rounded, label: "Hakkında", color: Colors.teal, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HakkindaEkrani()))),
      _AksiyonOge(icon: Icons.privacy_tip_rounded, label: "Gizlilik", color: Colors.indigo, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const GizlilikPolitikasiEkrani()))),
      _AksiyonOge(icon: Icons.alternate_email_rounded, label: "Bize Ulaşın", color: Colors.green, onTap: _bizeUlasin),
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Wrap(
        spacing: 12, runSpacing: 12,
        children: items.map((oge) {
          final double cardWidth = (size.width - 40 - 12) / 2;
          return SizedBox(width: cardWidth, child: _buildActionCard(oge));
        }).toList(),
      ),
    );
  }

  Widget _buildActionCard(_AksiyonOge oge) {
    return GestureDetector(
      onTap: oge.onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: oge.color.withOpacity(0.15)),
          boxShadow: [BoxShadow(color: oge.color.withOpacity(0.08), blurRadius: 8, offset: const Offset(0, 3))],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: oge.color.withOpacity(0.12), borderRadius: BorderRadius.circular(16)),
              child: Icon(oge.icon, color: oge.color, size: 24),
            ),
            const SizedBox(height: 10),
            Text(oge.label, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: AppColors.yaziRengi, height: 1.1)),
          ],
        ),
      ),
    );
  }

  Widget _buildDangerZone() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          GestureDetector(
            onTap: _cikisYap,
            child: Container(
              width: double.infinity,
              height: 54,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(colors: [AppColors.anaMavi, AppColors.anaMavi.withOpacity(0.8)]),
                boxShadow: [BoxShadow(color: AppColors.anaMavi.withOpacity(0.25), blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.logout_rounded, color: Colors.white, size: 18),
                  SizedBox(width: 8),
                  Text("OTURUMU KAPAT", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 1.1, fontSize: 13)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: _hesabiSil,
            child: const Text(
              "Hesabımı kalıcı olarak sil 🗑️",
              style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w800, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Column(
      children: [
        Text("Kahraman Dostum v1.0.0", style: TextStyle(color: Colors.grey.shade400, fontSize: 11, fontWeight: FontWeight.bold)),
        const SizedBox(height: 3),
        Text("TÜBİTAK Akran Zorbalığı Farkındalık Projesi", style: TextStyle(color: Colors.grey.shade400, fontSize: 9)),
      ],
    );
  }

  Future<void> _bizeUlasin() async {
    final String isim = _user?.displayName ?? widget.kullaniciAdi;
    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: 'siberkahramanapp@gmail.com',
      query: 'subject=Kahraman Dostum Geri Bildirim | $isim',
    );
    try {
      if (await canLaunchUrl(emailLaunchUri)) {
        await launchUrl(emailLaunchUri);
      } else if (mounted) {
        _showSnack("E-posta uygulaması bulunamadı.", isError: true);
      }
    } catch (e) {
      debugPrint("E-posta açılırken hata: $e");
    }
  }

  Future<bool?> _onayDiyalogu({required String emoji, required String baslik, required String icerik, required String butonMetni, required Color renk}) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        title: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 26)),
            const SizedBox(width: 10),
            Expanded(child: Text(baslik, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16))),
          ],
        ),
        content: Text(icerik, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13.5)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Vazgeç", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: renk,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              elevation: 0,
            ),
            child: Text(butonMetni, style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
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