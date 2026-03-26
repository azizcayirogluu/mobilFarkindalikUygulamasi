import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:zorbalik_uygulamasi/app_theme.dart';

class ScenarioManager extends StatefulWidget {
  const ScenarioManager({super.key});

  @override
  State<ScenarioManager> createState() => _ScenarioManagerState();
}

class _ScenarioManagerState extends State<ScenarioManager> {
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
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _firestore.collection('scenarios').snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                  final docs = snapshot.data!.docs;

                  return ListView.builder(
                    physics: const BouncingScrollPhysics(),
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      final data = docs[index].data() as Map<String, dynamic>;
                      final docId = docs[index].id;
                      final bolumler = (data['bolumler'] as List? ?? []);

                      return Container(
                        margin: const EdgeInsets.only(bottom: 24),
                        decoration: _cardDecoration(),
                        child: Theme(
                          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                          child: ExpansionTile(
                            tilePadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            leading: _buildLeadingIcon(data['renk']),
                            title: Text(data['baslik'] ?? "İsimsiz Senaryo",
                                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20)),
                            subtitle: _buildScenarioSubtitle(bolumler.length, data['altBaslik']),
                            trailing: _buildMainActions(docId, data),
                            children: [
                              _buildChapterContainer(docId, bolumler),
                            ],
                          ),
                        ),
                      );
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
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("SENARYO MİMARI",
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: AppColors.yaziRengi)),
            const Text("Eğitici içerikleri ve interaktif soruları buradan yönetin.",
                style: TextStyle(color: Colors.blueGrey)),
          ],
        ),
        ElevatedButton.icon(
          onPressed: () => _showScenarioDialog(),
          icon: const Icon(Icons.add_to_photos_rounded),
          label: const Text("YENİ SENARYO OLUŞTUR"),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.anaMavi,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 22),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 8,
            shadowColor: AppColors.anaMavi.withOpacity(0.4),
          ),
        ),
      ],
    );
  }

  Widget _buildScenarioSubtitle(int chapterCount, String? subtitle) {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Row(
        children: [
          _badge("${chapterCount} Bölüm", AppColors.anaMavi),
          const SizedBox(width: 10),
          Expanded(child: Text(subtitle ?? '', maxLines: 1, overflow: TextOverflow.ellipsis,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13))),
        ],
      ),
    );
  }

  Widget _buildChapterContainer(String docId, List bolumler) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("BÖLÜMLER", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: Colors.blueGrey, letterSpacing: 1.2)),
          const SizedBox(height: 15),
          ...List.generate(bolumler.length, (bIndex) {
            return _buildChapterItem(docId, bIndex, bolumler);
          }),
          const SizedBox(height: 15),
          _addNewChapterBtn(docId, bolumler),
        ],
      ),
    );
  }

  Widget _buildChapterItem(String docId, int bIndex, List currentBolumler) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: AppColors.zemin,
          child: Text("${bIndex + 1}", style: const TextStyle(color: AppColors.anaMavi, fontWeight: FontWeight.bold)),
        ),
        title: Text(currentBolumler[bIndex]['bolumAdi'] ?? 'Başlıksız Bölüm',
            style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text("${(currentBolumler[bIndex]['sorular'] as List? ?? []).length} Soru Yayında"),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _miniActionBtn(Icons.edit_note_rounded, Colors.blue, () => _showChapterEditor(docId, bIndex, currentBolumler)),
            const SizedBox(width: 8),
            _miniActionBtn(Icons.delete_outline_rounded, Colors.redAccent, () => _deleteChapter(docId, bIndex, currentBolumler)),
          ],
        ),
      ),
    );
  }

  // --- SORU EDİTÖRÜ---
  void _showChapterEditor(String docId, int bIndex, List currentBolumler) {
    Map<String, dynamic> chapter = Map<String, dynamic>.from(currentBolumler[bIndex]);
    List sorular = List.from(chapter['sorular'] ?? []);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              backgroundColor: AppColors.zemin,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              child: Container(
                width: MediaQuery.of(context).size.width * 0.8,
                height: MediaQuery.of(context).size.height * 0.9,
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    _buildEditorHeader(chapter['bolumAdi']),
                    const SizedBox(height: 24),
                    _buildChapterTitleField(chapter, (v) => chapter['bolumAdi'] = v),
                    const SizedBox(height: 24),
                    Expanded(
                      child: ListView.builder(
                        itemCount: sorular.length,
                        itemBuilder: (c, sIndex) => _buildSoruCard(sIndex, sorular[sIndex], () {
                          setDialogState(() => sorular.removeAt(sIndex));
                        }, setDialogState),
                      ),
                    ),
                    _buildEditorFooter(docId, chapter, sorular, currentBolumler, bIndex),
                  ],
                ),
              ),
            );
          }
      ),
    );
  }

  Widget _buildSoruCard(int index, Map soru, VoidCallback onDelete, StateSetter setState) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _badge("Soru ${index + 1}", AppColors.anaMavi),
              const Spacer(),
              IconButton(icon: const Icon(Icons.delete_sweep_rounded, color: Colors.redAccent), onPressed: onDelete),
            ],
          ),
          const SizedBox(height: 15),
          TextFormField(
            initialValue: soru['soru'],
            decoration: _inputDecoration("Soru Cümlesi", Icons.help_outline_rounded),
            onChanged: (v) => soru['soru'] = v,
          ),
          const SizedBox(height: 20),
          const Text("Seçenekler ve Dönütler", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey)),
          const SizedBox(height: 10),
          ...List.generate(soru['secenekler'].length, (optIndex) {
            var opt = soru['secenekler'][optIndex];
            return _buildOptionRow(opt, soru, setState);
          }),
        ],
      ),
    );
  }

  Widget _buildOptionRow(Map opt, Map soru, StateSetter setState) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        children: [
          Radio<bool>(
            value: true,
            groupValue: opt['dogru'],
            activeColor: AppColors.basariYesili,
            onChanged: (v) => setState(() {
              for (var o in soru['secenekler']) { o['dogru'] = false; }
              opt['dogru'] = true;
            }),
          ),
          Expanded(flex: 2, child: _smallField(opt, 'metin', "Seçenek...")),
          const SizedBox(width: 10),
          Expanded(flex: 3, child: _smallField(opt, 'feedback', "Seçilirse verilecek mesaj...")),
        ],
      ),
    );
  }

  // --- UI YARDIMCILAR ---
  InputDecoration _inputDecoration(String label, IconData icon) => InputDecoration(
    labelText: label,
    prefixIcon: Icon(icon, color: AppColors.anaMavi),
    filled: true,
    fillColor: AppColors.zemin.withOpacity(0.5),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: const BorderSide(color: AppColors.anaMavi, width: 2)),
  );

  Widget _smallField(Map opt, String key, String hint) {
    return TextFormField(
      initialValue: opt[key],
      style: const TextStyle(fontSize: 13),
      decoration: InputDecoration(
        hintText: hint,
        isDense: true,
        contentPadding: const EdgeInsets.all(12),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade200)),
      ),
      onChanged: (v) => opt[key] = v,
    );
  }

  Widget _badge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
      child: Text(text, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
    );
  }

  BoxDecoration _cardDecoration() => BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(20),
    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20, offset: const Offset(0, 10))],
    border: Border.all(color: Colors.white),
  );

  Widget _miniActionBtn(IconData icon, Color color, VoidCallback onTap) {
    return IconButton(
      onPressed: onTap,
      icon: Icon(icon, color: color, size: 20),
      style: IconButton.styleFrom(backgroundColor: color.withOpacity(0.1), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
    );
  }

  Widget _addNewChapterBtn(String docId, List currentBolumler) {
    return OutlinedButton.icon(
      onPressed: () => _addNewChapter(docId, currentBolumler),
      icon: const Icon(Icons.add_circle_outline),
      label: const Text("YENİ BÖLÜM EKLE"),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(double.infinity, 56),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        side: const BorderSide(color: AppColors.anaMavi, width: 2),
        foregroundColor: AppColors.anaMavi,
      ),
    );
  }

  // --- CRUD İŞLEMLERİ ---
  void _addNewChapter(String docId, List currentBolumler) async {
    currentBolumler.add({'bolumAdi': 'Yeni Bölüm', 'sorular': []});
    await _firestore.collection('scenarios').doc(docId).update({'bolumler': currentBolumler});
  }

  void _deleteChapter(String docId, int bIndex, List currentBolumler) {
    showDialog(context: context, builder: (c) => AlertDialog(
      title: const Text("Bölümü Sil"),
      content: const Text("Bu bölümü ve içindeki tüm soruları silmek istediğine emin misin?"),
      actions: [
        TextButton(onPressed: () => Navigator.pop(c), child: const Text("VAZGEÇ")),
        ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              currentBolumler.removeAt(bIndex);
              await _firestore.collection('scenarios').doc(docId).update({'bolumler': currentBolumler});
              Navigator.pop(c);
            }, child: const Text("SİL")),
      ],
    ));
  }

  Widget _buildEditorHeader(String title) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("BÖLÜM EDİTÖRÜ", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
            Text(title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
          ],
        ),
        const CloseButton(),
      ],
    );
  }

  Widget _buildChapterTitleField(Map chapter, Function(String) onChanged) {
    return TextFormField(
      initialValue: chapter['bolumAdi'],
      decoration: _inputDecoration("Bölüm Başlığı", Icons.title_rounded),
      onChanged: onChanged,
    );
  }

  Widget _buildEditorFooter(String docId, Map chapter, List sorular, List currentBolumler, int bIndex) {
    return Container(
      padding: const EdgeInsets.only(top: 24),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white, padding: const EdgeInsets.all(18)),
              onPressed: () => setState(() => sorular.add({
                'soru': 'Soru Metni?',
                'secenekler': [
                  {'metin': 'Seçenek 1', 'dogru': true, 'feedback': 'Bravo!'},
                  {'metin': 'Seçenek 2', 'dogru': false, 'feedback': 'Tekrar dene.'},
                ]
              })),
              icon: const Icon(Icons.add_circle),
              label: const Text("YENİ SORU EKLE"),
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.anaMavi, foregroundColor: Colors.white, padding: const EdgeInsets.all(18)),
              onPressed: () async {
                chapter['sorular'] = sorular;
                currentBolumler[bIndex] = chapter;
                await _firestore.collection('scenarios').doc(docId).update({'bolumler': currentBolumler});
                Navigator.pop(context);
              },
              icon: const Icon(Icons.save_rounded),
              label: const Text("TÜMÜNÜ KAYDET"),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeadingIcon(String? colorHex) {
    Color color = Color(int.parse(colorHex ?? "0xFF9575CD"));
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
      child: Icon(Icons.psychology_rounded, color: color, size: 28),
    );
  }

  Widget _buildMainActions(String docId, Map data) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _miniActionBtn(Icons.settings_suggest_rounded, Colors.grey, () => _showScenarioDialog(docId: docId, existingData: data.cast<String, dynamic>())),
        const SizedBox(width: 8),
        _miniActionBtn(Icons.delete_sweep_rounded, Colors.redAccent, () => _deleteScenario(docId)),
        const SizedBox(width: 12),
        const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.grey),
      ],
    );
  }

  void _showScenarioDialog({String? docId, Map<String, dynamic>? existingData}) {
    final titleController = TextEditingController(text: existingData?['baslik']);
    final subtitleController = TextEditingController(text: existingData?['altBaslik']);
    final colorController = TextEditingController(text: existingData?['renk'] ?? "0xFF9575CD");

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(docId == null ? "Yeni Senaryo Kartı" : "Senaryoyu Düzenle"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: titleController, decoration: const InputDecoration(labelText: "Senaryo Başlığı")),
            const SizedBox(height: 10),
            TextField(controller: subtitleController, decoration: const InputDecoration(labelText: "Kısa Açıklama")),
            const SizedBox(height: 10),
            TextField(controller: colorController, decoration: const InputDecoration(labelText: "Renk Hex (Örn: 0xFF4A90E2)")),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("İptal")),
          ElevatedButton(onPressed: () async {
            final data = {
              'baslik': titleController.text,
              'altBaslik': subtitleController.text,
              'renk': colorController.text,
              'ikon': 'psychology',
              if (docId == null) 'bolumler': [],
            };
            if (docId == null) await _firestore.collection('scenarios').add(data);
            else await _firestore.collection('scenarios').doc(docId).update(data);
            Navigator.pop(context);
          }, child: const Text("Kaydet")),
        ],
      ),
    );
  }

  void _deleteScenario(String docId) {
    showDialog(context: context, builder: (c) => AlertDialog(
      title: const Text("Senaryoyu Sil"),
      content: const Text("Bu senaryoyu silmek üzeresiniz. Bu işlem geri alınamaz!"),
      actions: [
        TextButton(onPressed: () => Navigator.pop(c), child: const Text("Vazgeç")),
        ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              await _firestore.collection('scenarios').doc(docId).delete();
              Navigator.pop(c);
            }, child: const Text("Sil")),
      ],
    ));
  }
}