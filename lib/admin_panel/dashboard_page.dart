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
        padding: const EdgeInsets.all(36),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProHeader(),
            const SizedBox(height: 32),
            _buildStatsGrid(),
            const SizedBox(height: 32),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 3, child: _buildMetricsSection()),
                const SizedBox(width: 24),
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
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Sistem Operasyon Merkezi",
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                color: Color(0xFF0F172A),
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              "Kahraman Dostum platformu genel performans, içerik hacmi ve sistem durumu.",
              style: TextStyle(color: Colors.blueGrey.shade600, fontSize: 14),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.green.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: Colors.green.withValues(alpha: 0.2)),
          ),
          child: const Row(
            children: [
              CircleAvatar(radius: 4, backgroundColor: Colors.green),
              SizedBox(width: 8),
              Text(
                "SİSTEM ÇEVRİMİÇİ",
                style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 11),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatsGrid() {
    return Row(
      children: [
        _statBox("Toplam Kahraman", "users", Icons.people_alt_rounded, Colors.blue),
        const SizedBox(width: 16),
        _statBox("Aktif Senaryolar", "scenarios", Icons.schema_rounded, Colors.indigo),
        const SizedBox(width: 16),
        _statBox("Kütüphane Öyküsü", "stories", Icons.menu_book_rounded, Colors.orange),
        const SizedBox(width: 16),
        _statBox("Eğitim Videoları", "videos", Icons.video_library_rounded, Colors.purple),
        const SizedBox(width: 16),
        _statBox("Rozet Çeşitliliği", "badges", Icons.emoji_events_rounded, Colors.amber.shade700),
      ],
    );
  }

  Widget _statBox(String title, String col, IconData icon, Color color) {
    return Expanded(
      child: FutureBuilder<AggregateQuerySnapshot>(
        future: FirebaseFirestore.instance.collection(col).count().get(),
        builder: (context, snapshot) {
          final count = snapshot.hasData ? snapshot.data!.count : 0;
          return Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 22),
                ),
                const SizedBox(height: 16),
                Text(
                  "$count",
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.blueGrey.shade600,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildMetricsSection() {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.analytics_rounded, color: Colors.blue, size: 20),
              ),
              const SizedBox(width: 12),
              const Text(
                "İçerik Derinliği & Eğitim Hacmi",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _miniMetric("Platform üzerindeki senaryo soru sayısı", "scenarios", "sorular", Icons.quiz_rounded),
          const Divider(height: 32),
          _miniMetric("Toplam yayınlanan eğitim videosu sayısı", "videos", "sure", Icons.smart_display_rounded),
          const Divider(height: 32),
          _miniMetric("Kazanılabilir rozet ve ödül sayısı", "badges", "rozet", Icons.workspace_premium_rounded),
          const Divider(height: 32),
          _miniMetric("Siber dedektif soru havuzu", "detective_questions", "soru", Icons.find_in_page_rounded),
        ],
      ),
    );
  }

  Widget _miniMetric(String label, String col, String field, IconData icon) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection(col).snapshots(),
      builder: (context, snapshot) {
        int val = 0;
        if (snapshot.hasData) {
          for (var doc in snapshot.data!.docs) {
            if (col == "scenarios") {
              final bolumler = (doc.data() as Map)['bolumler'] ?? [];
              for (var b in bolumler) {
                val += (b['sorular'] as List?)?.length ?? 0;
              }
            } else {
              val++;
            }
          }
        }
        return Row(
          children: [
            Icon(icon, size: 18, color: Colors.blueGrey.shade400),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: Colors.blueGrey.shade700,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                "$val",
                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Color(0xFF0F172A)),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildReportingCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.15),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.description_rounded, color: Colors.blueAccent, size: 32),
          ),
          const SizedBox(height: 20),
          const Text(
            "Veri Raporlama & PDF",
            style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          const Text(
            "Tüm kullanıcı gelişimlerini, aktif senaryoları ve içerik verilerini detaylı PDF raporu olarak dışa aktarın.",
            style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.5),
          ),
          const SizedBox(height: 28),
          ElevatedButton.icon(
            onPressed: () => ReportService().sistemRaporuOlustur(),
            icon: const Icon(Icons.picture_as_pdf_rounded, size: 18),
            label: const Text("RAPOR HAZIRLA (PDF)", style: TextStyle(fontWeight: FontWeight.w900)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF0F172A),
              minimumSize: const Size(double.infinity, 52),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }
}
