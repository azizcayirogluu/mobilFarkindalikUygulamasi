import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_custom_clippers/flutter_custom_clippers.dart';
import 'package:zorbalik_uygulamasi/app_theme.dart';
import 'package:zorbalik_uygulamasi/screens/karsilama_ekrani.dart';
import 'package:zorbalik_uygulamasi/admin_panel/admin_home.dart';

class ProfilEkrani extends StatefulWidget {
  final String kullaniciAdi;
  final VoidCallback? onRozetTap;

  const ProfilEkrani({
    super.key,
    required this.kullaniciAdi,
    this.onRozetTap,
  });

  @override
  State<ProfilEkrani> createState() => _ProfilEkraniState();
}

class _ProfilEkraniState extends State<ProfilEkrani> {
  bool bildirimlerAcik = true;
  bool _isDeleting = false;
  final User? _currentUser = FirebaseAuth.instance.currentUser;

  Future<void> _cikisYap() async {
    bool? onay = await _onayDiyalogu(
        "Oturumu Kapat",
        "Kahramanlık görevine ara vermek mi istiyorsun? 👋",
        "Evet, Çıkış Yap",
        AppColors.anaMavi
    );
    if (onay == true) {
      await FirebaseAuth.instance.signOut();
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const HomePages()),
              (route) => false
      );
    }
  }

  Future<void> _hesabiSil() async {
    if (_currentUser == null) return;
    
    bool? onay = await _onayDiyalogu(
        "Hesabı Kalıcı Sil",
        "Tüm başarın ve rozetlerin silinecek. Bu işlem geri alınamaz! 😢",
        "Evet, Hesabımı Sil",
        Colors.redAccent
    );
    if (onay == true) {
      setState(() => _isDeleting = true);
      try {
        final String uid = _currentUser!.uid;

        final messages = await FirebaseFirestore.instance
            .collection('usersProgress')
            .doc(uid)
            .collection('messages')
            .get();
        
        WriteBatch batch = FirebaseFirestore.instance.batch();
        for (var doc in messages.docs) {
          batch.delete(doc.reference);
        }
        await batch.commit();

        await FirebaseFirestore.instance.collection('users').doc(uid).delete();
        await FirebaseFirestore.instance.collection('usersProgress').doc(uid).delete();

        await _currentUser!.delete();
        
        if (!mounted) return;
        Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const HomePages()),
                (route) => false
        );
      } catch (e) {
        debugPrint("Hesap silme hatası: $e");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Hata: Lütfen tekrar giriş yapıp deneyin."))
          );
        }
      } finally {
        if (mounted) setState(() => _isDeleting = false);
      }
    }
  }

  Future<bool?> _onayDiyalogu(String baslik, String icerik, String butonMetni, Color renk) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        title: Text(baslik, style: const TextStyle(fontWeight: FontWeight.w900)),
        content: Text(icerik),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("Vazgeç", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold))
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: renk,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              elevation: 0,
            ),
            child: Text(butonMetni, style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_currentUser == null) return const Scaffold(body: Center(child: Text("Giriş yapmalısın.")));
    final size = MediaQuery.of(context).size;
    final String uid = _currentUser!.uid;
    final String ekrandaGozukenIsim = _currentUser!.displayName ?? widget.kullaniciAdi;

    return Scaffold(
      backgroundColor: AppColors.zemin,
      body: _isDeleting
          ? const Center(child: CircularProgressIndicator())
          : StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('usersProgress').doc(uid).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());

          var progressData = snapshot.data?.data() as Map<String, dynamic>? ?? {};
          List tamamlananlar = progressData['tamamlanan_bolumler'] ?? [];
          List rozetler = progressData['rozetler'] ?? [];
          int toplamPuan = progressData['toplam_puan'] ?? 0;

          return FutureBuilder<DocumentSnapshot>(
            future: FirebaseFirestore.instance.collection('users').doc(uid).get(),
            builder: (context, userSnap) {
              bool isAdmin = false;
              if (userSnap.hasData && userSnap.data!.exists) {
                isAdmin = (userSnap.data!.data() as Map<String, dynamic>)['isAdmin'] ?? false;
              }

              return FutureBuilder<QuerySnapshot>(
                future: FirebaseFirestore.instance.collection('scenarios').get(),
                builder: (context, scenarioSnap) {
                  int toplamBolumSayisi = 0;
                  if (scenarioSnap.hasData) {
                    for (var doc in scenarioSnap.data!.docs) {
                      toplamBolumSayisi += ((doc.data() as Map)['bolumler'] as List? ?? []).length;
                    }
                  }

                  double ilerleme = toplamBolumSayisi > 0
                      ? (tamamlananlar.length / toplamBolumSayisi).clamp(0.0, 1.0)
                      : 0.0;

                  int seviye = (tamamlananlar.length ~/ 3) + 1;

                  return SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      children: [
                        _buildHeader(seviye, size),
                        const SizedBox(height: 60),
                        _buildProfileInfo(ekrandaGozukenIsim, ilerleme, size),
                        const SizedBox(height: 40),
                        _buildStatsGrid(tamamlananlar.length, rozetler.length, toplamPuan, size),
                        const SizedBox(height: 40),
                        _buildSettingsList(size, isAdmin),
                        const SizedBox(height: 40),
                        _buildDangerZone(size),
                        const SizedBox(height: 120),
                      ],
                    ),
                  );
                },
              );
            }
          );
        },
      ),
    );
  }

  Widget _buildHeader(int seviye, Size size) {
    double headerHeight = size.height * 0.22;
    if (headerHeight < 180) headerHeight = 180;

    return Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [
        ClipPath(
          clipper: WaveClipperTwo(),
          child: Container(
            height: headerHeight,
            width: double.infinity,
            decoration: const BoxDecoration(gradient: AppColors.anaGradient),
            child: Center(
              child: Icon(Icons.shield_rounded, size: headerHeight * 0.5, color: Colors.white.withOpacity(0.1)),
            ),
          ),
        ),
        Positioned(
          bottom: -50,
          child: Hero(
            tag: 'profil_avatar',
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 25, offset: Offset(0, 10))]
              ),
              child: CircleAvatar(
                  radius: size.width * 0.16,
                  backgroundColor: AppColors.zemin,
                  backgroundImage: const AssetImage("assets/boy.png")
              ),
            ),
          ),
        ),
        Positioned(
          bottom: -55,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
            decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Colors.amber, Colors.orange]),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white, width: 3),
                boxShadow: [BoxShadow(color: Colors.orange.withOpacity(0.3), blurRadius: 10)]
            ),
            child: Text(
                "SEVİYE $seviye",
                style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.white, fontSize: 13, letterSpacing: 1)
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProfileInfo(String isim, double ilerleme, Size size) {
    String rutbe() {
      if (ilerleme <= 0.2) return "Çaylak Koruyucu 🛡️";
      if (ilerleme <= 0.5) return "Siber Devriye 🚔";
      if (ilerleme <= 0.8) return "Usta Muhafız ⚔️";
      return "Efsanevi Kahraman 👑";
    }

    return Column(
      children: [
        Text(
            isim.toLowerCase(),
            style: TextStyle(
                fontSize: size.width > 600 ? 32 : 28,
                fontWeight: FontWeight.w900,
                color: AppColors.yaziRengi,
                letterSpacing: -0.5
            )
        ),
        const SizedBox(height: 4),
        Text(
            rutbe(),
            style: const TextStyle(color: AppColors.accentMavi, fontWeight: FontWeight.bold, fontSize: 16)
        ),
        const SizedBox(height: 25),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: size.width * 0.1),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("KAHRAMANLIK YOLU", style: TextStyle(fontWeight: FontWeight.w900, color: Colors.grey, fontSize: 11, letterSpacing: 1)),
                  Text("%${(ilerleme * 100).toInt()}", style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.anaMavi, fontSize: 15)),
                ],
              ),
              const SizedBox(height: 10),
              Container(
                height: 14,
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [BoxShadow(color: AppColors.anaMavi.withOpacity(0.1), blurRadius: 10)]
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: LinearProgressIndicator(
                    value: ilerleme,
                    backgroundColor: AppColors.anaMavi.withOpacity(0.1),
                    valueColor: const AlwaysStoppedAnimation<Color>(AppColors.anaMavi),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatsGrid(int bolumSayisi, int rozetSayisi, int puan, Size size) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          _buildStatCard("GÖREV", bolumSayisi.toString(), Icons.auto_awesome_mosaic_rounded, Colors.orangeAccent, size),
          const SizedBox(width: 15),
          _buildStatCard("ROZET", rozetSayisi.toString(), Icons.emoji_events_rounded, Colors.purpleAccent, size),
          const SizedBox(width: 15),
          _buildStatCard("PUAN", puan.toString(), Icons.stars_rounded, Colors.greenAccent, size),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color, Size size) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(color: color.withOpacity(0.14), blurRadius: 5, offset: const Offset(0, 8))
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 10),
            Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.yaziRengi)),
            Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.grey.shade400, letterSpacing: 1)),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsList(Size size, bool isAdmin) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(30),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 20, offset: const Offset(0, 10))]
        ),
        child: Column(
          children: [
            if (isAdmin) _buildSettingsTile(Icons.admin_panel_settings_rounded, "Yönetim Paneli", size, color: Colors.deepPurple, onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminHome()));
            }),
            _buildSettingsTile(Icons.notifications_active_rounded, "Bildirimleri Yönet", size, isSwitch: true),
            _buildSettingsTile(Icons.shield_rounded, "Güvenlik Rehberim", size),
            _buildSettingsTile(Icons.info_rounded, "Uygulama Hakkında", size, isLast: true),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsTile(IconData icon, String title, Size size, {bool isSwitch = false, bool isLast = false, Color? color, VoidCallback? onTap}) {
    return Column(
      children: [
        ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 25, vertical: 8),
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: (color ?? AppColors.anaMavi).withOpacity(0.08), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: color ?? AppColors.anaMavi, size: 22),
          ),
          title: Text(title, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: color)),
          trailing: isSwitch
              ? Switch(
              value: bildirimlerAcik,
              onChanged: (v) => setState(() => bildirimlerAcik = v),
              activeColor: AppColors.anaMavi
          )
              : const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.grey),
          onTap: onTap ?? (isSwitch ? null : () {}),
        ),
        if (!isLast) Divider(height: 1, indent: 70, endIndent: 30, color: Colors.grey.shade100),
      ],
    );
  }

  Widget _buildDangerZone(Size size) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          _buildActionButton("OTURUMU KAPAT", AppColors.anaMavi, Icons.logout_rounded, _cikisYap, size),
          const SizedBox(height: 15),
          TextButton(
            onPressed: _hesabiSil,
            child: Text(
                "HESABI KALICI OLARAK SİL",
                style: TextStyle(color: Colors.red.shade300, fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 1)
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(String text, Color color, IconData icon, VoidCallback onTap, Size size) {
    return Container(
      width: double.infinity,
      height: 60,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(colors: [color, color.withOpacity(0.85)]),
        boxShadow: [BoxShadow(color: color.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 5))],
      ),
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, color: Colors.white, size: 20),
        label: Text(text, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 1.5, fontSize: 14)),
        style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))
        ),
      ),
    );
  }
}
