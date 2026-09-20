import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:zorbalik_uygulamasi/app_theme.dart';
import 'package:zorbalik_uygulamasi/screens/hikaye_detay_ekrani.dart';
import 'package:flutter_animate/flutter_animate.dart';

class HikayeListelemeEkrani extends StatelessWidget {
  const HikayeListelemeEkrani({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final paddingValue = size.width * 0.05;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        toolbarHeight: 90,
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: const Padding(
          padding: EdgeInsets.only(top: 25),
          child: Text(
            "Kahramanlık Öyküleri",
            style: TextStyle(
              color: Color(0xFF1E293B),
              fontWeight: FontWeight.w900,
              fontSize: 22,
              letterSpacing: -0.5,
            ),
          ),
        ),
        leading: Padding(
          padding: const EdgeInsets.only(left: 16, top: 25),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.indigo.withOpacity(0.06),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: IconButton(
              icon: const Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 18,
                color: Color(0xFF475569),
              ),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('stories').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppColors.anaMavi));
          }
          
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return _buildEmptyState();
          }

          final docs = snapshot.data!.docs;

          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverPadding(
                padding: EdgeInsets.fromLTRB(paddingValue, 10, paddingValue, 100),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 0.75,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      var data = docs[index].data() as Map<String, dynamic>;
                      return _buildModernStoryCard(context, data, index)
                          .animate(delay: (index * 50).ms)
                          .fadeIn(duration: 400.ms)
                          .scale(begin: const Offset(0.9, 0.9), curve: Curves.easeOutBack);
                    },
                    childCount: docs.length,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildModernStoryCard(BuildContext context, Map<String, dynamic> data, int index) {
    List<Color> palette = [
      const Color(0xFF6366F1), // Indigo
      const Color(0xFFEC4899), // Pink
      const Color(0xFFF59E0B), // Amber
      const Color(0xFF10B981), // Emerald
      const Color(0xFF3B82F6), // Blue
    ];
    Color cardColor = palette[index % palette.length];
    
    String gorsel = data['gorselYolu'] ?? "";
    String baslik = data['baslik'] ?? "Macera Başlıyor";

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (c) => HikayeDetayEkrani(
            feedbackMessage: data['feedbackMessage'] ?? "",
            baslik: baslik,
            gorselYolu: gorsel.isNotEmpty ? gorsel : "assets/image/books.png",
            temaRengi: cardColor,
            hikayeMetni: data['hikayeMetni'] ?? data['icerik'] ?? "",
          ),
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // VERİ DOSTU ALAN: İnternetten görsel indirmek yerine renkli lokal ikon alanı
              Expanded(
                flex: 4,
                child: Container(
                  width: double.infinity,
                  color: cardColor.withOpacity(0.08),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Icon(
                        Icons.auto_stories_rounded,
                        size: 42,
                        color: cardColor,
                      ),
                      Positioned(
                        top: 10,
                        left: 10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            "HİKAYE",
                            style: TextStyle(
                              color: cardColor,
                              fontSize: 8,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // METİN ALANI: Taşma hatası asla olamaz
              Expanded(
                flex: 3,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          baslik,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF1E293B),
                            height: 1.2,
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          Icon(Icons.arrow_right_alt_rounded, size: 14, color: cardColor),
                          const SizedBox(width: 2),
                          Text(
                            "Hemen Oku",
                            style: TextStyle(
                              fontSize: 10,
                              color: cardColor,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFallbackIcon(Color color) {
    return Container(
      color: color.withOpacity(0.1),
      child: Icon(Icons.auto_stories_rounded, size: 40, color: color.withOpacity(0.5)),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.indigo.withOpacity(0.05),
                  blurRadius: 20,
                ),
              ],
            ),
            child: const Icon(Icons.auto_stories_rounded, size: 60, color: Color(0xFFCBD5E1)),
          ),
          const SizedBox(height: 24),
          const Text(
            "Kütüphane Hazırlanıyor!",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: Color(0xFF475569),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            "Yeni hikayeler çok yakında burada olacak.",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF94A3B8),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ).animate().fadeIn().scale(begin: const Offset(0.9, 0.9)),
    );
  }
}
