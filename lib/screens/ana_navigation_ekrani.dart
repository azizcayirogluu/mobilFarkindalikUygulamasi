import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:zorbalik_uygulamasi/app_theme.dart';
import 'package:zorbalik_uygulamasi/screens/ana_ekran.dart';
import 'package:zorbalik_uygulamasi/screens/egitim_ekrani.dart';
import 'package:zorbalik_uygulamasi/screens/profil_ekrani.dart';
import 'package:zorbalik_uygulamasi/screens/siber_asistan_ekrani.dart';
import 'package:zorbalik_uygulamasi/screens/rozet_listeleme_ekrani.dart';

class AnaNavigation extends StatefulWidget {
  const AnaNavigation({super.key});

  @override
  State<AnaNavigation> createState() => _AnaNavigationState();
}

class _AnaNavigationState extends State<AnaNavigation> {
  int _secilenIndeks = 0; // Aktif olan sekme indeksini tutar
  bool _baloncukGorunsun = false; // Siber Dost mesaj baloncuğunun görünürlük durumu
  final User? _currentUser = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    _karsilamaMesajiGoster(); // Sayfa açıldıktan kısa süre sonra karşılama mesajını tetikle
  }

  // Siber Dost animasyonlu baloncuğunu belirli süre aralıklarıyla gösterip gizler
  void _karsilamaMesajiGoster() {
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _baloncukGorunsun = true);
      Future.delayed(const Duration(seconds: 8), () {
        if (mounted) setState(() => _baloncukGorunsun = false);
      });
    });
  }

  // Alt menüden veya diğer sayfalardan gelen sekme değiştirme isteğini yönetir
  void _sekmeDegistir(int yeniIndeks) {
    if (_secilenIndeks != yeniIndeks) {
      setState(() => _secilenIndeks = yeniIndeks);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Kullanıcı oturum açmamışsa yükleme göstergesi döner
    if (_currentUser == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final String aktifIsim = _currentUser!.displayName ?? "Kahraman";

    return Scaffold(
      extendBody: true, // Alt menünün arkasındaki içeriğin devam etmesini sağlar
      backgroundColor: const Color(0xFFF8FAFC),
      body: IndexedStack(
        // Sayfaların durumunu koruyarak sadece aktif olanı gösterir
        index: _secilenIndeks,
        children: [
          AnaSayfa(
            kullaniciAdi: aktifIsim,
            onProfileTap: () => _sekmeDegistir(3),
            onTabChanged: (index) => _sekmeDegistir(index),
          ),
          const EgitimEkrani(),
          const RozetlerEkrani(),
          ProfilEkrani(
            kullaniciAdi: aktifIsim,
            onRozetTap: () => _sekmeDegistir(2),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: _buildSiberDostFAB(aktifIsim), // Ortadaki özel asistan butonu
      bottomNavigationBar: _buildGlassFloatingBar(), // Buzlu cam efektli navigasyon çubuğu
    );
  }

  // Siber Asistan'a (AI) yönlendiren ve mesaj baloncuğu içeren özel buton yapısı
  Widget _buildSiberDostFAB(String isim) {
    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedSlide(
            duration: const Duration(milliseconds: 800),
            offset: _baloncukGorunsun ? const Offset(0, 0) : const Offset(0, 0.5),
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 500),
              opacity: _baloncukGorunsun ? 1.0 : 0.0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  gradient: AppColors.anaGradient,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                    bottomLeft: Radius.circular(20),
                    bottomRight: Radius.circular(5),
                  ),
                  boxShadow: [
                    BoxShadow(color: AppColors.anaMavi.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 5))
                  ],
                ),
                child: Text(
                  "Selam $isim! 👋",
                  style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Ana FAB Butonu
          GestureDetector(
            onTap: () {
              setState(() => _baloncukGorunsun = false);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const SiberAsistanEkrani()));
            },
            child: Container(
              height: 72,
              width: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: AppColors.anaGradient,
                boxShadow: [
                  BoxShadow(color: AppColors.anaMavi.withOpacity(0.5), blurRadius: 20, spreadRadius: 2),
                ],
                border: Border.all(color: Colors.white, width: 4),
              ),
              child: const Icon(Icons.smart_toy_rounded, color: Colors.white, size: 36),
            ),
          ),
        ],
      ),
    );
  }

  // Glassmorphism (Buzlu Cam) efektli özel tasarlanmış navigasyon barı
  Widget _buildGlassFloatingBar() {
    return Container(
      height: 90,
      margin: const EdgeInsets.fromLTRB(18, 0, 18, 25),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(35),
        child: BackdropFilter(
          // Arka planı bulanıklaştırarak buzlu cam etkisi verir
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.85),
              borderRadius: BorderRadius.circular(35),
              border: Border.all(color: Colors.white.withOpacity(0.5), width: 1.5),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(Icons.grid_view_rounded, "Ana Sayfa", 0),
                _buildNavItem(Icons.local_library_rounded, "Eğitim", 1),
                const SizedBox(width: 60), // FAB (Siber Dost) için bırakılan boşluk
                _buildNavItem(Icons.workspace_premium_rounded, "Rozetler", 2),
                _buildNavItem(Icons.face_retouching_natural_rounded, "Profil", 3),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Navigasyon barındaki her bir butonu oluşturan yardımcı widget
  Widget _buildNavItem(IconData icon, String label, int index) {
    bool aktifMi = _secilenIndeks == index;
    return GestureDetector(
      onTap: () => _sekmeDegistir(index),
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Aktif butonda büyüme (Scale) animasyonu
          AnimatedScale(
            duration: const Duration(milliseconds: 300),
            scale: aktifMi ? 1.2 : 1.0,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: aktifMi ? AppColors.anaMavi.withOpacity(0.12) : Colors.transparent,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 28,
                color: aktifMi ? AppColors.anaMavi : Colors.blueGrey.shade300,
              ),
            ),
          ),
          // Sadece aktif butonda görünen metin etiketi
          AnimatedOpacity(
            duration: const Duration(milliseconds: 300),
            opacity: aktifMi ? 1.0 : 0.0,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: AppColors.anaMavi,
              ),
            ),
          ),
        ],
      ),
    );
  }
}