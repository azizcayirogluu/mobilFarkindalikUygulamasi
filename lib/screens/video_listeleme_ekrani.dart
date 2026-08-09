import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:zorbalik_uygulamasi/app_theme.dart';
import 'package:zorbalik_uygulamasi/screens/video_detay_ekrani.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:ui';
import 'dart:math' as math;

class VideoListelemeEkrani extends StatelessWidget {
  const VideoListelemeEkrani({super.key});

  @override
  Widget build(BuildContext context) {
    const Color backgroundSubtle = Color(0xFFF0F9FF); // Akıcı bulut mavisi zemin

    return Scaffold(
      backgroundColor: backgroundSubtle,
      appBar: AppBar(
        title: const Text(
          "EĞİTİCİ VİDEOLAR 🎥",
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 18,
            color: Color(0xFF4A90E2),
              letterSpacing: 1.5
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 3)),
              ],
            ),
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: Color(0xFF334155)),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          // Arka Plan Dekoratif Halkaları
          Positioned(
            top: 40,
            left: -50,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(shape: BoxShape.circle, color: const Color(0xFF3B82F6).withOpacity(0.03)),
            ),
          ),
          Positioned(
            bottom: -30,
            right: -30,
            child: Transform.rotate(
              angle: math.pi / 4,
              child: Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(35), color: Colors.amber.withOpacity(0.02)),
              ),
            ),
          ),

          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('videos').limit(20).snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return _buildShimmerLoading();
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("🎬", style: TextStyle(fontSize: 45)),
                      const SizedBox(height: 12),
                      Text(
                        "Henüz video eklenmemiş.",
                        style: TextStyle(color: Colors.blueGrey.shade400, fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                );
              }

              var videoDocs = snapshot.data!.docs;
              // JSON serileştirmesini güvenli hale getir ve map dönüşümünü yap
              List<dynamic> allVideosJson = videoDocs.map((e) {
                var d = e.data() as Map<String, dynamic>;
                return d;
              }).toList();

              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(22, 12, 22, 100),
                physics: const BouncingScrollPhysics(),
                itemCount: videoDocs.length,
                itemBuilder: (context, index) {
                  var data = videoDocs[index].data() as Map<String, dynamic>;
                  return _buildVideoCard(context, data, allVideosJson, index);
                },
              );
            },
          ),
        ],
      ),
    );
  }

  // Yenilenen Canlı Video Kart Tasarımı
  Widget _buildVideoCard(BuildContext context, Map<String, dynamic> data, List<dynamic> allVideos, int index) {
    String yId = data['youtubeId']?.toString() ?? "";
    String baslik = data['baslik'] ?? "Eğitici Video";
    String sure = data['sure'] ?? "5 Dakika";

    return Container(
      margin: const EdgeInsets.only(bottom: 22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E293B).withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 8),
          )
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (c) => VideoDetayEkrani(
                  baslik: baslik,
                  youtubeId: yId,
                  tumVideolarJson: allVideos,
                ),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Video Görsel Üst Alanı
                Stack(
                  alignment: Alignment.center,
                  children: [
                    _buildThumbnail(yId, data['kapakYolu']),

                    // Cam Efektli (Glassmorphism) Modern Oynat Butonu
                    ClipRRect(
                      borderRadius: BorderRadius.circular(100),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.25),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white.withOpacity(0.4), width: 1.5)
                          ),
                          child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 36),
                        ),
                      ),
                    ),

                    // Sağ Üst Köşe Sevecekleri Süre Rozeti
                    Positioned(
                      top: 14,
                      right: 14,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            color: Colors.black.withOpacity(0.4),
                            child: Row(
                              children: [
                                const Icon(Icons.timer_outlined, size: 12, color: Colors.amber),
                                const SizedBox(width: 4),
                                Text(
                                  sure,
                                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                // Alt Başlık ve Bilgi Alanı
                Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        baslik,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 15.5,
                            color: Color(0xFF4A90E2),
                            letterSpacing: -0.2,
                            height: 1.3
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF3B82F6).withOpacity(0.08),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              "Siber Görev",
                              style: TextStyle(color: Color(0xFF3B82F6), fontSize: 10, fontWeight: FontWeight.w900),
                            ),
                          ),
                          Row(
                            children: [
                              Text(
                                  "İzlemek için dokun",
                                  style: TextStyle(color: Colors.blueGrey.shade400, fontSize: 11, fontWeight: FontWeight.bold)
                              ),
                              const SizedBox(width: 4),
                              Icon(Icons.arrow_forward_rounded, size: 12, color: Colors.blueGrey.shade300),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ).animate(delay: (index * 25).ms).fadeIn(duration: 300.ms).slideY(begin: 0.05, curve: Curves.easeOutQuad);
  }

  Widget _buildThumbnail(String yId, String? kapakYolu) {
    return CachedNetworkImage(
      imageUrl: "https://img.youtube.com/vi/$yId/maxresdefault.jpg",
      height: 175,
      width: double.infinity,
      fit: BoxFit.cover,
      errorWidget: (context, url, error) {
        if (kapakYolu != null && kapakYolu.isNotEmpty) {
          if (kapakYolu.startsWith('assets/')) {
            return Image.asset(kapakYolu, height: 175, width: double.infinity, fit: BoxFit.cover);
          } else {
            return CachedNetworkImage(
              imageUrl: kapakYolu,
              height: 175,
              width: double.infinity,
              fit: BoxFit.cover,
              errorWidget: (c, e, s) => _buildPlaceholder(),
            );
          }
        }
        return _buildPlaceholder();
      },
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      height: 175,
      width: double.infinity,
      color: const Color(0xFFE2E8F0),
      child: const Icon(Icons.video_library_rounded, size: 40, color: Color(0xFF94A3B8)),
    );
  }

  // Yükleme Sırasında Gösterilecek Şık Shimmer (İskelet Efekt) Yapısı
  Widget _buildShimmerLoading() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(22, 12, 22, 100),
      itemCount: 3,
      itemBuilder: (context, index) {
        return Container(
          margin: const EdgeInsets.only(bottom: 22),
          height: 265,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 175,
                decoration: const BoxDecoration(
                  color: Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(height: 16, width: double.infinity, color: const Color(0xFFE2E8F0)),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(height: 14, width: 70, color: const Color(0xFFE2E8F0)),
                        Container(height: 14, width: 100, color: const Color(0xFFE2E8F0)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ).animate(onPlay: (c) => c.repeat(reverse: true)).shimmer(duration: 1200.ms, color: Colors.grey.shade100);
      },
    );
  }
}