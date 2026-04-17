import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:zorbalik_uygulamasi/app_theme.dart';

class RozetlerEkrani extends StatelessWidget {
  const RozetlerEkrani({super.key});

  // hex kodlarını Flutter Color'a dönüştürür
  Color _parseColor(String? hexColor) {
    if (hexColor == null || hexColor.isEmpty) return AppColors.anaMavi;
    try {
      String cleanHex = hexColor.replaceAll('#', '').replaceAll('0x', '');
      if (cleanHex.length == 6) cleanHex = 'FF$cleanHex'; // Opacity (FF) eklemesi yapar
      return Color(int.parse('0x$cleanHex'));
    } catch (e) {
      return AppColors.anaMavi;
    }
  }

  // Veritabanından gelen ikon isimlerini veya kodlarını Material Icons kütüphanesiyle eşleştirir
  IconData _getIconData(dynamic iconData) {
    if (iconData == null) return Icons.stars_rounded;

    if (iconData is int) {
      return IconData(iconData, fontFamily: 'MaterialIcons');
    }

    String name = iconData.toString();

    // Sık kullanılan ikonlar için manuel eşleştirme (Fallback mekanizması)
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

    try {
      if (name.startsWith('0x')) {
        return IconData(int.parse(name), fontFamily: 'MaterialIcons');
      }
      if (name.length >= 4 && name.length <= 5) {
        return IconData(int.parse(name, radix: 16), fontFamily: 'MaterialIcons');
      }
    } catch (e) {
      debugPrint("İkon dönüştürme hatası: $name -> $e");
    }

    return Icons.stars_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final User? user = FirebaseAuth.instance.currentUser;
    final size = MediaQuery.of(context).size;

    if (user == null) return const Scaffold(body: Center(child: Text("Giriş Yapılmadı")));

    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      appBar: AppBar(
        title: const Text("BAŞARI KOLEKSİYONU",
            style: TextStyle(color: AppColors.yaziRengi, fontWeight: FontWeight.w900, fontSize: 20, letterSpacing: 1.2)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      // İç içe StreamBuilder: Hem kullanıcı ilerlemesini hem de tüm rozet listesini anlık dinler
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('usersProgress').doc(user.uid).snapshots(),
        builder: (context, userSnap) {
          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('badges').snapshots(),
            builder: (context, badgeSnap) {
              if (!userSnap.hasData || !badgeSnap.hasData) {
                return const Center(child: CircularProgressIndicator(color: AppColors.anaMavi));
              }

              final userData = userSnap.data!.data() as Map<String, dynamic>?;
              final List kazanilanIds = userData?['rozetler'] ?? []; // Kullanıcının sahip olduğu rozet ID'leri

              final List<QueryDocumentSnapshot> tumRozetler = List.from(badgeSnap.data!.docs);

              // Sıralama Mantığı: Kazanılan rozetleri listenin en başına taşır
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
                    child: _buildEnhancedHeader(kazanilanIds.length, tumRozetler.length, size),
                  ),
                  // Rozetlerin 3'lü sütun yapısında sergilendiği ızgara (Grid)
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    sliver: SliverGrid(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 15,
                        mainAxisSpacing: 20,
                        childAspectRatio: 0.75,
                      ),
                      delegate: SliverChildBuilderDelegate(
                            (context, index) {
                          final rozet = tumRozetler[index];
                          final data = rozet.data() as Map<String, dynamic>;
                          final bool isEarned = kazanilanIds.contains(rozet.id);
                          return _buildModernBadgeCard(context, data, isEarned);
                        },
                        childCount: tumRozetler.length,
                      ),
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 100)),
                ],
              );
            },
          );
        },
      ),
    );
  }

  // Kullanıcının kaç rozet topladığını gösteren özet alanı
  Widget _buildEnhancedHeader(int current, int total, Size size) {
    double progress = total > 0 ? (current / total) : 0;
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.anaMavi, Color(0xFF64B5F6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(color: AppColors.anaMavi.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10))
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
                  Text("Gelişimin", style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w600)),
                  SizedBox(height: 5),
                  Text("Süper Kahraman!", style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900)),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
                child: const Icon(Icons.auto_awesome, color: Colors.white, size: 28),
              )
            ],
          ),
          const SizedBox(height: 25),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Kazanılan: $current / $total", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              Text("%${(progress * 100).toInt()}", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.white.withOpacity(0.2),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
              minHeight: 10,
            ),
          ),
        ],
      ),
    );
  }

  // Her bir rozetin görselini ve ismini içeren kart yapısı
  Widget _buildModernBadgeCard(BuildContext context, Map<String, dynamic> data, bool isEarned) {
    final Color badgeColor = _parseColor(data['renk']);
    final IconData badgeIcon = _getIconData(data['ikon']);

    return GestureDetector(
      onTap: () => _showBadgeInfo(context, data, isEarned, badgeColor, badgeIcon),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        decoration: BoxDecoration(
          color: isEarned ? Colors.white : Colors.white.withOpacity(0.5),
          borderRadius: BorderRadius.circular(25),
          boxShadow: isEarned
              ? [BoxShadow(color: badgeColor.withOpacity(0.15), blurRadius: 10, offset: const Offset(0, 5))]
              : [],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 60, height: 60,
                  decoration: BoxDecoration(
                    color: isEarned ? badgeColor.withOpacity(0.1) : Colors.grey[300]!.withOpacity(0.5),
                    shape: BoxShape.circle,
                  ),
                ),
                Icon(
                  // Kazanılmamış rozetlerde kilit ikonu gösterilir
                  isEarned ? badgeIcon : Icons.lock_rounded,
                  color: isEarned ? badgeColor : Colors.grey[400],
                  size: 32,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Text(
                data['ad'] ?? "???",
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: isEarned ? AppColors.yaziRengi : Colors.grey[500],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Rozete tıklandığında alttan açılan detaylı bilgi ekranı
  void _showBadgeInfo(BuildContext context, Map<String, dynamic> data, bool isEarned, Color color, IconData icon) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(35),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(40)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 50, height: 5, decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(10))),
            const SizedBox(height: 30),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
              child: Icon(isEarned ? icon : Icons.lock_clock_rounded, size: 60, color: color),
            ),
            const SizedBox(height: 20),
            Text(data['ad'] ?? "Gizemli Rozet", style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: AppColors.yaziRengi)),
            const SizedBox(height: 12),
            // Kazanma durumuna göre dinamik açıklama metni
            Text(
              isEarned
                  ? "Tebrikler! Bu rozeti koleksiyonuna ekledin. Başarılarınla gurur duyuyoruz!"
                  : "Bu rozet henüz kilitli. ${data['kriter_tipi'] == 'puan' ? data['hedef_deger'].toString() + ' puan toplayarak' : 'daha fazla senaryo çözerek'} bu rozeti kazanabilirsin!",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey[600], height: 1.5),
            ),
            const SizedBox(height: 35),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: isEarned ? color : Colors.grey,
                minimumSize: const Size(double.infinity, 60),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                elevation: 0,
              ),
              onPressed: () => Navigator.pop(context),
              child: const Text("KAPAT", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}