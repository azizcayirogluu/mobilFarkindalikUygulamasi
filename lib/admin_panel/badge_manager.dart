import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class BadgeManager extends StatefulWidget {
  const BadgeManager({super.key});

  @override
  State<BadgeManager> createState() => _BadgeManagerState();
}

class _BadgeManagerState extends State<BadgeManager> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProHeader(),
            const SizedBox(height: 32),
            Expanded(child: _buildBadgeGrid()),
          ],
        ),
      ),
    );
  }

  Widget _buildProHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Rozet & Başarı Sistemi", style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Color(0xFF1E293B))),
              SizedBox(height: 4),
              Text("Kullanıcıların kazanabileceği ödülleri buradan yönetebilirsiniz.", style: TextStyle(color: Color(0xFF64748B), fontSize: 14)),
            ],
          ),
          ElevatedButton.icon(
            onPressed: () => _showBadgeEditor(),
            icon: const Icon(Icons.add_task_rounded),
            label: const Text("YENİ ROZET EKLE"),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6366F1),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadgeGrid() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore.collection('badges').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return Center(child: Text("Hata: ${snapshot.error}"));
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        
        final docs = snapshot.data!.docs;
        if (docs.isEmpty) return const Center(child: Text("Henüz rozet eklenmemiş."));

        return LayoutBuilder(
          builder: (context, constraints) {
            int crossAxisCount = constraints.maxWidth > 1400 ? 5 : constraints.maxWidth > 1000 ? 4 : constraints.maxWidth > 600 ? 2 : 1;
            return GridView.builder(
              physics: const BouncingScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount, 
                crossAxisSpacing: 20, 
                mainAxisSpacing: 20, 
                childAspectRatio: 0.9,
              ),
              itemCount: docs.length,
              itemBuilder: (context, index) {
                final data = docs[index].data() as Map<String, dynamic>;
                return _buildBadgeCard(docs[index].id, data);
              },
            );
          },
        );
      },
    );
  }

  Widget _buildBadgeCard(String id, Map<String, dynamic> data) {
    final Color badgeColor = _parseColor(data['renk']);
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.white, 
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: badgeColor.withOpacity(0.15), width: 1.5),
        boxShadow: [BoxShadow(color: badgeColor.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 6))],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: badgeColor.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(_getIconData(data['ikon']), color: badgeColor, size: 40),
          ),
          const SizedBox(height: 16),
          Text(data['ad'] ?? "İsimsiz", style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 17, color: Color(0xFF1E293B))),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(color: badgeColor.withOpacity(0.08), borderRadius: BorderRadius.circular(20)),
            child: Text(
              data['kriter_tipi'] == 'puan' ? "${data['hedef_deger']} Puan" : "${data['hedef_deger']} Senaryo",
              style: TextStyle(color: badgeColor, fontSize: 12, fontWeight: FontWeight.w800),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _actionBtn(Icons.edit_rounded, const Color(0xFF3B82F6), () => _showBadgeEditor(docId: id, existingData: data)),
              const SizedBox(width: 12),
              _actionBtn(Icons.delete_outline_rounded, const Color(0xFFEF4444), () => _deleteBadge(id)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _actionBtn(IconData i, Color c, VoidCallback o) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: o,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            border: Border.all(color: c.withOpacity(0.2)),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(i, color: c, size: 20),
        ),
      ),
    );
  }

  void _showBadgeEditor({String? docId, Map<String, dynamic>? existingData}) {
    final nameC = TextEditingController(text: existingData?['ad']);
    final valueC = TextEditingController(text: existingData?['hedef_deger']?.toString());
    String currentIcon = existingData?['ikon'] ?? 'star';
    String currentColor = existingData?['renk'] ?? '#6366F1';
    String currentType = existingData?['kriter_tipi'] ?? 'puan';

    final colors = ['#6366F1', '#EC4899', '#10B981', '#F59E0B', '#EF4444', '#8B5CF6', '#06B6D4', '#3B82F6'];
    final icons = ['star', 'shield', 'bolt', 'favorite', 'psychology', 'rocket', 'emoji_events', 'visibility', 'security'];

    showDialog(
      context: context,
      builder: (c) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Text(docId == null ? "Yeni Rozet Oluştur" : "Rozeti Düzenle", style: const TextStyle(fontWeight: FontWeight.w900)),
          content: SizedBox(
            width: 480,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: nameC, 
                    decoration: InputDecoration(labelText: "Rozet Adı", border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: currentType,
                    decoration: InputDecoration(labelText: "Kriter Tipi", border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                    items: const [
                      DropdownMenuItem(value: 'puan', child: Text("Toplam Puan")),
                      DropdownMenuItem(value: 'senaryo_sayisi', child: Text("Senaryo Tamamlama")),
                    ],
                    onChanged: (v) => setDialogState(() => currentType = v!),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: valueC, 
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(labelText: "Hedef Değer", hintText: "Örn: 500", border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                  ),
                  const SizedBox(height: 24),
                  const Text("İkon", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8, runSpacing: 8,
                    children: icons.map((icon) {
                      bool isSel = currentIcon == icon;
                      return InkWell(
                        onTap: () => setDialogState(() => currentIcon = icon),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: isSel ? _parseColor(currentColor).withOpacity(0.1) : Colors.transparent,
                            border: Border.all(color: isSel ? _parseColor(currentColor) : Colors.grey.shade300, width: 2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(_getIconData(icon), color: isSel ? _parseColor(currentColor) : Colors.grey, size: 24),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                  const Text("Renk", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 12,
                    children: colors.map((hex) {
                      bool isSel = currentColor == hex;
                      return InkWell(
                        onTap: () => setDialogState(() => currentColor = hex),
                        child: Container(
                          width: 36, height: 36,
                          decoration: BoxDecoration(
                            color: _parseColor(hex),
                            shape: BoxShape.circle,
                            border: isSel ? Border.all(color: Colors.white, width: 3) : null,
                            boxShadow: isSel ? [BoxShadow(color: Colors.black26, blurRadius: 4)] : null,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(c), child: const Text("Vazgeç", style: TextStyle(color: Colors.grey))),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: _parseColor(currentColor), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              onPressed: () async {
                if (nameC.text.isEmpty) return;
                final data = {
                  'ad': nameC.text,
                  'ikon': currentIcon,
                  'renk': currentColor,
                  'kriter_tipi': currentType,
                  'hedef_deger': int.tryParse(valueC.text) ?? 0,
                  'updated_at': FieldValue.serverTimestamp(),
                };
                if (docId == null) {
                  await _firestore.collection('badges').add(data);
                } else {
                  await _firestore.collection('badges').doc(docId).update(data);
                }
                Navigator.pop(c);
              },
              child: const Text("KAYDET"),
            ),
          ],
        ),
      ),
    );
  }

  void _deleteBadge(String id) {
    showDialog(context: context, builder: (c) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text("Silmek istediğine emin misin?"),
      content: const Text("Bu rozet kalıcı olarak silinecektir."),
      actions: [
        TextButton(onPressed: () => Navigator.pop(c), child: const Text("İptal")),
        ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
            onPressed: () { _firestore.collection('badges').doc(id).delete(); Navigator.pop(c); }, 
            child: const Text("SİL")),
      ],
    ));
  }

  Color _parseColor(String? hexColor) {
    if (hexColor == null || hexColor.isEmpty) return const Color(0xFF6366F1);
    try {
      String cleanHex = hexColor.replaceAll('#', '').replaceAll('0x', '');
      if (cleanHex.length == 6) cleanHex = 'FF$cleanHex';
      return Color(int.parse('0x$cleanHex'));
    } catch (e) { return const Color(0xFF6366F1); }
  }

  IconData _getIconData(String name) {
    switch (name) {
      case 'star': return Icons.star_rounded;
      case 'shield': return Icons.shield_rounded;
      case 'bolt': return Icons.bolt_rounded;
      case 'favorite': return Icons.favorite_rounded;
      case 'psychology': return Icons.psychology_rounded;
      case 'rocket': return Icons.rocket_launch_rounded;
      case 'emoji_events': return Icons.emoji_events_rounded;
      case 'visibility': return Icons.visibility_rounded;
      case 'security': return Icons.security_rounded;
      default: return Icons.stars_rounded;
    }
  }
}
