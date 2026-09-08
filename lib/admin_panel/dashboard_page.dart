import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/report_service.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProHeader(),
            const SizedBox(height: 40),
            _buildStatsGrid(),
            const SizedBox(height: 40),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 3, child: _buildMetricsSection()),
                const SizedBox(width: 30),
                Expanded(flex: 2, child: _buildReportingCard(context)),
              ],
            ),
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
            Text("Sistem Operasyon Merkezi", style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
            SizedBox(height: 4),
            Text("Kahraman Dostum platformu genel performans ve içerik durumu.", style: TextStyle(color: Colors.blueGrey, fontSize: 14)),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(30), border: Border.all(color: Colors.green.withOpacity(0.2))),
          child: const Row(
            children: [
              CircleAvatar(radius: 4, backgroundColor: Colors.green),
              SizedBox(width: 8),
              Text("SİSTEM ÇEVRİMİÇİ", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 11)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatsGrid() {
    return Row(
      children: [
        _statBox("Toplam Kahraman", "users", Icons.people_outline_rounded, Colors.blue),
        const SizedBox(width: 20),
        _statBox("Yeni Olaylar", "reports", Icons.report_gmailerrorred_rounded, Colors.red),
        const SizedBox(width: 20),
        _statBox("Aktif Senaryolar", "scenarios", Icons.schema_outlined, Colors.indigo),
        const SizedBox(width: 20),
        _statBox("Kütüphane Öyküsü", "stories", Icons.menu_book_rounded, Colors.orange),
      ],
    );
  }

  Widget _statBox(String title, String col, IconData icon, Color color) {
    return Expanded(
      child: FutureBuilder<AggregateQuerySnapshot>(
        // Audit HIGH-01: Use count() instead of snapshots() to reduce Firestore read costs.
        future: FirebaseFirestore.instance.collection(col).count().get(),
        builder: (context, snapshot) {
          final count = snapshot.hasData ? snapshot.data!.count : 0;
          return Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFFE2E8F0))),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(height: 20),
                Text("$count", style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
                Text(title, style: TextStyle(color: Colors.blueGrey.shade400, fontWeight: FontWeight.bold, fontSize: 12)),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildMetricsSection() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), border: Border.all(color: const Color(0xFFE2E8F0))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.analytics_rounded, color: Colors.blueGrey),
              SizedBox(width: 12),
              Text("İçerik Derinliği", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
            ],
          ),
          const SizedBox(height: 30),
          _miniMetric("Platform üzerindeki toplam soru sayısı", "scenarios", "sorular"),
          const Divider(height: 40),
          _miniMetric("Toplam eğitim materyali hacmi", "videos", "sure"),
        ],
      ),
    );
  }

  Widget _miniMetric(String label, String col, String field) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection(col).snapshots(),
      builder: (context, snapshot) {
        int val = 0;
        if (snapshot.hasData) {
          for (var doc in snapshot.data!.docs) {
            if (col == "scenarios") {
              final bolumler = (doc.data() as Map)['bolumler'] ?? [];
              for (var b in bolumler) { val += (b['sorular'] as List?)?.length ?? 0; }
            } else { val++; }
          }
        }
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(color: Colors.blueGrey, fontWeight: FontWeight.w500)),
            Text("$val", style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
          ],
        );
      },
    );
  }

  Widget _buildReportingCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF1E293B), Color(0xFF334155)]),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.description_rounded, color: Colors.blueAccent, size: 40),
          const SizedBox(height: 20),
          const Text("Veri Raporlama", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          const Text("Tüm kullanıcı gelişimlerini ve içerik verilerini PDF olarak dışa aktarın.", style: TextStyle(color: Colors.white60, fontSize: 13, height: 1.5)),
          const SizedBox(height: 30),
          ElevatedButton(
            onPressed: () => ReportService().sistemRaporuOlustur(),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF0F172A),
              minimumSize: const Size(double.infinity, 55),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text("RAPOR HAZIRLA", style: TextStyle(fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );
  }
}
