import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';

class VideoManager extends StatefulWidget {
  const VideoManager({super.key});

  @override
  State<VideoManager> createState() => _VideoManagerState();
}

class _VideoManagerState extends State<VideoManager> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProHeader(),
            const SizedBox(height: 40),
            Expanded(child: _buildVideoGrid()),
          ],
        ),
      ),
    );
  }

  Widget _buildProHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Video Yönetim Ekranı", style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
            Text("Multimedya içeriklerini ve YouTube entegrasyonlarını buradan yönetin.", style: TextStyle(color: Colors.blueGrey, fontSize: 14)),
          ],
        ),
        ElevatedButton.icon(
          onPressed: () => _showVideoStudio(),
          icon: const Icon(Icons.video_call_rounded),
          label: const Text("YENİ İÇERİK YÜKLE"),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.redAccent,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ],
    );
  }

  Widget _buildVideoGrid() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore.collection('videos').orderBy('eklenmeTarihi', descending: true).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final docs = snapshot.data!.docs;
        return GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3, crossAxisSpacing: 20, mainAxisSpacing: 20, childAspectRatio: 1.1,
          ),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            final String videoId = data['youtubeId'] ?? "";
            return _buildVideoCard(docs[index].id, data, videoId);
          },
        );
      },
    );
  }

  Widget _buildVideoCard(String id, Map<String, dynamic> data, String vid) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFFE2E8F0))),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Expanded(
            flex: 3,
            child: Stack(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: vid.isNotEmpty 
                      ? CachedNetworkImage(imageUrl: 'https://img.youtube.com/vi/$vid/0.jpg', fit: BoxFit.cover, errorWidget: (c,u,e) => Container(color: Colors.grey.shade100))
                      : Container(color: Colors.grey.shade100, child: const Icon(Icons.videocam_off_rounded, color: Colors.grey)),
                ),
                const Center(child: Icon(Icons.play_circle_fill_rounded, color: Colors.white, size: 50)),
                Positioned(top: 10, right: 10, child: _miniBtn(Icons.delete_sweep_rounded, Colors.white, () => _deleteVideo(id))),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.all(15),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(data['baslik'] ?? "Başlıksız", style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15), maxLines: 1, overflow: TextOverflow.ellipsis),
                  Text("${data['sure'] ?? '00:00'} • ${data['altBaslik'] ?? ''}", style: TextStyle(color: Colors.blueGrey.shade400, fontSize: 11)),
                  const Spacer(),
                  Align(alignment: Alignment.centerRight, child: TextButton(onPressed: () => _showVideoStudio(docId: id, existingData: data), child: const Text("Düzenle"))),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _miniBtn(IconData i, Color c, VoidCallback o) {
    return Container(
      decoration: BoxDecoration(color: Colors.black26, shape: BoxShape.circle),
      child: IconButton(onPressed: o, icon: Icon(i, color: c, size: 20), constraints: const BoxConstraints()),
    );
  }

  void _showVideoStudio({String? docId, Map<String, dynamic>? existingData}) {
    final titleC = TextEditingController(text: existingData?['baslik']);
    final subC = TextEditingController(text: existingData?['altBaslik']);
    final ytC = TextEditingController(text: existingData?['youtubeId']);
    final timeC = TextEditingController(text: existingData?['sure']);

    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(docId == null ? "Yeni Video Yükle" : "Videoyu Düzenle", style: const TextStyle(fontWeight: FontWeight.bold)),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: titleC, decoration: const InputDecoration(labelText: "Video Başlığı", hintText: "Örn: Siber Zorbalık Nedir?")),
              TextField(controller: subC, decoration: const InputDecoration(labelText: "Alt Başlık", hintText: "Örn: Eğitici Animasyon")),
              TextField(controller: ytC, decoration: const InputDecoration(labelText: "YouTube Video ID", hintText: "Örn: dQw4w9WgXcQ")),
              TextField(controller: timeC, decoration: const InputDecoration(labelText: "Süre", hintText: "Örn: 04:20")),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c), child: const Text("İptal")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F172A), foregroundColor: Colors.white),
            onPressed: () async {
              final data = {
                'baslik': titleC.text,
                'altBaslik': subC.text,
                'youtubeId': ytC.text,
                'sure': timeC.text,
                'eklenmeTarihi': existingData?['eklenmeTarihi'] ?? FieldValue.serverTimestamp(),
              };

              if (docId == null) {
                await _firestore.collection('videos').add(data);
              } else {
                await _firestore.collection('videos').doc(docId).update(data);
              }
              Navigator.pop(c);
            },
            child: const Text("Sisteme Kaydet"),
          ),
        ],
      ),
    );
  }

  void _deleteVideo(String id) {
    showDialog(context: context, builder: (c) => AlertDialog(
      title: const Text("Videoyu Sil"),
      content: const Text("Bu videoyu silmek istediğine emin misin? Bu işlem geri alınamaz."),
      actions: [
        TextButton(onPressed: () => Navigator.pop(c), child: const Text("Vazgeç")),
        ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.red), 
            onPressed: () { _firestore.collection('videos').doc(id).delete(); Navigator.pop(c); }, 
            child: const Text("SİL")),
      ],
    ));
  }
}
