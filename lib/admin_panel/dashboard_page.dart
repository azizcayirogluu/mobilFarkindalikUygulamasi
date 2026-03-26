import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/report_service.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FB),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _header(),
            const SizedBox(height: 24),
            _summaryGrid(),
            const SizedBox(height: 24),

            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: Column(
                    children: [
                      _card(_systemAnalysis()),
                      const SizedBox(height: 20),
                      _card(_userMetrics()),
                    ],
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  flex: 2,
                  child: _actionCenter(context),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  // ---------------- HEADER ----------------
  Widget _header() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Dashboard",
                style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A))),
            SizedBox(height: 4),
            Text("Sistem genel durumu",
                style: TextStyle(color: Colors.grey)),
          ],
        ),
        _statusChip(),
      ],
    );
  }

  Widget _statusChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Row(
        children: [
          Icon(Icons.circle, size: 10, color: Colors.green),
          SizedBox(width: 6),
          Text("Aktif", style: TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  // ---------------- SUMMARY ----------------
  Widget _summaryGrid() {
    return Row(
      children: [
        _statCard("Kullanıcılar", "users", Icons.people, Colors.indigo),
        const SizedBox(width: 16),
        _statCard("Senaryolar", "scenarios", Icons.map, Colors.purple),
        const SizedBox(width: 16),
        _statCard("Hikayeler", "stories", Icons.menu_book, Colors.orange),
        const SizedBox(width: 16),
        _statCard("Videolar", "videos", Icons.play_circle, Colors.red),
      ],
    );
  }

  Widget _statCard(String title, String col, IconData icon, Color color) {
    return Expanded(
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection(col).snapshots(),
        builder: (context, snapshot) {
          final count =
          snapshot.hasData ? snapshot.data!.docs.length : 0;

          return Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  color.withOpacity(0.15),
                  color.withOpacity(0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: color.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: Colors.white),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("$count",
                        style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: color)),
                    Text(title,
                        style: const TextStyle(color: Colors.black54)),
                  ],
                )
              ],
            ),
          );
        },
      ),
    );
  }

  // ---------------- SYSTEM ANALYSIS ----------------
  Widget _systemAnalysis() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("İçerik Analizi",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
        const SizedBox(height: 20),

        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('scenarios').snapshots(),
          builder: (context, snapshot) {
            int senaryo = 0;
            int soru = 0;

            if (snapshot.hasData) {
              senaryo = snapshot.data!.docs.length;
              for (var doc in snapshot.data!.docs) {
                final bolumler = (doc.data() as Map)['bolumler'] ?? [];
                for (var b in bolumler) {
                  soru += (b['sorular'] as List?)?.length ?? 0;
                }
              }
            }

            return Row(
              children: [
                _miniBox("Senaryo", senaryo, Colors.purple),
                const SizedBox(width: 12),
                _miniBox("Soru", soru, Colors.indigo),
              ],
            );
          },
        )
      ],
    );
  }

  // ---------------- USER METRICS ----------------
  Widget _userMetrics() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Kullanıcılar",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
        const SizedBox(height: 20),

        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('users').snapshots(),
          builder: (context, snapshot) {
            int total = 0;
            int online = 0;

            if (snapshot.hasData) {
              total = snapshot.data!.docs.length;
              online = snapshot.data!.docs
                  .where((e) => (e.data() as Map)['isOnline'] == true)
                  .length;
            }

            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _bigStat("Online", online, Colors.green , isOnline: true),
                _bigStat("Toplam", total, Colors.indigo),
              ],
            );
          },
        )
      ],
    );
  }

  // ---------------- ACTION ----------------
  Widget _actionCenter(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Aksiyon Merkezi",
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),

          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
              minimumSize: const Size(double.infinity, 50),
            ),
            icon: const Icon(Icons.download),
            label: const Text("Rapor Oluştur"),
            onPressed: () async {
              await ReportService().sistemRaporuOlustur();
            },
          )
        ],
      ),
    );
  }

  // ---------------- COMPONENTS ----------------
  Widget _miniBox(String label, int value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Text("$value",
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: color)),
            Text(label, style: const TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _bigStat(String label, int value, Color color, {bool isOnline = false}) {
    return Column(
      children: [
        Row(
          children: [
            if (isOnline)
              Container(
                width: 10,
                height: 10,
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.green.withOpacity(0.6),
                      blurRadius: 8,
                      spreadRadius: 1,
                    )
                  ],
                ),
              ),

            Text(
              "$value",
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: Colors.grey)),
      ],
    );
  }

  Widget _card(Widget child) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            blurRadius: 12,
            color: Colors.black.withOpacity(0.04),
          )
        ],
      ),
      child: child,
    );
  }
}