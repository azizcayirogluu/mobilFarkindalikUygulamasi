import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:zorbalik_uygulamasi/app_theme.dart';

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
      backgroundColor: AppColors.zemin,
      body: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 30),
            _buildQuickStoryStats(),
            const SizedBox(height: 25),

            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _firestore.collection('stories').snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                  final docs = snapshot.data!.docs;

                  if (docs.isEmpty) return _buildEmptyState();

                  return GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 20,
                      mainAxisSpacing: 20,
                      childAspectRatio: 0.85,
                    ),
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      final data = docs[index].data() as Map<String, dynamic>;
                      final docId = docs[index].id;

                      return _buildStoryCard(docId, data);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text("HİKAYE KÜTÜPHANESİ",
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: AppColors.yaziRengi)),
          const Text("Eğitici hikayeleri ve içerik metinlerini buradan yönetin.",
              style: TextStyle(color: Colors.blueGrey)),
        ]),
        ElevatedButton.icon(
          onPressed: () => _showStoryDialog(),
          icon: const Icon(Icons.add_to_photos_rounded),
          label: const Text("YENİ HİKAYE EKLE"),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.uyariTuruncusu,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 22),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 5,
          ),
        ),
      ],
    );
  }

  // --- HİKAYE KARTLARI ---
  Widget _buildStoryCard(String docId, Map<String, dynamic> data) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 5,
            child: Stack(
              children: [
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppColors.uyariTuruncusu.withOpacity(0.1),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                  ),
                  child: data['gorselYolu'] != null && data['gorselYolu'].toString().isNotEmpty
                      ? ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                    child: Image.network(data['gorselYolu'], fit: BoxFit.cover, errorBuilder: (c, e, s) => const Icon(Icons.broken_image_rounded, size: 40)),
                  )
                      : const Icon(Icons.auto_stories_rounded, size: 50, color: AppColors.uyariTuruncusu),
                ),
                Positioned(
                  top: 15, right: 15,
                  child: Row(
                    children: [
                      _miniActionBtn(Icons.edit_rounded, Colors.blue, () => _showStoryDialog(docId: docId, existingData: data)),
                      const SizedBox(width: 8),
                      _miniActionBtn(Icons.delete_outline_rounded, Colors.redAccent, () => _deleteStory(docId)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 4,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(data['baslik'] ?? "İsimsiz",
                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: AppColors.yaziRengi)),
                  const SizedBox(height: 8),
                  Text(data['altBaslik'] ?? "Özet bulunmuyor...",
                      maxLines: 2, overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 13, height: 1.4)),
                  const Spacer(),
                  Row(
                    children: [
                      const Icon(Icons.notes_rounded, size: 14, color: Colors.grey),
                      const SizedBox(width: 5),
                      Text("${(data['hikayeMetni'] ?? '').toString().split(' ').length} Kelime",
                          style: const TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold)),
                    ],
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  void _showStoryDialog({String? docId, Map<String, dynamic>? existingData}) {
    final tC = TextEditingController(text: existingData?['baslik']);
    final sC = TextEditingController(text: existingData?['altBaslik']);
    final iC = TextEditingController(text: existingData?['gorselYolu']);
    final mC = TextEditingController(text: existingData?['hikayeMetni']);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        child: Container(
          width: 900, height: 800,
          padding: const EdgeInsets.all(32),
          child: Column(
            children: [
              _buildDialogHeader(docId == null ? "Yeni Hikaye Oluştur" : "Hikayeyi Güncelle"),
              const SizedBox(height: 24),
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 2,
                      child: Column(
                        children: [
                          _buildField(tC, "Hikaye Başlığı", Icons.title_rounded),
                          const SizedBox(height: 15),
                          _buildField(sC, "Kısa Özet / Alt Başlık", Icons.short_text_rounded),
                          const SizedBox(height: 15),
                          _buildField(iC, "Kapak Görseli URL", Icons.image_search_rounded),
                          const SizedBox(height: 20),
                          _buildImagePreview(iC),
                        ],
                      ),
                    ),
                    const SizedBox(width: 30),
                    Expanded(
                      flex: 3,
                      child: _buildRichTextField(mC),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              _buildDialogActions(docId, tC, sC, iC, mC),
            ],
          ),
        ),
      ),
    );
  }

  // --- UI YARDIMCILARI ---
  Widget _buildField(TextEditingController controller, String label, IconData icon) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label, prefixIcon: Icon(icon, color: AppColors.uyariTuruncusu),
        filled: true, fillColor: AppColors.zemin.withOpacity(0.4),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
      ),
    );
  }

  Widget _buildRichTextField(TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("HİKAYE METNİ", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1.2, color: Colors.blueGrey)),
        const SizedBox(height: 10),
        Expanded(
          child: TextFormField(
            controller: controller,
            maxLines: null, expands: true,
            textAlignVertical: TextAlignVertical.top,
            decoration: InputDecoration(
              hintText: "Hikayeyi buraya yazmaya başlayın...",
              filled: true, fillColor: Colors.grey.shade50,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide(color: Colors.grey.shade200)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickStoryStats() {
    return Row(
      children: [
        _miniStatCard("Toplam Hikaye Sayısı ", "stories", Icons.auto_stories_rounded, AppColors.uyariTuruncusu),
        const SizedBox(width: 15),
      ],
    );
  }

  Widget _miniStatCard(String title, String collection, IconData icon, Color color, {bool isReadStat = false}) {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore.collection(collection).snapshots(),
      builder: (context, snapshot) {
        String val = "...";
        if (snapshot.hasData) {
          if (isReadStat) {
            int total = 0;
            for (var d in snapshot.data!.docs) {
              final List okunanlar = (d.data() as Map<String, dynamic>)['okunan_hikayeler'] as List? ?? [];
              total += okunanlar.length;
            }
            val = total.toString();
          } else {
            val = snapshot.data!.docs.length.toString();
          }
        }
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), border: Border.all(color: color.withOpacity(0.1))),
          child: Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 12),
              Text("$title: ", style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              Text(val, style: TextStyle(fontWeight: FontWeight.w900, color: color, fontSize: 16)),
            ],
          ),
        );
      },
    );
  }

  Widget _miniActionBtn(IconData icon, Color color, VoidCallback onTap) {
    return IconButton(
      onPressed: onTap,
      icon: Icon(icon, color: color, size: 18),
      style: IconButton.styleFrom(backgroundColor: Colors.white, shadowColor: Colors.black26, elevation: 4),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.menu_book_rounded, size: 80, color: Colors.grey.shade300),
        const Text("Henüz kütüphanede hikaye yok.", style: TextStyle(color: Colors.grey)),
      ]),
    );
  }

  // --- CRUD İŞLEMLERİ ---
  Widget _buildDialogActions(String? docId, TextEditingController t, TextEditingController s, TextEditingController i, TextEditingController m) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text("Vazgeç", style: TextStyle(color: Colors.grey))),
        const SizedBox(width: 15),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.uyariTuruncusu, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20)),
          onPressed: () async {
            final data = {'baslik': t.text, 'altBaslik': s.text, 'gorselYolu': i.text, 'hikayeMetni': m.text, 'renk': '0xFFFFB74D', 'ikon': 'auto_stories'};
            if (docId == null) await _firestore.collection('stories').add(data);
            else await _firestore.collection('stories').doc(docId).update(data);
            Navigator.pop(context);
          },
          child: const Text("HİKAYEYİ KAYDET", style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  Widget _buildDialogHeader(String title) {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
      const CloseButton(),
    ]);
  }

  Widget _buildImagePreview(TextEditingController iC) {
    return ValueListenableBuilder(
        valueListenable: iC,
        builder: (context, value, child) {
          return Container(
            height: 150, width: double.infinity,
            decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.grey.shade300, style: BorderStyle.none)),
            child: iC.text.isNotEmpty
                ? ClipRRect(borderRadius: BorderRadius.circular(15), child: Image.network(iC.text, fit: BoxFit.cover, errorBuilder: (c,e,s) => const Center(child: Text("Görsel Yüklenemedi"))))
                : const Center(child: Icon(Icons.image_outlined, color: Colors.grey, size: 40)),
          );
        }
    );
  }

  void _deleteStory(String id) {
    showDialog(context: context, builder: (c) => AlertDialog(
      title: const Text("Hikayeyi Sil"),
      content: const Text("Bu hikaye kalıcı olarak silinecektir. Onaylıyor musunuz?"),
      actions: [
        TextButton(onPressed: () => Navigator.pop(c), child: const Text("İptal")),
        ElevatedButton(onPressed: () { _firestore.collection('stories').doc(id).delete(); Navigator.pop(c); }, child: const Text("Sil")),
      ],
    ));
  }
}