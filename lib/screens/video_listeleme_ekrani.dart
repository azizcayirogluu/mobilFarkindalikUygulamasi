import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:zorbalik_uygulamasi/app_theme.dart';
import 'package:zorbalik_uygulamasi/screens/video_detay_ekrani.dart';

class VideoListelemeEkrani extends StatelessWidget {
  const VideoListelemeEkrani({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.zemin,
      appBar: AppBar(
        title: const Text("EĞİTİCİ VİDEOLAR",
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: AppColors.yaziRengi)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.yaziRengi),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      // Firestore'daki 'videos' koleksiyonunu anlık olarak çek
      body: StreamBuilder<QuerySnapshot>(
        //Sorguyu ilk 20 video ile sınırlandırarak veri tasarrufu sağla
        stream: FirebaseFirestore.instance.collection('videos').limit(20).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("Henüz video eklenmemiş."));
          }

          var videos = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 100),
            physics: const BouncingScrollPhysics(), // iOS tarzı esnek kaydırma efekti
            itemCount: videos.length,
            itemBuilder: (context, index) {
              var data = videos[index].data() as Map<String, dynamic>;
              // Kart oluşturulurken tüm video listesi, detay sayfasındaki "sıradakiler" için gönder
              return _buildVideoCard(context, data, videos.map((e) => e.data()).toList());
            },
          );
        },
      ),
    );
  }

  // Kullanıcının videoya tıklayarak detay sayfasına gitmesini sağlayan kart.
  Widget _buildVideoCard(BuildContext context, Map<String, dynamic> data, List allVideos) {
    String yId = data['youtubeId']?.toString() ?? "";

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 8))],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(25),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (c) => VideoDetayEkrani(
              baslik: data['baslik'] ?? "Eğitici Video",
              youtubeId: yId,
              tumVideolarJson: allVideos,
            ),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Video önizlemesi ve üzerindeki oynat butonu simgesi.
            Stack(
              alignment: Alignment.center,
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
                  child: _buildThumbnail(yId, data['kapakYolu']),
                ),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: Colors.black.withOpacity(0.3), shape: BoxShape.circle),
                  child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 40),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(15),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(data['baslik'] ?? "İsimsiz Video",
                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: AppColors.yaziRengi)),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      const Icon(Icons.timer_outlined, size: 14, color: Colors.grey),
                      const SizedBox(width: 5),
                      Text(data['sure'] ?? "5 Dakika", style: const TextStyle(color: Colors.grey, fontSize: 12)),
                      const Spacer(),
                      Text("İzlemek için dokun", style: TextStyle(color: AppColors.anaMavi.withOpacity(0.8), fontSize: 11, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Öncelikli olarak YouTube'dan çekmeyi dener, hata oluşursa yerel/uzak kapak yoluna geçer.
  Widget _buildThumbnail(String yId, String? kapakYolu) {
    return Image.network(
      "https://img.youtube.com/vi/$yId/maxresdefault.jpg",
      height: 180,
      width: double.infinity,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        // YouTube görseli yüklenemezse yedek görseli kontrol et.
        if (kapakYolu != null && kapakYolu.isNotEmpty) {
          if (kapakYolu.startsWith('assets/')) {
            return Image.asset(
              kapakYolu,
              height: 180,
              width: double.infinity,
              fit: BoxFit.cover,
            );
          } else {
            return Image.network(
              kapakYolu,
              height: 180,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (c, e, s) => _buildPlaceholder(),
            );
          }
        }
        return _buildPlaceholder();
      },
    );
  }

  // Hiçbir görsel kaynağı bulunamazsa gösterilecek standart gri alan.
  Widget _buildPlaceholder() {
    return Container(
        height: 180,
        width: double.infinity,
        color: Colors.grey[200],
        child: const Icon(Icons.play_circle_outline, size: 50, color: Colors.grey)
    );
  }
}