import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
  int _secilenIndeks = 0;
  final User? _currentUser = FirebaseAuth.instance.currentUser;

  // Ekran listesi (Hafıza dostu olması için burada tanımlıyoruz)
  late List<Widget> _sayfalar;

  @override
  void initState() {
    super.initState();
    final String aktifIsim = _currentUser?.displayName ?? "Kahraman";
    _sayfalar = [
      AnaSayfa(kullaniciAdi: aktifIsim, onProfileTap: () => setState(() => _secilenIndeks = 3), onTabChanged: (i) => setState(() => _secilenIndeks = i)),
      const EgitimEkrani(),
      const RozetlerEkrani(),
      ProfilEkrani(kullaniciAdi: aktifIsim),
    ];
  }

  @override
  Widget build(BuildContext context) {
    if (_currentUser == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      // IndexedStack yerine basit geçiş kullanıyoruz (Daha az RAM harcar)
      body: _sayfalar[_secilenIndeks],
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: _buildKahramanFAB(),
      bottomNavigationBar: _buildModernBottomBar(),
    );
  }

  Widget _buildKahramanFAB() {
    return Container(
      height: 65,
      width: 65,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          colors: [Color(0xFF10B981), Color(0xFF3B82F6)],
        ),
        border: Border.all(color: Colors.white, width: 4),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const SiberAsistanEkrani()),
          ),
          customBorder: const CircleBorder(),
          child: const Icon(Icons.smart_toy_rounded, color: Colors.white, size: 30),
        ),
      ),
    );
  }

  Widget _buildModernBottomBar() {
    return BottomAppBar(
      color: Colors.white,
      shape: const CircularNotchedRectangle(),
      notchMargin: 10,
      elevation: 15,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(Icons.grid_view_rounded, "Keşfet", 0),
            _buildNavItem(Icons.auto_stories_rounded, "Eğitim", 1),
            const SizedBox(width: 48), // FAB boşluğu
            _buildNavItem(Icons.emoji_events_rounded, "Rozetler", 2),
            _buildNavItem(Icons.face_retouching_natural_rounded, "Profil", 3),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    final bool isSelected = _secilenIndeks == index;
    final Color color =
        isSelected ? const Color(0xFF3B82F6) : Colors.grey.shade400;

    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _secilenIndeks = index),
        borderRadius: BorderRadius.circular(15),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: color,
              size: isSelected ? 26 : 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
