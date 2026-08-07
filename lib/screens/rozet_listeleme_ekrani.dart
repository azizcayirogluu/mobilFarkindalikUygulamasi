import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:zorbalik_uygulamasi/app_theme.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:math' as math;

class RozetlerEkrani extends StatelessWidget {
  const RozetlerEkrani({super.key});

  // Hex kodlarını güvenli bir şekilde Flutter Color'a dönüştürür
  Color _parseColor(String? hexColor) {
    if (hexColor == null || hexColor.isEmpty) return const Color(0xFF3B82F6);
    try {
      String cleanHex = hexColor.replaceAll('#', '').replaceAll('0x', '');
      if (cleanHex.length == 6) cleanHex = 'FF$cleanHex';
      return Color(int.parse('0x$cleanHex'));
    } catch (e) {
      return const Color(0xFF3B82F6);
    }
  }

  // Firestore'dan gelen ikon isimlerini Material Icons kütüphanesiyle eşleştirir
  IconData _getIconData(dynamic iconData) {
    if (iconData == null) return Icons.stars_rounded;
    String name = iconData.toString();

    switch (name) {
      case 'directions_walk': return Icons.directions_walk_rounded;
      case 'menu_book': return Icons.menu_book_rounded;
      case 'security': return Icons.security_rounded;
      case 'bolt': return Icons.bolt_rounded;
      case 'favorite': return Icons.favorite_rounded;
      case 'visibility': return Icons.visibility_rounded;
      case 'psychology': return Icons.psychology_rounded;
      case 'people': return Icons.people_alt_rounded;
      case 'workspace_premium': return Icons.workspace_premium_rounded;
      case 'star': return Icons.star_rounded;
      case 'shield': return Icons.shield_rounded;
      case 'rocket': return Icons.rocket_launch_rounded;
      case 'emoji_events': return Icons.emoji_events_rounded;
    }
    return Icons.stars_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final User? user = FirebaseAuth.instance.currentUser;
    const Color backgroundSubtle = Color(0xFFF0F9FF); // Akıcı bulut mavisi zemin

    if (user == null) {
      return const Scaffold(
        backgroundColor: backgroundSubtle,
        body: Center(child: Text("Giriş Yapılmadı", style: TextStyle(fontWeight: FontWeight.bold))),
      );
    }

    return Scaffold(
      backgroundColor: backgroundSubtle,
      appBar: AppBar(
        title: const Text(
          "BAŞARI KOLEKSİYONU 🏆",
          style: TextStyle(
            color: Color(0xFF0F172A),
            fontWeight: FontWeight.w900,
            fontSize: 18,
            letterSpacing: -0.3,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: Stack(
        children: [
          // Arka Plan Dekoratif Halka Efektleri
          Positioned(
            top: 120,
            right: -60,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(shape: BoxShape.circle, color: const Color(0xFF3B82F6).withOpacity(0.02)),
            ),
          ),

          StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance.collection('usersProgress').doc(user.uid).snapshots(),
            builder: (context, userSnap) {
              return StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('badges').snapshots(),
                builder: (context, badgeSnap) {
                  if (!userSnap.hasData || !badgeSnap.hasData) {
                    return const Center(
                      child: CircularProgressIndicator(color: Color(0xFF3B82F6)),
                    );
                  }

                  final userData = userSnap.data!.data() as Map<String, dynamic>?;
                  final List kazanilanIds = userData?['rozetler'] ?? [];

                  final List<QueryDocumentSnapshot> tumRozetler = List.from(badgeSnap.data!.docs);

                  // Sıralama Mantığı: Kazanılan rozetleri her zaman en başa alır
                  tumRozetler.sort((a, b) {
                    bool aKazanildi = kazanilanIds.contains(a.id);
                    bool bKazanildi = kazanilanIds.contains(b.id);
                    if (aKazanildi && !bKazanildi) return -1;
                    if (!aKazanildi && bKazanildi) return 1;
                    return 0;
                  });

                  return CustomScrollView(
                    physics: const BouncingScrollPhysics(),
                    slivers: [
                      SliverToBoxAdapter(
                        child: _buildEnhancedHeader(kazanilanIds.length, tumRozetler.length),
                      ),

                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(20, 5, 20, 100),
                        sliver: SliverGrid(
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            crossAxisSpacing: 14,
                            mainAxisSpacing: 16,
                            childAspectRatio: 0.78,
                          ),
                          delegate: SliverChildBuilderDelegate((context, index) {
                            final rozet = tumRozetler[index];
                            final data = rozet.data() as Map<String, dynamic>;
                            final bool isEarned = kazanilanIds.contains(rozet.id);
                            return _buildModernBadgeCard(context, data, isEarned, index);
                          }, childCount: tumRozetler.length),
                        ),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  // Kullanıcının ilerlemesini gösteren Neon Gradyanlı Kart
  Widget _buildEnhancedHeader(int current, int total) {
    double progress = total > 0 ? (current / total) : 0;
    return Container(
      margin: const EdgeInsets.fromLTRB(22, 15, 22, 20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1D4ED8).withOpacity(0.25),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Koleksiyon Durumu 🌟",
                    style: TextStyle(color: Color(0xFFBFDBFE), fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 0.5),
                  ),
                  SizedBox(height: 4),
                  Text(
                    "Süper Kahraman!",
                    style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: -0.3),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.auto_awesome, color: Colors.amber, size: 24)
                    .animate(onPlay: (c) => c.repeat())
                    .shimmer(duration: 1800.ms),
              ),
            ],
          ),
          const SizedBox(height: 22),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Kazanılan: $current / $total Rozet",
                style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w800),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(10)),
                child: Text(
                  "%${(progress * 100).toInt()}",
                  style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w900),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.white.withOpacity(0.15),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
              minHeight: 8,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).scale(begin: const Offset(0.96, 0.96), curve: Curves.easeOutBack);
  }

  // 3D Hissiyatlı, İnteraktif Rozet Yuvaları
  Widget _buildModernBadgeCard(BuildContext context, Map<String, dynamic> data, bool isEarned, int index) {
    final Color badgeColor = _parseColor(data['renk']);
    final IconData badgeIcon = _getIconData(data['ikon']);

    return GestureDetector(
      onTap: () => _showBadgeInfo(context, data, isEarned, badgeColor, badgeIcon),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isEarned ? badgeColor.withOpacity(0.15) : Colors.transparent,
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: isEarned ? badgeColor.withOpacity(0.08) : const Color(0xFF0F172A).withOpacity(0.02),
              blurRadius: 15,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                // Dış Halka Parlaması
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    color: isEarned ? badgeColor.withOpacity(0.08) : const Color(0xFFF1F5F9),
                    shape: BoxShape.circle,
                  ),
                ),
                // İkon Alanı
                Icon(
                  isEarned ? badgeIcon : Icons.lock_rounded,
                  color: isEarned ? badgeColor : const Color(0xFF94A3B8),
                  size: 26,
                ),
              ],
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Text(
                isEarned ? (data['ad'] ?? "???") : "Kilitli",
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    color: isEarned ? const Color(0xFF1E293B) : const Color(0xFF94A3B8),
                    letterSpacing: -0.2
                ),
              ),
            ),
          ],
        ),
      ).animate(delay: (index * 40).ms).fadeIn(duration: 400.ms).slideY(begin: 0.08, curve: Curves.easeOutBack),
    );
  }

  // Rozet Detay Alt Penceresi (Modal Bottom Sheet)
  void _showBadgeInfo(BuildContext context, Map<String, dynamic> data, bool isEarned, Color color, IconData icon) {
    String kriterMetni = "";
    if (!isEarned) {
      if (data['kriter_tipi'] == 'puan') {
        kriterMetni = "${data['hedef_deger'] ?? '100'} Puan toplayarak";
      } else {
        kriterMetni = "Daha fazla siber senaryo tamamlayarak";
      }
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        padding: const EdgeInsets.fromLTRB(30, 20, 30, 35),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(36)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 45,
              height: 5,
              decoration: BoxDecoration(color: const Color(0xFFE2E8F0), borderRadius: BorderRadius.circular(10)),
            ),
            const SizedBox(height: 25),

            // Yuva İkonu Parlaması
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                  color: color.withOpacity(0.08),
                  shape: BoxShape.circle,
                  border: Border.all(color: color.withOpacity(0.2), width: 2)
              ),
              child: Icon(
                isEarned ? icon : Icons.lock_outline_rounded,
                size: 55,
                color: color,
              ),
            ).animate().scale(duration: 400.ms, curve: Curves.bounceOut),
            const SizedBox(height: 18),

            Text(
              isEarned ? (data['ad'] ?? "Gizemli Rozet") : "Gizemli Rozet Kalkanı",
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF0F172A), letterSpacing: -0.3),
            ),
            const SizedBox(height: 12),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Text(
                isEarned
                    ? "Harika iş çıkardın! Zorbalığa karşı verdiğin mücadele ve kazandığın bu rozet projemizin en değerli parçası. Kahramanlığa devam et!"
                    : "Bu güç kalkanı henüz aktifleşmedi. $kriterMetni bu rozeti başarı koleksiyonuna katabilirsin! ⚡",
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, color: Color(0xFF475569), height: 1.5, fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(height: 30),

            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: isEarned ? color : const Color(0xFF64748B),
                minimumSize: const Size(double.infinity, 54),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                elevation: 0,
              ),
              onPressed: () => Navigator.pop(context),
              child: const Text(
                "KAHRAMAN KÜTÜPHANESİNE DÖN",
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 0.2),
              ),
            ),
          ],
        ),
      ),
    );
  }
}