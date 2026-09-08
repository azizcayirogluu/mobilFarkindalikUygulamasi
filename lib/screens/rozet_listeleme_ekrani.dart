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

  // Kullanıcının ilerlemesini gösteren Oyunbaz Cam Kart
  Widget _buildEnhancedHeader(int current, int total) {
    double progress = total > 0 ? (current / total) : 0;
    return Container(
      margin: const EdgeInsets.fromLTRB(22, 15, 22, 20),
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 180),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(35),
        color: Colors.white.withOpacity(0.45),
        border: Border.all(color: Colors.white.withOpacity(0.6), width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.08),
            blurRadius: 25,
            offset: const Offset(0, 10),
          )
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(35),
        child: Stack(
          children: [
            // Arka plandaki renkli "Oyun Bulutları"
            _buildBlob(right: -20, top: -20, color: Colors.blue.shade100, size: 120),
            _buildBlob(left: -30, bottom: -40, color: Colors.purple.shade100, size: 140),
            _buildBlob(right: 40, bottom: -20, color: Colors.pink.shade100, size: 80),

            Padding(
              padding: const EdgeInsets.all(22),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      // Başarı İkonu
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.8),
                          shape: BoxShape.circle,
                          boxShadow: [BoxShadow(color: Colors.amber.withOpacity(0.2), blurRadius: 8)],
                        ),
                        child: const Icon(Icons.auto_awesome, color: Colors.amber, size: 24)
                            .animate(onPlay: (c) => c.repeat())
                            .shimmer(duration: 1000.ms),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "KOLEKSİYON DURUMU",
                              style: TextStyle(
                                color: Colors.indigo.shade900.withOpacity(0.5),
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.5,
                              ),
                            ),
                            Text(
                              "Süper Kahraman! ✨",
                              style: TextStyle(
                                color: Colors.indigo.shade900,
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Yüzde Rozeti
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.indigo.shade900,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          "%${(progress * 100).toInt()}",
                          style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w900),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _buildLinearProgress(progress),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Kazanılan: $current / $total Rozet",
                        style: TextStyle(
                          color: Colors.indigo.shade700,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.05, curve: Curves.easeOutQuad);
  }

  Widget _buildBlob({double? top, double? bottom, double? left, double? right, required Color color, required double size}) {
    return Positioned(
      top: top, bottom: bottom, left: left, right: right,
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

  Widget _buildLinearProgress(double value) {
    return Container(
      height: 14,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.6),
        borderRadius: BorderRadius.circular(20),
      ),
      child: LayoutBuilder(builder: (context, constraints) {
        return Stack(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeOutQuart,
              height: 14,
              width: constraints.maxWidth * value.clamp(0.0, 1.0),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ],
        );
      }),
    );
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
                data['ad'] ?? "Gizemli",
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    color: isEarned ? const Color(0xFF1E293B) : const Color(0xFF94A3B8),
                    letterSpacing: -0.2
                ),
              ),
            ),
            const SizedBox(height: 4),
            // Kriter Bilgisi (Küçük İpucu)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isEarned 
                  ? badgeColor.withOpacity(0.1) 
                  : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                data['kriter_tipi'] == 'puan' 
                  ? "${data['hedef_deger'] ?? '100'} Puan" 
                  : "Görev",
                style: TextStyle(
                  fontSize: 8,
                  fontWeight: FontWeight.w800,
                  color: isEarned ? badgeColor : const Color(0xFF94A3B8),
                ),
              ),
            ),
          ],
        ),
      ).animate(delay: (index * 15).ms).fadeIn(duration: 300.ms).slideY(begin: 0.05, curve: Curves.easeOutQuad),
    );
  }

  // Rozet Detay Alt Penceresi (Modal Bottom Sheet)
  void _showBadgeInfo(BuildContext context, Map<String, dynamic> data, bool isEarned, Color color, IconData icon) {
    String kriterMetni = "";
    if (data['kriter_tipi'] == 'puan') {
      kriterMetni = "${data['hedef_deger'] ?? '100'} Puan toplayarak";
    } else {
      kriterMetni = "Daha fazla siber senaryo tamamlayarak";
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
            ).animate().scale(duration: 200.ms, curve: Curves.bounceOut),
            const SizedBox(height: 18),

            Text(
              data['ad'] ?? "Gizemli Rozet",
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
