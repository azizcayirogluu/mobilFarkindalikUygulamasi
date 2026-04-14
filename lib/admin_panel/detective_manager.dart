import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:zorbalik_uygulamasi/app_theme.dart';

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

  final List<Map<String, dynamic>> _ikonlar = [
    {"name": "vpn_key", "icon": Icons.vpn_key_rounded},
    {"name": "thumb_up", "icon": Icons.thumb_up_rounded},
    {"name": "location_off", "icon": Icons.location_off_rounded},
    {"name": "group_remove", "icon": Icons.group_remove_rounded},
    {"name": "school", "icon": Icons.school_rounded},
    {"name": "security", "icon": Icons.security_rounded},
    {"name": "warning", "icon": Icons.warning_amber_rounded},
    {"name" : "error", "icon": Icons.error_outline_rounded},
  ];

  final List<Map<String, String>> _renkler = [
    {"name": "Kırmızı", "hex": "#F44336"},
    {"name": "Yeşil", "hex": "#4CAF50"},
    {"name": "Mavi", "hex": "#2196F3"},
    {"name": "Turuncu", "hex": "#FF9800"},
    {"name": "Mor", "hex": "#9C27B0"},
    {"name": "Gri", "hex": "#607D8B"},
  ];

  void _formuSifirla() {
    setState(() {
      _metinController.clear();
      _aciklamaController.clear();
      _secilenDurum = "TEHLİKELİ";
      _secilenIkon = "warning";
      _secilenRenk = "#F44336";
      _editingDocId = null;
    });
  }

  void _duzenle(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    setState(() {
      _editingDocId = doc.id;
      _metinController.text = data['metin'] ?? "";
      _aciklamaController.text = data['aciklama'] ?? "";
      _secilenDurum = data['durum'] ?? "TEHLİKELİ";
      _secilenIkon = data['ikon'] ?? "warning";
      _secilenRenk = data['renk'] ?? "#F44336";
    });
  }

  Future<void> _kaydet() async {
    if (_formKey.currentState!.validate()) {
      final data = {
        "metin": _metinController.text,
        "durum": _secilenDurum,
        "aciklama": _aciklamaController.text,
        "ikon": _secilenIkon,
        "renk": _secilenRenk,
        "sonGuncelleme": FieldValue.serverTimestamp(),
      };

      try {
        if (_editingDocId != null) {
          await FirebaseFirestore.instance.collection('detective_questions').doc(_editingDocId).update(data);
        } else {
          data["eklenmeTarihi"] = FieldValue.serverTimestamp();
          await FirebaseFirestore.instance.collection('detective_questions').add(data);
        }
        
        _formuSifirla();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(_editingDocId != null ? "Soru güncellendi!" : "Soru eklendi!"), backgroundColor: Colors.green),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Hata: $e"), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Siber Dedektif Soru Yönetimi", style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Row(
        children: [
          Expanded(
            flex: 2,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionTitle(_editingDocId != null ? "Soruyu Düzenle" : "Yeni Soru Ekle"),
                    const SizedBox(height: 20),
                    _buildTextField("Soru Metni", _metinController, "Örn: Biri şifreni istedi...", maxLines: 3),
                    const SizedBox(height: 16),
                    _buildTextField("Eğitici Açıklama", _aciklamaController, "Örn: Şifreni kimseyle paylaşmamalısın!", maxLines: 2),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(child: _buildDropdown("Durum", _secilenDurum, ["GÜVENLİ", "TEHLİKELİ"], (v) => setState(() => _secilenDurum = v!))),
                        const SizedBox(width: 16),
                        Expanded(child: _buildIkonSecici()),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildRenkSecici(),
                    const SizedBox(height: 30),
                    Row(
                      children: [
                        if (_editingDocId != null) 
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: OutlinedButton(
                                onPressed: _formuSifirla,
                                style: OutlinedButton.styleFrom(minimumSize: const Size(0, 55)),
                                child: const Text("İPTAL"),
                              ),
                            ),
                          ),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.anaMavi,
                              minimumSize: const Size(0, 55),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: _kaydet,
                            child: Text(_editingDocId != null ? "GÜNCELLE" : "VERİTABANINA EKLE", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          const VerticalDivider(width: 1),
          Expanded(
            flex: 3,
            child: _buildQuestionsList(),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF1E293B)));
  }

  Widget _buildTextField(String label, TextEditingController controller, String hint, {int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: Colors.grey[50],
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[200]!)),
          ),
          validator: (v) => v!.isEmpty ? "Boş bırakılamaz" : null,
        ),
      ],
    );
  }

  Widget _buildDropdown(String label, String value, List<String> items, Function(String?) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey)),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: value,
          items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
          onChanged: onChanged,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.grey[50],
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ],
    );
  }

  Widget _buildIkonSecici() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("İkon Seç", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey)),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _secilenIkon,
          items: _ikonlar.map((e) => DropdownMenuItem(
            value: e['name'] as String,
            child: Row(children: [Icon(e['icon'] as IconData, size: 20), const SizedBox(width: 10), Text(e['name'] as String)]),
          )).toList(),
          onChanged: (v) => setState(() => _secilenIkon = v!),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.grey[50],
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ],
    );
  }

  Widget _buildRenkSecici() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Renk Seç", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey)),
        const SizedBox(height: 10),
        SizedBox(
          height: 50,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _renkler.length,
            itemBuilder: (context, i) {
              bool isSelected = _secilenRenk == _renkler[i]["hex"];
              return GestureDetector(
                onTap: () => setState(() => _secilenRenk = _renkler[i]["hex"]!),
                child: Container(
                  margin: const EdgeInsets.only(right: 12),
                  width: 45,
                  decoration: BoxDecoration(
                    color: Color(int.parse("0xFF${_renkler[i]["hex"]!.replaceAll("#", "")}")),
                    shape: BoxShape.circle,
                    border: Border.all(color: isSelected ? Colors.black : Colors.transparent, width: 3),
                  ),
                  child: isSelected ? const Icon(Icons.check, color: Colors.white) : null,
                ),
              );
            },
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
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: _sectionTitle("Mevcut Sorular (${docs.length})"),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                itemCount: docs.length,
                itemBuilder: (context, i) {
                  final data = docs[i].data() as Map<String, dynamic>;
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: data['durum'] == "GÜVENLİ" ? Colors.green[50] : Colors.red[50],
                        child: Icon(
                          data['durum'] == "GÜVENLİ" ? Icons.check : Icons.close,
                          color: data['durum'] == "GÜVENLİ" ? Colors.green : Colors.red,
                        ),
                      ),
                      title: Text(data['metin'], maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(data['aciklama'], maxLines: 1, overflow: TextOverflow.ellipsis),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(icon: const Icon(Icons.edit_outlined, color: Colors.blue), onPressed: () => _duzenle(docs[i])),
                          IconButton(icon: const Icon(Icons.delete_outline, color: Colors.redAccent), onPressed: () => docs[i].reference.delete()),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}
