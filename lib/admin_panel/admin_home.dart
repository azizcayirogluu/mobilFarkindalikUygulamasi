// Flutter UI için gerekli paket
import 'package:flutter/material.dart';

// Firebase Authentication işlemleri (çıkış yapma vs.)
import 'package:firebase_auth/firebase_auth.dart';

// Uygulamanın renk ve tema ayarları
import 'package:zorbalik_uygulamasi/app_theme.dart';

// Admin paneldeki sayfalar (her biri ayrı ekran)
import 'package:zorbalik_uygulamasi/admin_panel/dashboard_page.dart';
import 'package:zorbalik_uygulamasi/admin_panel/scenario_manager.dart';
import 'package:zorbalik_uygulamasi/admin_panel/story_manager.dart';
import 'package:zorbalik_uygulamasi/admin_panel/video_manager.dart';
import 'package:zorbalik_uygulamasi/admin_panel/user_manager.dart';
import 'package:zorbalik_uygulamasi/admin_panel/detective_manager.dart';

// Çıkış yaptıktan sonra yönlendirilecek giriş/karşılama ekranı
import 'package:zorbalik_uygulamasi/screens/karsilama_ekrani.dart';

// Stateful widget → çünkü sayfa değiştikçe UI güncelleniyor
class AdminHome extends StatefulWidget {
  const AdminHome({super.key});

  @override
  State<AdminHome> createState() => _AdminHomeState();
}

class _AdminHomeState extends State<AdminHome> {
  // Sidebar'da seçili olan index'i tutuyor
  int _selectedIndex = 0;

  // Sağ tarafta gösterilecek sayfalar listesi
  final List<Widget> _pages = [
    const DashboardPage(),       // 0 → Ana dashboard
    const ScenarioManager(),     // 1 → Senaryo yönetimi
    const StoryManager(),        // 2 → Hikaye yönetimi
    const VideoManager(),        // 3 → Video yönetimi
    const UserManager(),         // 4 → Kullanıcı yönetimi
    const DetectiveManager(),    // 5 → Dedektif soruları
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.zemin,

      // Ana layout: Sol sidebar + sağ içerik
      body: Row(
        children: [
          // SOL MENÜ (SIDEBAR)
          Container(
            width: 260,
            margin: const EdgeInsets.all(16),

            // Sidebar görünüm ayarları
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),

            child: Column(
              children: [
                _buildSidebarHeader(), // Üst başlık (logo + isim)

                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Divider(color: Colors.white10, height: 1),
                ),

                const SizedBox(height: 20),

                // Menü itemları (scroll olabilir)
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    children: [
                      _sidebarItem(0, Icons.grid_view_rounded, "Genel Merkez"),
                      _sidebarItem(1, Icons.map_rounded, "Senaryo Akışı"),
                      _sidebarItem(2, Icons.book_rounded, "Hikaye Arşivi"),
                      _sidebarItem(3, Icons.play_circle_outline, "Eğitim Videoları"),
                      _sidebarItem(4, Icons.group_outlined, "Kullanıcılar"),
                      _sidebarItem(5, Icons.search_rounded, "Dedektif Soruları"),
                    ],
                  ),
                ),

                _buildAdminProfile(), // Admin bilgisi (altta)
                _buildLogoutButton(), // Çıkış butonu
              ],
            ),
          ),

          // SAĞ TARAF → İÇERİK ALANI
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(top: 16, bottom: 16, right: 16),

              // İçerik kutusu tasarımı
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white, width: 2),
              ),

              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),

                // Sayfa değişiminde animasyon sağlar
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),

                  // Seçilen index'e göre sayfa değişir
                  child: _pages[_selectedIndex],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Sidebar üst kısmı (logo + başlık)
  Widget _buildSidebarHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 30),
      child: Column(
        children: [
          // Logo kutusu
          Container(
            height: 45,
            width: 45,
            decoration: BoxDecoration(
              gradient: AppColors.anaGradient,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.shield_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),

          const SizedBox(height: 12),

          // Panel başlığı
          const Text(
            "Uygulama Yönetim Paneli",
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 16,
              letterSpacing: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  // Sidebar menü item'ı
  Widget _sidebarItem(int index, IconData icon, String label) {
    // Seçili mi kontrolü
    bool isSelected = _selectedIndex == index;

    return InkWell(
      // Tıklanınca sayfa değiştirir
      onTap: () => setState(() => _selectedIndex = index),

      borderRadius: BorderRadius.circular(15),

      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),

        margin: const EdgeInsets.only(bottom: 4),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),

        // Seçili item arka planı değişir
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.white.withOpacity(0.08)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(15),
        ),

        child: Row(
          children: [
            // Icon rengi seçiliye göre değişir
            Icon(
              icon,
              color: isSelected
                  ? AppColors.anaMavi
                  : Colors.white.withOpacity(0.4),
              size: 20,
            ),

            const SizedBox(width: 12),

            // Yazı rengi ve bold durumu değişir
            Text(
              label,
              style: TextStyle(
                color: isSelected
                    ? Colors.white
                    : Colors.white.withOpacity(0.4),
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                fontSize: 14,
              ),
            ),

            // Seçili item'in en sağına küçük dot ekler
            if (isSelected) const Spacer(),
            if (isSelected)
              Container(
                width: 4,
                height: 4,
                decoration: const BoxDecoration(
                  color: AppColors.anaMavi,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }

  // Admin profil bilgisi (sidebar altı)
  Widget _buildAdminProfile() {
    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(12),

      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(15),
      ),

      child: Row(
        children: [
          // Profil iconu
          CircleAvatar(
            radius: 16,
            backgroundColor: AppColors.anaMavi.withOpacity(0.2),
            child: const Icon(Icons.person, size: 18, color: AppColors.anaMavi),
          ),

          const SizedBox(width: 10),

          // Admin adı
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Text(
                  "Aziz ÇAYIROĞLU",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Çıkış butonu
  Widget _buildLogoutButton() {
    return Padding(
      padding: const EdgeInsets.only(left: 12, right: 12, bottom: 20),

      child: TextButton.icon(
        onPressed: () async {
          // Firebase'den kullanıcıyı çıkış yaptırır
          await FirebaseAuth.instance.signOut();

          // Widget hala aktif mi kontrol (bug önleme)
          if (!mounted) return;

          // Kullanıcıyı giriş ekranına yönlendirir
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const HomePages()),
                (r) => false,
          );
        },

        icon: const Icon(Icons.power_settings_new_rounded, size: 18),
        label: const Text("ÇIKIŞ YAP"),

        // Buton stil ayarları
        style: TextButton.styleFrom(
          foregroundColor: Colors.redAccent.withOpacity(0.8),
          minimumSize: const Size(double.infinity, 45),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}