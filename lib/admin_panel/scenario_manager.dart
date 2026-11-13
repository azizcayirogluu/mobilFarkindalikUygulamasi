import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:zorbalik_uygulamasi/app_theme.dart';
import 'package:zorbalik_uygulamasi/services/scenario_export_service.dart';

class ScenarioManager extends StatefulWidget {
  const ScenarioManager({super.key});

  @override
  State<ScenarioManager> createState() => _ScenarioManagerState();
}

class _ScenarioManagerState extends State<ScenarioManager> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isExporting = false;

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
                      final String scenarioYasGrubu = data['yasGrubu'] ?? "6-12";

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
                            subtitle: _buildScenarioSubtitle(bolumler.length, data['altBaslik'], scenarioYasGrubu),
                            trailing: _buildMainActions(docId, data),
                            children: [
                              _buildChapterContainer(docId, bolumler, scenarioYasGrubu),
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

  Future<void> _exportScenariosToJson() async {
    if (_isExporting) return;
    setState(() => _isExporting = true);

    try {
      final exportService = ScenarioExportService();
      final result = await exportService.exportScenariosToJson();

      if (!mounted) return;

      if (result.success) {
        showDialog(
          context: context,
          builder: (dialogCtx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            title: const Row(
              children: [
                Icon(Icons.check_circle_rounded, color: Colors.green, size: 28),
                SizedBox(width: 10),
                Text("Dışa Aktarma Başarılı!", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("${result.totalScenarios} senaryo başarıyla JSON formatında dışa aktarıldı."),
                const SizedBox(height: 12),
                Text("Dosya Adı: ${result.fileName}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.blueGrey)),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogCtx),
                child: const Text("Tamam", style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.errorMessage ?? "Dışa aktarma başarısız."),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Hata oluştu: $e"),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Senaryo Yönetim Ekranı",
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: AppColors.yaziRengi)),
            const Text("Eğitici içerikleri ve interaktif soruları buradan yönetin.",
                style: TextStyle(color: Colors.blueGrey)),
          ],
        ),
        Row(
          children: [
            ElevatedButton.icon(
              onPressed: _isExporting ? null : _exportScenariosToJson,
              icon: _isExporting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(color: Colors.indigo, strokeWidth: 2),
                    )
                  : const Icon(Icons.download_rounded),
              label: Text(_isExporting ? "Dışa Aktarılıyor..." : "JSON OLARAK DIŞA AKTAR 📥"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.indigo,
                side: const BorderSide(color: Colors.indigo, width: 1.5),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 2,
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton.icon(
              onPressed: () => _showScenarioDialog(),
              icon: const Icon(Icons.add_to_photos_rounded),
              label: const Text("YENİ SENARYO OLUŞTUR"),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.anaMavi,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 22),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 8,
                shadowColor: AppColors.anaMavi.withValues(alpha: 0.4),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildScenarioSubtitle(int chapterCount, String? subtitle, String yasGrubu) {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Row(
        children: [
          _badge("$chapterCount Bölüm", AppColors.anaMavi),
          const SizedBox(width: 8),
          _badge(yasGrubu == "6-12" ? "Çocuk" : "Genç", Colors.orange),
          const SizedBox(width: 10),
          Expanded(child: Text(subtitle ?? '', maxLines: 1, overflow: TextOverflow.ellipsis,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13))),
        ],
      ),
    );
  }

  Widget _buildChapterContainer(String docId, List bolumler, String scenarioYasGrubu) {
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
            return _buildChapterItem(docId, bIndex, bolumler, scenarioYasGrubu);
          }),
          const SizedBox(height: 15),
          _addNewChapterBtn(docId, bolumler),
        ],
      ),
    );
  }

  Widget _buildChapterItem(String docId, int bIndex, List currentBolumler, String scenarioYasGrubu) {
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
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("${(currentBolumler[bIndex]['sorular'] as List? ?? []).length} Soru Yayında"),
            if (currentBolumler[bIndex]['bolumAmaci'] != null)
              Text("Amacı: ${currentBolumler[bIndex]['bolumAmaci']}",
                  maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: Colors.blueGrey)),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _miniActionBtn(Icons.edit_note_rounded, Colors.blue, () => _showChapterEditor(docId, bIndex, currentBolumler, scenarioYasGrubu)),
            const SizedBox(width: 8),
            _miniActionBtn(Icons.delete_outline_rounded, Colors.redAccent, () => _deleteChapter(docId, bIndex, currentBolumler)),
          ],
        ),
      ),
    );
  }

  void _showChapterEditor(String docId, int bIndex, List currentBolumler, String scenarioYasGrubu) {
    Map<String, dynamic> chapter = Map<String, dynamic>.from(currentBolumler[bIndex]);
    List sorular = List.from(chapter['sorular'] ?? []);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => StatefulBuilder(
          builder: (dialogCtx, setDialogState) {
            return Dialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              child: Container(
                width: MediaQuery.of(dialogCtx).size.width * 0.85,
                height: MediaQuery.of(dialogCtx).size.height * 0.9,
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    _buildEditorHeader(chapter['bolumAdi']),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(child: _buildChapterTitleField(chapter, (v) => setDialogState(() => chapter['bolumAdi'] = v))),
                        const SizedBox(width: 15),
                        Expanded(child: _buildChapterAimField(chapter, (v) => setDialogState(() => chapter['bolumAmaci'] = v))),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Expanded(
                      child: ListView.builder(
                        physics: const BouncingScrollPhysics(),
                        itemCount: sorular.length,
                        itemBuilder: (c, sIndex) => _buildSoruCard(sIndex, sorular[sIndex], scenarioYasGrubu, () {
                          setDialogState(() => sorular.removeAt(sIndex));
                        }, setDialogState),
                      ),
                    ),
                    _buildEditorFooter(docId, chapter, sorular, currentBolumler, bIndex, scenarioYasGrubu, setDialogState, dialogCtx),
                  ],
                ),
              ),
            );
          }
      ),
    );
  }

  Widget _buildSoruCard(int index, Map soru, String scenarioYasGrubu, VoidCallback onDelete, StateSetter setDialogState) {
    List secenekler = List.from(soru['secenekler'] ?? []);
    if (scenarioYasGrubu == "13-18" && secenekler.length < 3) {
      secenekler.add({'metin': '3. Seçenek', 'dogru': false, 'feedback': 'Yeni bir bakış açısı...'});
      soru['secenekler'] = secenekler;
    } else if (scenarioYasGrubu == "6-12" && secenekler.length > 2) {
      secenekler = secenekler.sublist(0, 2);
      bool hasTrue = secenekler.any((o) => o['dogru'] == true);
      if (!hasTrue) secenekler[0]['dogru'] = true;
      soru['secenekler'] = secenekler;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 25),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: AppColors.anaMavi.withValues(alpha: 0.1), width: 2),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 15, offset: const Offset(0, 5))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.anaMavi.withValues(alpha: 0.05),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(23)),
            ),
            child: Row(
              children: [
                _badge("SORU ${index + 1}", AppColors.anaMavi),
                const SizedBox(width: 8),
                _badge(scenarioYasGrubu, Colors.grey),
                const Spacer(),
                IconButton(icon: const Icon(Icons.delete_sweep_rounded, color: Colors.redAccent), onPressed: onDelete),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: Column(
                    children: [
                      _buildImagePreviewInSoru(soru['imageUrl']),
                      const SizedBox(height: 12),
                      TextFormField(
                        initialValue: soru['imageUrl'],
                        decoration: _inputDecoration("Görsel URL", Icons.link_rounded),
                        style: const TextStyle(fontSize: 12),
                        onChanged: (v) => setDialogState(() => soru['imageUrl'] = v),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 25),
                Expanded(
                  flex: 7,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextFormField(
                        initialValue: soru['soru'],
                        maxLines: 3,
                        decoration: _inputDecoration("Soru Metni", Icons.help_outline_rounded),
                        onChanged: (v) => soru['soru'] = v,
                      ),
                      const SizedBox(height: 20),
                      Text("SEÇENEKLER VE DÖNÜTLER (${scenarioYasGrubu == '6-12' ? '2 Şık Zorunlu' : '3 Şık Zorunlu'})",
                          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12, color: Colors.blueGrey)),
                      const SizedBox(height: 15),
                      ...List.generate((soru['secenekler'] as List).length, (optIndex) {
                        var opt = soru['secenekler'][optIndex];
                        return _buildOptionRow(opt, soru, setDialogState, optIndex);
                      }),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImagePreviewInSoru(String? url) {
    return Container(
      height: 140,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: (url != null && url.isNotEmpty)
          ? ClipRRect(
          borderRadius: BorderRadius.circular(15),
          child: CachedNetworkImage(imageUrl: url, fit: BoxFit.cover, errorWidget: (c, url, e) => const Center(child: Icon(Icons.broken_image_rounded, size: 40, color: Colors.grey))))
          : const Center(child: Icon(Icons.image_search_rounded, size: 40, color: Colors.grey)),
    );
  }

  Widget _buildOptionRow(Map opt, Map soru, StateSetter setState, int index) {
    bool isTrue = opt['dogru'] == true;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isTrue ? Colors.green.withValues(alpha: 0.03) : Colors.red.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: isTrue ? Colors.green.withValues(alpha: 0.2) : Colors.red.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                icon: Icon(
                  isTrue ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                  color: isTrue ? Colors.green : Colors.grey,
                ),
                onPressed: () => setState(() {
                  for (var o in soru['secenekler']) {
                    o['dogru'] = false;
                  }
                  opt['dogru'] = true;
                }),
              ),
              Expanded(
                child: _smallField(opt, 'metin', "Seçenek metni...", isTrue ? Colors.green : Colors.red),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.only(left: 48),
            child: _smallField(opt, 'feedback', "Feedback: Bu şık seçilirse ne densin?", Colors.blueGrey),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) => InputDecoration(
    labelText: label,
    labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
    prefixIcon: Icon(icon, color: AppColors.anaMavi),
    filled: true,
    fillColor: Colors.grey.shade50,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide(color: Colors.grey.shade200)),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide(color: Colors.grey.shade200)),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: const BorderSide(color: AppColors.anaMavi, width: 2)),
  );

  Widget _smallField(Map opt, String key, String hint, Color color) {
    return TextFormField(
      initialValue: opt[key],
      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: color.withValues(alpha: 0.8)),
      decoration: InputDecoration(
        hintText: hint,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: color.withValues(alpha: 0.5))),
      ),
      onChanged: (v) => opt[key] = v,
    );
  }

  Widget _badge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
      child: Text(text, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 1)),
    );
  }

  BoxDecoration _cardDecoration() => BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(20),
    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 20, offset: const Offset(0, 10))],
    border: Border.all(color: Colors.white),
  );

  Widget _buildLeadingIcon(String? colorHex) {
    Color color = Color(int.parse(colorHex ?? "0xFF9575CD"));
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
      child: Icon(Icons.psychology_rounded, color: color, size: 28),
    );
  }

  Widget _miniActionBtn(IconData icon, Color color, VoidCallback onTap) {
    return IconButton(
      onPressed: onTap,
      icon: Icon(icon, color: color, size: 20),
      style: IconButton.styleFrom(backgroundColor: color.withValues(alpha: 0.1), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
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

  void _addNewChapter(String docId, List currentBolumler) async {
    currentBolumler.add({'bolumAdi': 'Yeni Bölüm', 'bolumAmaci': '', 'sorular': []});
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
              if (!c.mounted) return;
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

  Widget _buildChapterAimField(Map chapter, Function(String) onChanged) {
    return TextFormField(
      initialValue: chapter['bolumAmaci'],
      decoration: _inputDecoration("Bölümün Amacı / Misyonu", Icons.track_changes_rounded),
      onChanged: onChanged,
    );
  }

  Widget _buildEditorFooter(String docId, Map chapter, List sorular, List currentBolumler, int bIndex, String scenarioYasGrubu, StateSetter setDialogState, BuildContext dialogContext) {
    return Container(
      padding: const EdgeInsets.only(top: 24),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white, padding: const EdgeInsets.all(18)),
              onPressed: () {
                setDialogState(() => sorular.add({
                  'soru': 'Soru Metni?',
                  'imageUrl': '',
                  'yasGrubu': scenarioYasGrubu,
                  'secenekler': scenarioYasGrubu == "6-12" ? [
                    {'metin': 'Seçenek 1', 'dogru': true, 'feedback': 'Bravo!'},
                    {'metin': 'Seçenek 2', 'dogru': false, 'feedback': 'Tekrar dene.'},
                  ] : [
                    {'metin': 'Seçenek 1', 'dogru': true, 'feedback': 'Harika!'},
                    {'metin': 'Seçenek 2', 'dogru': false, 'feedback': 'Tekrar düşün.'},
                    {'metin': 'Seçenek 3', 'dogru': false, 'feedback': 'Geliştirilmeli.'},
                  ]
                }));
              },
              icon: const Icon(Icons.add_circle),
              label: const Text("YENİ SORU EKLE"),
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.anaMavi, foregroundColor: Colors.white, padding: const EdgeInsets.all(18)),
              onPressed: () async {
                for (var s in sorular) {
                  s['yasGrubu'] = scenarioYasGrubu;
                }
                chapter['sorular'] = sorular;
                currentBolumler[bIndex] = chapter;
                await _firestore.collection('scenarios').doc(docId).update({'bolumler': currentBolumler});
                if (!dialogContext.mounted) return;
                Navigator.pop(dialogContext);
              },
              icon: const Icon(Icons.save_rounded),
              label: const Text("TÜMÜNÜ KAYDET"),
            ),
          ),
        ],
      ),
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
    String selectedYasGrubu = existingData?['yasGrubu'] ?? "6-12";

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (dialogCtx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(docId == null ? "Yeni Senaryo Kartı" : "Senaryo Ayarları"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: titleController, decoration: const InputDecoration(labelText: "Senaryo Başlığı")),
              const SizedBox(height: 10),
              TextField(controller: subtitleController, decoration: const InputDecoration(labelText: "Kısa Açıklama")),
              const SizedBox(height: 10),
              TextField(controller: colorController, decoration: const InputDecoration(labelText: "Renk Hex (Örn: 0xFF4A90E2)")),
              const SizedBox(height: 20),
              const Align(alignment: Alignment.centerLeft, child: Text("Hedef Yaş Grubu (Tüm Soruları Etkiler)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.blueGrey))),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                initialValue: selectedYasGrubu,
                decoration: _inputDecoration("Yaş Grubu", Icons.child_care_rounded),
                items: ["6-12", "13-18"].map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value == "6-12" ? "6 - 12 Yaş (Çocuk)" : "13 - 18 Yaş (Genç)"),
                  );
                }).toList(),
                onChanged: (newValue) => setDialogState(() => selectedYasGrubu = newValue!),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogCtx), child: const Text("İptal")),
            ElevatedButton(onPressed: () async {
              final data = {
                'baslik': titleController.text,
                'altBaslik': subtitleController.text,
                'renk': colorController.text,
                'ikon': 'psychology',
                'yasGrubu': selectedYasGrubu,
                if (docId == null) 'bolumler': [],
              };
              if (docId == null) {
                await _firestore.collection('scenarios').add(data);
              } else {
                await _firestore.collection('scenarios').doc(docId).update(data);
              }
              if (!dialogCtx.mounted) return;
              Navigator.pop(dialogCtx);
            }, child: const Text("Kaydet")),
          ],
        ),
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
              if (!c.mounted) return;
              Navigator.pop(c);
            }, child: const Text("Sil")),
      ],
    ));
  }
}
