import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DetectiveManager extends StatefulWidget {
  const DetectiveManager({super.key});

  @override
  State<DetectiveManager> createState() => _DetectiveManagerState();
}

class _DetectiveManagerState extends State<DetectiveManager> {
  final _formKey = GlobalKey<FormState>();
  final _metinController = TextEditingController();
  final _aciklamaController = TextEditingController();

  String _secilenDurum = "TEHLİKELİ";
  String _secilenIkon = "warning";
  String _secilenRenk = "#F44336";
  String? _editingDocId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Row(
        children: [
          // SOL PANEL: FORM
          Expanded(
            flex: 4,
            child: Container(
              padding: const EdgeInsets.all(40),
              decoration: const BoxDecoration(border: Border(right: BorderSide(color: Color(0xFFE2E8F0)))),
              child: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _headerSection(),
                      const SizedBox(height: 40),
                      _proTextField("Soru Senaryosu", _metinController, "Çocukların karşılaşabileceği bir durumu yazın...", maxLines: 4),
                      const SizedBox(height: 25),
                      _proTextField("Eğitici Geri Bildirim", _aciklamaController, "Doğru karar verildiğinde/yanlış yapıldığında gösterilecek açıklama...", maxLines: 3),
                      const SizedBox(height: 25),
                      _buildOptionsRow(),
                      const SizedBox(height: 40),
                      _buildFormActions(),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // SAĞ PANEL: LİSTE
          Expanded(
            flex: 6,
            child: _buildQuestionsList(),
          ),
        ],
      ),
    );
  }

  Widget _headerSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(_editingDocId != null ? "Soru Düzenleniyor" : "Yeni İçerik Oluştur", style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
        const Text("Siber Dedektif oyunu için interaktif sorular ekleyin.", style: TextStyle(color: Colors.blueGrey, fontSize: 13)),
      ],
    );
  }

  Widget _proTextField(String label, TextEditingController ctrl, String hint, {int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.blueGrey, letterSpacing: 1)),
        const SizedBox(height: 8),
        TextFormField(
          controller: ctrl,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
          ),
          validator: (v) => v!.isEmpty ? "Zorunlu alan" : null,
        ),
      ],
    );
  }

  Widget _buildOptionsRow() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("GÜVENLİK DURUMU", style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.blueGrey)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _secilenDurum,
                items: ["GÜVENLİ", "TEHLİKELİ"].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                onChanged: (v) => setState(() => _secilenDurum = v!),
                decoration: InputDecoration(filled: true, fillColor: const Color(0xFFF8FAFC), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
              ),
            ],
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("İKON TİPİ", style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.blueGrey)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _secilenIkon,
                items: ["warning", "security", "thumb_up", "vpn_key"].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                onChanged: (v) => setState(() => _secilenIkon = v!),
                decoration: InputDecoration(filled: true, fillColor: const Color(0xFFF8FAFC), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFormActions() {
    return Row(
      children: [
        if (_editingDocId != null)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(right: 12),
              child: OutlinedButton(onPressed: _formuSifirla, style: OutlinedButton.styleFrom(minimumSize: const Size(0, 55)), child: const Text("İPTAL")),
            ),
          ),
        Expanded(
          flex: 2,
          child: ElevatedButton(
            onPressed: _kaydet,
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F172A), minimumSize: const Size(0, 55), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            child: Text(_editingDocId != null ? "DEĞİŞİKLİKLERİ KAYDET" : "SİSTEME EKLE", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }

  Widget _buildQuestionsList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('detective_questions').orderBy('eklenmeTarihi', descending: true).snapshots(),
      builder: (context, snap) {
        if (!snap.hasData) return const Center(child: CircularProgressIndicator());
        final docs = snap.data!.docs;
        return ListView.builder(
          padding: const EdgeInsets.all(40),
          itemCount: docs.length,
          itemBuilder: (context, i) {
            final data = docs[i].data() as Map<String, dynamic>;
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE2E8F0))),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                leading: CircleAvatar(
                  backgroundColor: data['durum'] == "GÜVENLİ" ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                  child: Icon(data['durum'] == "GÜVENLİ" ? Icons.check_circle_outline : Icons.error_outline, color: data['durum'] == "GÜVENLİ" ? Colors.green : Colors.red),
                ),
                title: Text(data['metin'], maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(data['durum'], style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: data['durum'] == "GÜVENLİ" ? Colors.green : Colors.red)),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(icon: const Icon(Icons.edit_note_rounded, color: Colors.blue), onPressed: () => _duzenle(docs[i])),
                    IconButton(icon: const Icon(Icons.delete_sweep_rounded, color: Colors.redAccent), onPressed: () => docs[i].reference.delete()),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _formuSifirla() {
    setState(() {
      _metinController.clear(); _aciklamaController.clear();
      _secilenDurum = "TEHLİKELİ"; _editingDocId = null;
    });
  }

  void _duzenle(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    setState(() {
      _editingDocId = doc.id;
      _metinController.text = data['metin'] ?? "";
      _aciklamaController.text = data['aciklama'] ?? "";
      _secilenDurum = data['durum'] ?? "TEHLİKELİ";
    });
  }

  Future<void> _kaydet() async {
    if (_formKey.currentState!.validate()) {
      final data = {
        "metin": _metinController.text, "durum": _secilenDurum, "aciklama": _aciklamaController.text,
        "ikon": _secilenIkon, "renk": _secilenRenk, "sonGuncelleme": FieldValue.serverTimestamp(),
      };
      if (_editingDocId != null) await FirebaseFirestore.instance.collection('detective_questions').doc(_editingDocId).update(data);
      else { data["eklenmeTarihi"] = FieldValue.serverTimestamp(); await FirebaseFirestore.instance.collection('detective_questions').add(data); }
      _formuSifirla();
    }
  }
}
