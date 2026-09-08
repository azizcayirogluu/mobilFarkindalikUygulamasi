import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:zorbalik_uygulamasi/app_theme.dart';
import 'package:zorbalik_uygulamasi/admin_panel/dashboard_page.dart';
import 'package:zorbalik_uygulamasi/admin_panel/scenario_manager.dart';
import 'package:zorbalik_uygulamasi/admin_panel/story_manager.dart';
import 'package:zorbalik_uygulamasi/admin_panel/video_manager.dart';
import 'package:zorbalik_uygulamasi/admin_panel/user_manager.dart';
import 'package:zorbalik_uygulamasi/admin_panel/detective_manager.dart';
import 'package:zorbalik_uygulamasi/admin_panel/incident_manager.dart';
import 'package:zorbalik_uygulamasi/screens/karsilama_ekrani.dart';
import 'package:zorbalik_uygulamasi/screens/ana_navigation_ekrani.dart';
import 'package:zorbalik_uygulamasi/services/report_service.dart';

class AdminHome extends StatefulWidget {
  const AdminHome({super.key});

  @override
  State<AdminHome> createState() => _AdminHomeState();
}

class _AdminHomeState extends State<AdminHome> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const DashboardPage(),
    const ScenarioManager(),
    const StoryManager(),
    const VideoManager(),
    const UserManager(),
    const DetectiveManager(),
    const IncidentManager(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      body: Row(
        children: [
          // PRO SIDEBAR
          Container(
            width: 280,
            decoration: const BoxDecoration(
              color: Color(0xFF0F172A),
              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 20)],
            ),
            child: Column(
              children: [
                _buildBrandHeader(),
                const Divider(color: Colors.white10, height: 1),
                const SizedBox(height: 20),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: [
                      _menuHeader("GENEL BAKIŞ"),
                      _sidebarItem(0, Icons.dashboard_customize_rounded, "Yönetim Paneli"),
                      _sidebarItem(6, Icons.report_problem_rounded, "Olay Bildirimleri"),
                      const SizedBox(height: 20),
                      _menuHeader("İÇERİK OPERASYONLARI"),
                      _sidebarItem(1, Icons.account_tree_rounded, "Senaryo Mimarisi"),
                      _sidebarItem(2, Icons.auto_stories_rounded, "Hikaye Kütüphanesi"),
                      _sidebarItem(3, Icons.video_library_rounded, "Eğitim Arşivi"),
                      _sidebarItem(5, Icons.psychology_rounded, "Dedektif Soruları"),
                      const SizedBox(height: 20),
                      _menuHeader("SİSTEM"),
                      _sidebarItem(4, Icons.admin_panel_settings_rounded, "Kullanıcı Yönetimi"),
                    ],
                  ),
                ),
                _buildBottomActions(),
              ],
            ),
          ),

          // ANA İÇERİK ALANI
          Expanded(
            child: Container(
              color: Colors.white,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: _pages[_selectedIndex],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBrandHeader() {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: AppColors.anaMavi, borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.shield_rounded, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 15),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("KAHRAMAN", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 1)),
              Text("DOSTUM CMS", style: TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _menuHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 12, bottom: 10),
      child: Text(title, style: const TextStyle(color: Colors.white24, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
    );
  }

  Widget _sidebarItem(int index, IconData icon, String label) {
    bool isSelected = _selectedIndex == index;
    return InkWell(
      onTap: () => setState(() => _selectedIndex = index),
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 4),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white.withOpacity(0.05) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: isSelected ? Border.all(color: Colors.white10) : null,
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? AppColors.accentMavi : Colors.white54, size: 20),
            const SizedBox(width: 14),
            Text(label, style: TextStyle(color: isSelected ? Colors.white : Colors.white54, fontWeight: isSelected ? FontWeight.bold : FontWeight.w500, fontSize: 13)),
          ],
        ),
      ),
    );
  }



  Widget _buildBottomActions() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          ElevatedButton.icon(
            onPressed: () => Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const AnaNavigation()), (r) => false),
            icon: const Icon(Icons.launch_rounded, size: 16),
            label: const Text("UYGULAMAYA DÖN"),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.anaMavi,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 10),
          TextButton.icon(
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (!mounted) return;
              Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const KarsilamaEkrani()), (r) => false);
            },
            icon: const Icon(Icons.power_settings_new_rounded, size: 16),
            label: const Text("GÜVENLİ ÇIKIŞ"),
            style: TextButton.styleFrom(foregroundColor: Colors.redAccent.withOpacity(0.7)),
          ),
        ],
      ),
    );
  }
}
