import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:intl/intl.dart';

class UserManager extends StatelessWidget {
  const UserManager({super.key});

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
            const SizedBox(height: 30),
            Expanded(child: _buildUserList()),
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
            Text("Kahraman Veri Merkezi", style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
            Text("Tüm kullanıcıların ilerleme süreçlerini ve güvenlik analizlerini yönetin.", style: TextStyle(color: Colors.blueGrey, fontSize: 14)),
          ],
        ),
        _buildSummaryBadge(),
      ],
    );
  }

  Widget _buildSummaryBadge() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('users').snapshots(),
      builder: (context, s) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), border: Border.all(color: const Color(0xFFE2E8F0))),
        child: Text("${s.hasData ? s.data!.docs.length : 0} Kayıtlı Kullanıcı", style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.blue, fontSize: 13)),
      ),
    );
  }

  Widget _buildUserList() {
    return StreamBuilder<QuerySnapshot>(
      // Audit HIGH-02: Limit query and reduce N+1 stream listeners.
      stream: FirebaseFirestore.instance.collection('users')
          .orderBy('kayitTarihi', descending: true)
          .limit(50)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final users = snapshot.data!.docs;
        
        return ListView.builder(
          itemCount: users.length,
          itemBuilder: (context, index) {
            final userData = users[index].data() as Map<String, dynamic>;
            final String uid = users[index].id;
            
            return FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance.collection('usersProgress').doc(uid).get(),
              builder: (context, progSnap) {
                final progData = progSnap.data?.data() as Map<String, dynamic>? ?? {};
                return _buildUserCard(context, uid, userData, progData);
              },
            );
          },
        );
      },
    );
  }

  Widget _buildUserCard(BuildContext context, String uid, Map<String, dynamic> user, Map<String, dynamic> prog) {
    final String risk = prog['riskDurumu'] ?? "BELİRSİZ";
    final Color riskColor = risk == "TEHLİKELİ" ? Colors.red : (risk == "RİSKLİ" ? Colors.orange : Colors.green);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 25, vertical: 12),
        leading: CircleAvatar(
          radius: 25,
          backgroundColor: riskColor.withOpacity(0.1),
          child: Text(user['kullaniciAdi']?[0].toUpperCase() ?? "K", style: TextStyle(color: riskColor, fontWeight: FontWeight.bold, fontSize: 18)),
        ),
        title: Row(
          children: [
            Text(user['kullaniciAdi'] ?? "İsimsiz", style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
            const SizedBox(width: 10),
            _badge(user['yasGrubu'] ?? "-", Colors.blueGrey),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: Row(
            children: [
              _infoItem(Icons.stars_rounded, "${prog['toplam_puan'] ?? 0} TP", Colors.amber),
              const SizedBox(width: 15),
              _infoItem(Icons.emoji_events_rounded, "${(prog['rozetler'] as List? ?? []).length} Rozet", Colors.purple),
              const SizedBox(width: 15),
              _infoItem(Icons.security_rounded, risk, riskColor),
            ],
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _actionBtn(Icons.troubleshoot_rounded, Colors.indigo, () => _showUserDetails(context, uid, user, prog)),
            const SizedBox(width: 8),
            _actionBtn(Icons.delete_sweep_rounded, Colors.redAccent, () => _deleteUser(context, uid, user['kullaniciAdi'])),
          ],
        ),
      ),
    );
  }

  Widget _infoItem(IconData i, String t, Color c) {
    return Row(
      children: [
        Icon(i, size: 14, color: c),
        const SizedBox(width: 4),
        Text(t, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.blueGrey.shade600)),
      ],
    );
  }

  Widget _badge(String t, Color c) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(color: c.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
      child: Text(t, style: TextStyle(color: c, fontSize: 10, fontWeight: FontWeight.w900)),
    );
  }

  Widget _actionBtn(IconData i, Color c, VoidCallback o) {
    return Container(
      decoration: BoxDecoration(color: c.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
      child: IconButton(onPressed: o, icon: Icon(i, color: c, size: 20), splashRadius: 24),
    );
  }

  void _showUserDetails(BuildContext context, String uid, Map<String, dynamic> user, Map<String, dynamic> prog) {
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        title: Row(
          children: [
            const Icon(Icons.person_search_rounded, color: Colors.blue),
            const SizedBox(width: 12),
            Text("${user['kullaniciAdi']} - Detaylı Analiz", style: const TextStyle(fontWeight: FontWeight.w900)),
          ],
        ),
        content: SizedBox(
          width: 500,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _detailRow("Kayıt Tarihi", _formatDate(user['kayitTarihi'])),
              _detailRow("Son Görülme", _formatDate(user['sonGorulme'])),
              const Divider(height: 30),
              const Text("GÜVENLİK ANALİZİ", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12, color: Colors.blueGrey)),
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.grey.shade200)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Risk Durumu: ${prog['riskDurumu'] ?? 'ANALİZ EDİLMEDİ'}", style: TextStyle(fontWeight: FontWeight.bold, color: _getRiskColor(prog['riskDurumu']))),
                    const SizedBox(height: 5),
                    Text(prog['riskNedeni'] ?? "Henüz bir risk tespiti yapılmadı.", style: const TextStyle(fontSize: 13, color: Colors.black87)),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              const Text("SON HATALAR & EĞİTİM İHTİYAÇLARI", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12, color: Colors.blueGrey)),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                children: (prog['son_hatalar'] as List? ?? []).map((e) => _badge(e.toString(), Colors.redAccent)).toList(),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c), child: const Text("Kapat")),
        ],
      ),
    );
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return "Bilinmiyor";
    DateTime date = (timestamp as Timestamp).toDate();
    return DateFormat('dd.MM.yyyy HH:mm').format(date);
  }

  Color _getRiskColor(String? r) {
    if (r == "TEHLİKELİ") return Colors.red;
    if (r == "RİSKLİ") return Colors.orange;
    return Colors.green;
  }

  void _deleteUser(BuildContext context, String uid, String? name) {
    showDialog(context: context, builder: (c) => AlertDialog(
      title: const Text("Kullanıcıyı Sil"),
      content: Text("$name kullanıcısını ve tüm verilerini sistemden silmek istediğinize emin misiniz?"),
      actions: [
        TextButton(onPressed: () => Navigator.pop(c), child: const Text("İptal")),
        ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              final deleteFn = FirebaseFunctions.instanceFor(region: 'europe-west1').httpsCallable('deleteUser');
              await deleteFn.call({'uid': uid});
              Navigator.pop(c);
            }, child: const Text("SİL")),
      ],
    ));
  }

  Widget _detailRow(String l, String v) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(l, style: const TextStyle(color: Colors.blueGrey, fontWeight: FontWeight.w500)),
          Text(v, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
