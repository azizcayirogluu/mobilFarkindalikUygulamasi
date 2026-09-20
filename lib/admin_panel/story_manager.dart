import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class StoryManager extends StatefulWidget {
  const StoryManager({super.key});

  @override
  State<StoryManager> createState() => _StoryManagerState();
}

class _StoryManagerState extends State<StoryManager> {
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
            Expanded(child: _buildStoryGrid()),
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
            Text("Hikaye Yönetim Ekranı", style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
            Text("Çocukların okuma listesindeki içerikleri yönetin ve yeni öyküler ekleyin.", style: TextStyle(color: Colors.blueGrey, fontSize: 14)),
          ],
        ),
        ElevatedButton.icon(
          onPressed: () => _showStoryEditor(),
          icon: const Icon(Icons.add_photo_alternate_rounded),
          label: const Text("YENİ ÖYKÜ KALEME AL"),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFF59E0B),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ],
    );
  }

  Widget _buildStoryGrid() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore.collection('stories').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final docs = snapshot.data!.docs;
        return GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3, crossAxisSpacing: 20, mainAxisSpacing: 20, childAspectRatio: 0.9,
          ),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            return _buildStoryCard(docs[index].id, data);
          },
        );
      },
    );
  }

  Widget _buildStoryCard(String id, Map<String, dynamic> data) {
    final String? imageUrl = data['gorselYolu']?.toString();
    final bool hasValidUrl = imageUrl != null && imageUrl.startsWith('http');

    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFFE2E8F0))),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Stack(
              children: [
                SizedBox(
                  width: double.infinity,
                  height: double.infinity,
                  child: hasValidUrl
                      ? Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Container(
                              color: Colors.grey.shade100,
                              child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) {
                            debugPrint("Görsel yükleme hatası: $error");
                            return Container(
                              color: Colors.grey.shade100,
                              child: const Icon(Icons.broken_image_rounded, color: Colors.grey, size: 40),
                            );
                          },
                        )
                      : Container(
                          color: Colors.grey.shade100,
                          child: const Icon(Icons.menu_book_rounded, color: Colors.grey, size: 50),
                        ),
                ),
                Positioned(
                  top: 10, right: 10,
                  child: Row(
                    children: [
                      _miniCircleBtn(Icons.edit_note_rounded, Colors.blue, () => _showStoryEditor(docId: id, existingData: data)),
                      const SizedBox(width: 8),
                      _miniCircleBtn(Icons.delete_outline_rounded, Colors.redAccent, () => _deleteStory(id)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(data['baslik'] ?? "İsimsiz Öykü", style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16), maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Text(data['feedbackMessage'] ?? "Dönüt mesajı yok.", maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.blueGrey.shade400, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _miniCircleBtn(IconData i, Color c, VoidCallback o) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 5)]),
      child: IconButton(onPressed: o, icon: Icon(i, color: c, size: 18), constraints: const BoxConstraints(), padding: const EdgeInsets.all(8)),
    );
  }

  void _showStoryEditor({String? docId, Map<String, dynamic>? existingData}) {
    final titleC = TextEditingController(text: existingData?['baslik']);
    final contentC = TextEditingController(text: existingData?['hikayeMetni'] ?? existingData?['icerik']);
    final imageC = TextEditingController(text: existingData?['gorselYolu']);
    final feedbackC = TextEditingController(text: existingData?['feedbackMessage']);

    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(docId == null ? "Yeni Öykü Kaleme Al" : "Öyküyü Düzenle", style: const TextStyle(fontWeight: FontWeight.bold)),
        content: SizedBox(
          width: 600,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: titleC, decoration: const InputDecoration(labelText: "Öykü Başlığı", hintText: "Örn: Cesur Kaplumbağa")),
                const SizedBox(height: 10),
                TextField(controller: imageC, decoration: const InputDecoration(labelText: "Görsel URL (Opsiyonel)", hintText: "https://... ")),
                const SizedBox(height: 10),
                TextField(
                  controller: contentC, 
                  maxLines: 8, 
                  decoration: const InputDecoration(
                    labelText: "Hikaye Metni", 
                    hintText: "Hikayeyi buraya yazın. Sayfalar için iki kez Enter (boş satır) bırakın.",
                    alignLabelWithHint: true,
                    border: OutlineInputBorder(),
                  )
                ),
                const SizedBox(height: 10),
                TextField(controller: feedbackC, decoration: const InputDecoration(labelText: "Kahraman Notu (Dönüt)", hintText: "Hikaye bitince verilecek ders...")),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c), child: const Text("İptal")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF59E0B), foregroundColor: Colors.white),
            onPressed: () async {
              final data = {
                'baslik': titleC.text,
                'hikayeMetni': contentC.text,
                'gorselYolu': imageC.text,
                'feedbackMessage': feedbackC.text,
                'eklenmeTarihi': existingData?['eklenmeTarihi'] ?? FieldValue.serverTimestamp(),
              };

              if (docId == null) {
                await _firestore.collection('stories').add(data);
              } else {
                await _firestore.collection('stories').doc(docId).update(data);
              }
              Navigator.pop(c);
            },
            child: const Text("Kütüphaneye Kaydet"),
          ),
        ],
      ),
    );
  }

  void _deleteStory(String id) {
    showDialog(context: context, builder: (c) => AlertDialog(
      title: const Text("Öyküyü Sil"),
      content: const Text("Bu öyküyü silmek istediğine emin misin?"),
      actions: [
        TextButton(onPressed: () => Navigator.pop(c), child: const Text("Vazgeç")),
        ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.red), 
            onPressed: () { _firestore.collection('stories').doc(id).delete(); Navigator.pop(c); }, 
            child: const Text("SİL")),
      ],
    ));
  }
}
