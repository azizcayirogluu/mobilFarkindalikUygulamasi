import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:zorbalik_uygulamasi/screens/video_detay_ekrani.dart';
import 'package:flutter_animate/flutter_animate.dart';

class VideoListelemeEkrani extends StatelessWidget {
  const VideoListelemeEkrani({super.key});

  @override
  Widget build(BuildContext context) {
    const Color backgroundSubtle = Color(0xFFF8FAFC);
    final bottomInset = MediaQuery.paddingOf(context).bottom + 40;

    return Scaffold(
      backgroundColor: backgroundSubtle,
      appBar: AppBar(
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "EĞİTİCİ VİDEOLAR 🎥",
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 18,
            color: Color(0xFF1E293B),
            letterSpacing: 1.2,
          ),
        ),
        leading: Padding(
          padding: const EdgeInsets.only(left: 12),
          child: Center(
            child: Container(
              width: 38,
              height: 38,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: Color(0x0F000000), blurRadius: 10, offset: Offset(0, 4)),
                ],
              ),
              child: IconButton(
                padding: EdgeInsets.zero,
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: Color(0xFF475569)),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('videos').limit(20).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildShimmerLoading(bottomInset);
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return _buildEmptyState();
          }

          var videoDocs = snapshot.data!.docs;
          List<dynamic> allVideosJson = videoDocs.map((e) => e.data() as Map<String, dynamic>).toList();

          return ListView.builder(
            padding: EdgeInsets.fromLTRB(20, 12, 20, bottomInset),
            physics: const BouncingScrollPhysics(),
            itemCount: videoDocs.length,
            itemBuilder: (context, index) {
              var data = videoDocs[index].data() as Map<String, dynamic>;
              return _buildVideoCard(context, data, allVideosJson, index);
            },
          );
        },
      ),
    );
  }

  Widget _buildVideoCard(BuildContext context, Map<String, dynamic> data, List<dynamic> allVideos, int index) {
    String yId = data['youtubeId']?.toString() ?? "";
    String baslik = data['baslik'] ?? "Eğitici Video";
    String sure = data['sure'] ?? "5 Dakika";

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A0F172A),
            blurRadius: 16,
            offset: Offset(0, 6),
          )
        ],
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
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
                    Positioned.fill(child: Container(color: Colors.black.withAlpha(25))),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(50),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white.withAlpha(100), width: 1.5),
                      ),
                      child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 36),
                    ),
                    Positioned(
                      top: 12,
                      right: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withAlpha(150),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
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
                  ],
                ),

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
                          fontSize: 15,
                          color: Color(0xFF1E293B),
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF6366F1).withAlpha(20),
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
                                style: TextStyle(color: Color(0xFF64748B), fontSize: 11, fontWeight: FontWeight.w800),
                              ),
                              SizedBox(width: 4),
                              Icon(Icons.chevron_right_rounded, size: 16, color: Color(0xFF94A3B8)),
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
      height: 180,
      width: double.infinity,
      fit: BoxFit.cover,
      errorWidget: (context, url, error) {
        if (kapakYolu != null && kapakYolu.isNotEmpty) {
          if (kapakYolu.startsWith('assets/')) {
            return Image.asset(kapakYolu, height: 180, width: double.infinity, fit: BoxFit.cover);
          }
          return CachedNetworkImage(
            imageUrl: kapakYolu,
            height: 180,
            width: double.infinity,
            fit: BoxFit.cover,
            errorWidget: (c, u, e) => _buildPlaceholder(),
          );
        }
        return _buildPlaceholder();
      },
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      height: 180,
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
            padding: const EdgeInsets.all(28),
            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Color(0x0D4F46E5), blurRadius: 20)]),
            child: const Icon(Icons.movie_filter_rounded, size: 56, color: Color(0xFFCBD5E1)),
          ),
          const SizedBox(height: 20),
          const Text("Henüz Video Yok!", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF475569))),
          const SizedBox(height: 8),
          const Text("Eğitici videolar çok yakında burada olacak.", style: TextStyle(fontSize: 14, color: Color(0xFF94A3B8), fontWeight: FontWeight.w500)),
        ],
      ).animate().fadeIn().scale(begin: const Offset(0.9, 0.9)),
    );
  }

  Widget _buildShimmerLoading(double bottomInset) {
    return ListView.builder(
      padding: EdgeInsets.fromLTRB(20, 12, 20, bottomInset),
      itemCount: 3,
      itemBuilder: (context, index) {
        return Container(
          margin: const EdgeInsets.only(bottom: 20),
          height: 260,
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(height: 180, decoration: const BoxDecoration(color: Color(0xFFF1F5F9), borderRadius: BorderRadius.vertical(top: Radius.circular(24)))),
              Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(height: 16, width: double.infinity, color: const Color(0xFFF1F5F9)),
                    const SizedBox(height: 10),
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Container(height: 12, width: 80, color: const Color(0xFFF1F5F9)), Container(height: 12, width: 100, color: const Color(0xFFF1F5F9))]),
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
