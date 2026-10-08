import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_animate/flutter_animate.dart';

class RozetlerEkrani extends StatelessWidget {
  const RozetlerEkrani({super.key});

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
    const Color backgroundSubtle = Color(0xFFF8FAFC);
    final bottomInset = MediaQuery.paddingOf(context).bottom + 80;

    if (user == null) {
      return const Scaffold(
        backgroundColor: backgroundSubtle,
        body: Center(child: Text("Giriş Yapılmadı", style: TextStyle(fontWeight: FontWeight.bold))),
      );
    }

    return Scaffold(
      backgroundColor: backgroundSubtle,
      appBar: AppBar(
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
        title: const Text(
          "BAŞARI KOLEKSİYONU 🏆",
          style: TextStyle(
            color: Color(0xFF1E293B),
            fontWeight: FontWeight.w900,
            fontSize: 18,
            letterSpacing: -0.3,
          ),
        ),
      ),
      body: StreamBuilder<DocumentSnapshot>(
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
                    padding: EdgeInsets.fromLTRB(20, 5, 20, bottomInset),
                    sliver: SliverGrid(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 14,
                        childAspectRatio: 0.72,
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
    );
  }

  Widget _buildEnhancedHeader(int current, int total) {
    double progress = total > 0 ? (current / total) : 0;
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 10, 20, 20),
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A4F46E5),
            blurRadius: 16,
            offset: Offset(0, 8),
          )
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Stack(
          children: [
            _buildBlob(right: -20, top: -20, color: const Color(0x33DBEAFE), size: 120),
            _buildBlob(left: -30, bottom: -40, color: const Color(0x33F3E8FF), size: 140),

            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [BoxShadow(color: Color(0x26FFC107), blurRadius: 8)],
                        ),
                        child: const Icon(Icons.auto_awesome, color: Colors.amber, size: 24)
                            .animate(onPlay: (c) => c.repeat())
                            .shimmer(duration: 1500.ms),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "KOLEKSİYON DURUMU",
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.indigo.shade900.withAlpha(128),
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.2,
                              ),
                            ),
                            const Text(
                              "Süper Kahraman! ✨",
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Color(0xFF1E293B),
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E293B),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          "%${(progress * 100).toInt()}",
                          style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w900),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  _buildLinearProgress(progress),
                  const SizedBox(height: 10),
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
          color: color,
        ),
      ),
    );
  }

  Widget _buildLinearProgress(double value) {
    return Container(
      height: 10,
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(20),
      ),
      child: LayoutBuilder(builder: (context, constraints) {
        return Stack(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeOutQuart,
              height: 10,
              width: constraints.maxWidth * value.clamp(0.0, 1.0),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6366F1), Color(0xFF3B82F6)],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildModernBadgeCard(BuildContext context, Map<String, dynamic> data, bool isEarned, int index) {
    final Color badgeColor = _parseColor(data['renk']);
    final IconData badgeIcon = _getIconData(data['ikon']);

    return GestureDetector(
      onTap: () => _showBadgeInfo(context, data, isEarned, badgeColor, badgeIcon),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isEarned ? badgeColor.withAlpha(50) : const Color(0xFFE2E8F0),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: isEarned ? badgeColor.withAlpha(12) : const Color(0x05000000),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: isEarned ? badgeColor.withAlpha(20) : const Color(0xFFF8FAFC),
                    shape: BoxShape.circle,
                  ),
                ),
                Icon(
                  isEarned ? badgeIcon : Icons.lock_rounded,
                  color: isEarned ? badgeColor : const Color(0xFFCBD5E1),
                  size: 22,
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
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
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isEarned 
                  ? badgeColor.withAlpha(20) 
                  : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                data['kriter_tipi'] == 'puan' 
                  ? "${data['hedef_deger'] ?? '100'} P" 
                  : "GÖREV",
                style: TextStyle(
                  fontSize: 8,
                  fontWeight: FontWeight.w900,
                  color: isEarned ? badgeColor : const Color(0xFF94A3B8),
                ),
              ),
            ),
          ],
        ),
      ).animate(delay: (index * 15).ms).fadeIn(duration: 300.ms).slideY(begin: 0.05, curve: Curves.easeOutQuad),
    );
  }

  void _showBadgeInfo(BuildContext context, Map<String, dynamic> data, bool isEarned, Color color, IconData icon) {
    String kriterMetni = "";
    if (data['kriter_tipi'] == 'puan') {
      kriterMetni = "${data['hedef_deger'] ?? '100'} Puan toplayarak";
    } else {
      kriterMetni = "Daha fazla siber senaryo tamamlayarak";
    }

    final bottomPadding = MediaQuery.paddingOf(context).bottom + 20;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.8),
        padding: EdgeInsets.fromLTRB(24, 20, 24, bottomPadding),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(color: const Color(0xFFE2E8F0), borderRadius: BorderRadius.circular(10)),
              ),
              const SizedBox(height: 20),

              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                    color: color.withAlpha(20),
                    shape: BoxShape.circle,
                    border: Border.all(color: color.withAlpha(30), width: 2)
                ),
                child: Icon(
                  isEarned ? icon : Icons.lock_outline_rounded,
                  size: 48,
                  color: color,
                ),
              ).animate().scale(duration: 200.ms, curve: Curves.bounceOut),
              const SizedBox(height: 16),

              Text(
                data['ad'] ?? "Gizemli Rozet",
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF1E293B), letterSpacing: -0.3),
              ),
              const SizedBox(height: 10),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Text(
                  isEarned
                      ? "Harika iş çıkardın! Zorbalığa karşı verdiğin mücadele ve kazandığın bu rozet projemizin en değerli parçası. Kahramanlığa devam et!"
                      : "Bu güç kalkanı henüz aktifleşmedi. $kriterMetni bu rozeti başarı koleksiyonuna katabilirsin! ⚡",
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 14, color: Color(0xFF64748B), height: 1.5, fontWeight: FontWeight.w500),
                ),
              ),
              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isEarned ? color : const Color(0xFF64748B),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    "TAMAM",
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 0.2),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
