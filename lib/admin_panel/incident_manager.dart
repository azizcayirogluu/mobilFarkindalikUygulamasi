import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class IncidentManager extends StatefulWidget {
  const IncidentManager({super.key});

  @override
  State<IncidentManager> createState() => _IncidentManagerState();
}

class _IncidentManagerState extends State<IncidentManager> {
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
            _buildHeader(),
            const SizedBox(height: 30),
            Expanded(child: _buildIncidentList()),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Olay Bildirim Merkezi", style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
        Text("Çocuklardan gelen yardım taleplerini ve bildirimleri buradan yönetin.", style: TextStyle(color: Colors.blueGrey.shade400, fontSize: 14)),
      ],
    );
  }

  Widget _buildIncidentList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore.collection('reports').orderBy('tarih', descending: true).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final docs = snapshot.data!.docs;

        if (docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.assignment_turned_in_rounded, size: 80, color: Colors.grey.shade300),
                const SizedBox(height: 15),
                const Text("Henüz bir olay bildirimi yok.", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
              ],
            ),
          );
        }

        return ListView.builder(
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            final String docId = docs[index].id;
            return _buildIncidentCard(docId, data);
          },
        );
      },
    );
  }

  Widget _buildIncidentCard(String id, Map<String, dynamic> data) {
    final bool isNew = data['durum'] == 'YENİ';
    final DateTime? tarih = (data['tarih'] as Timestamp?)?.toDate();
    final String formatliTarih = tarih != null ? DateFormat('dd.MM.yyyy HH:mm').format(tarih) : "-";

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isNew ? Colors.blue.withOpacity(0.3) : const Color(0xFFE2E8F0), width: isNew ? 2 : 1),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: isNew ? Colors.blue : Colors.grey.shade200,
          child: Icon(isNew ? Icons.notification_important_rounded : Icons.mark_email_read_rounded, color: isNew ? Colors.white : Colors.grey, size: 20),
        ),
        title: Text(data['baslik'] ?? "Başlıksız Olay", style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
        subtitle: Text("${data['kullaniciAdi']} • $formatliTarih", style: TextStyle(fontSize: 12, color: Colors.blueGrey.shade400)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isNew) Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
              child: const Text("YENİ", style: TextStyle(color: Colors.blue, fontWeight: FontWeight.w900, fontSize: 10)),
            ),
            const SizedBox(width: 10),
            IconButton(icon: const Icon(Icons.delete_sweep_rounded, color: Colors.redAccent), onPressed: () => _deleteReport(id)),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Divider(),
                const SizedBox(height: 10),
                const Text("OLAY DETAYLARI", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11, color: Colors.blueGrey, letterSpacing: 1)),
                const SizedBox(height: 8),
                Text(data['detay'] ?? "Detay belirtilmemiş.", style: const TextStyle(fontSize: 14, height: 1.5, color: Colors.black87)),
                const SizedBox(height: 20),
                Row(
                  children: [
                    const Icon(Icons.location_on_rounded, size: 16, color: Colors.grey),
                    const SizedBox(width: 6),
                    Text("Konum: ${data['konum'] ?? 'Belirtilmedi'}", style: const TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 20),
                if (isNew) ElevatedButton.icon(
                  onPressed: () => _markAsRead(id),
                  icon: const Icon(Icons.check_circle_outline_rounded, size: 18),
                  label: const Text("OKUNDU OLARAK İŞARETLE"),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white, minimumSize: const Size(double.infinity, 45)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _markAsRead(String id) {
    _firestore.collection('reports').doc(id).update({'durum': 'OKUNDU'});
  }

  void _deleteReport(String id) {
    showDialog(context: context, builder: (c) => AlertDialog(
      title: const Text("Raporu Sil"),
      content: const Text("Bu raporu kalıcı olarak silmek istediğinize emin misiniz?"),
      actions: [
        TextButton(onPressed: () => Navigator.pop(c), child: const Text("VAZGEÇ")),
        ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.red), 
            onPressed: () { _firestore.collection('reports').doc(id).delete(); Navigator.pop(c); }, 
            child: const Text("SİL")),
      ],
    ));
  }
}
