import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:zorbalik_uygulamasi/screens/video_detay_ekrani.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:ui';
import 'dart:math' as math;

class VideoListelemeEkrani extends StatelessWidget {
  const VideoListelemeEkrani({super.key});

  @override
  Widget build(BuildContext context) {
    const Color backgroundSubtle = Color(0xFFF8FAFC); // Diğer ekranlarla uyumlu ferah zemin

    return Scaffold(
      backgroundColor: backgroundSubtle,
      appBar: AppBar(
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        toolbarHeight: 90,
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: const Padding(
          padding: EdgeInsets.only(top: 25),
          child: Text(
            "EĞİTİCİ VİDEOLAR 🎥",
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 18,
              color: Color(0xFF1E293B),
              letterSpacing: 1.5
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
                BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4)),
              ],
            ),
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: Color(0xFF475569)),
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
              decoration: BoxDecoration(shape: BoxShape.circle, color: const Color(0xFF6366F1).withOpacity(0.03)),
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
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(35), color: Colors.orange.withOpacity(0.02)),
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
                return _buildEmptyState();
              }

              var videoDocs = snapshot.data!.docs;
              List<dynamic> allVideosJson = videoDocs.map((e) => e.data() as Map<String, dynamic>).toList();

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
        border: Border.all(color: const Color(0xFFF1F5F9), width: 1.5),
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
                Stack(
                  alignment: Alignment.center,
                  children: [
                    _buildThumbnail(yId, data['kapakYolu']),
                    
                    // Video Karartma Filtresi
                    Positioned.fill(child: Container(color: Colors.black.withOpacity(0.1))),

                    // Cam Efektli Modern Oynat Butonu
                    ClipRRect(
                      borderRadius: BorderRadius.circular(100),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white.withOpacity(0.4), width: 1.5)
                          ),
                          child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 40),
                        ),
                      ),
                    ),

                    // Süre Rozeti
                    Positioned(
                      top: 14,
                      right: 14,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            color: Colors.black.withOpacity(0.5),
                            child: Row(
                              children: [
                                const Icon(Icons.timer_outlined, size: 12, color: Colors.amber),
                                const SizedBox(width: 4),
                                Text(
                                  sure,
                                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        baslik,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                            color: Color(0xFF1E293B),
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
                              color: const Color(0xFF6366F1).withOpacity(0.08),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              "SİBER GÖREV",
                              style: TextStyle(color: Color(0xFF6366F1), fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                            ),
                          ),
                          const Row(
                            children: [
                              Text(
                                  "Hemen İzle",
                                  style: TextStyle(color: Color(0xFF64748B), fontSize: 11, fontWeight: FontWeight.w800)
                              ),
                              SizedBox(width: 4),
                              Icon(Icons.arrow_forward_ios_rounded, size: 10, color: Color(0xFF94A3B8)),
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
    ).animate(delay: (index * 20).ms).fadeIn(duration: 400.ms).slideY(begin: 0.05, curve: Curves.easeOutQuad);
  }

  Widget _buildThumbnail(String yId, String? kapakYolu) {
    return CachedNetworkImage(
      imageUrl: "https://img.youtube.com/vi/$yId/maxresdefault.jpg",
      height: 185,
      width: double.infinity,
      fit: BoxFit.cover,
      errorWidget: (context, url, error) {
        if (kapakYolu != null && kapakYolu.isNotEmpty) {
          if (kapakYolu.startsWith('assets/')) {
            return Image.asset(kapakYolu, height: 185, width: double.infinity, fit: BoxFit.cover);
          }
          return CachedNetworkImage(imageUrl: kapakYolu, height: 185, width: double.infinity, fit: BoxFit.cover, errorWidget: (_,__,___) => _buildPlaceholder());
        }
        return _buildPlaceholder();
      },
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      height: 185,
      width: double.infinity,
      color: const Color(0xFFF1F5F9),
      child: const Icon(Icons.video_library_rounded, size: 40, color: Color(0xFFCBD5E1)),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.indigo.withOpacity(0.05), blurRadius: 20)]),
            child: const Icon(Icons.movie_filter_rounded, size: 60, color: Color(0xFFCBD5E1)),
          ),
          const SizedBox(height: 24),
          const Text("Henüz Video Yok!", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF475569))),
          const SizedBox(height: 8),
          const Text("Eğitici videolar çok yakında burada olacak.", style: TextStyle(fontSize: 14, color: Color(0xFF94A3B8), fontWeight: FontWeight.w500)),
        ],
      ).animate().fadeIn().scale(begin: const Offset(0.9, 0.9)),
    );
  }

  Widget _buildShimmerLoading() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(22, 12, 22, 100),
      itemCount: 3,
      itemBuilder: (context, index) {
        return Container(
          margin: const EdgeInsets.only(bottom: 22),
          height: 280,
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(28)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(height: 185, decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: const BorderRadius.vertical(top: Radius.circular(28)))),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(height: 18, width: double.infinity, color: const Color(0xFFF1F5F9)),
                    const SizedBox(height: 12),
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Container(height: 14, width: 80, color: const Color(0xFFF1F5F9)), Container(height: 14, width: 100, color: const Color(0xFFF1F5F9))]),
                  ],
                ),
              ),
            ],
          ),
        ).animate(onPlay: (c) => c.repeat(reverse: true)).shimmer(duration: 1.seconds, color: const Color(0xFFF8FAFC));
      },
    );
  }
}
