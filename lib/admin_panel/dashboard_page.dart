import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/report_service.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FA),

      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _header(),
            const SizedBox(height: 35),

            _summaryGrid(), // Üst istatistik kartları
            const SizedBox(height: 35),

            // Alt layout → sol analiz + sağ aksiyon
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // SOL TARAF → analizler
                Expanded(
                  flex: 3,
                  child: Column(
                    children: [
                      _card(_systemAnalysis()), // içerik analizi
                      const SizedBox(height: 25),
                      _card(_userMetrics()), // kullanıcı istatistikleri
                    ],
                  ),
                ),

                const SizedBox(width: 25),

                // SAĞ TARAF → aksiyon merkezi
                Expanded(flex: 2, child: _actionCenter(context)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _header() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Sistem Özeti",
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w900,
                color: Color(0xFF0F172A),
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              "Platformun genel durumunu ve içerik istatistiklerini buradan takip edin.",
              style: TextStyle(
                color: Colors.blueGrey.shade400,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        _statusChip(),
      ],
    );
  }

  Widget _statusChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.12),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.green.withOpacity(0.3), width: 1.5),
      ),
      child: const Row(
        children: [
          Icon(Icons.check_circle_rounded, size: 16, color: Colors.green),
          SizedBox(width: 8),
          Text(
            "Sistem Aktif",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.green,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryGrid() {
    return Row(
      children: [
        _premiumStatCard(
          "Kahramanlar",
          "users",
          Icons.people_alt_rounded,
          const Color(0xFF6366F1),
          const Color(0xFF4338CA),
        ),
        const SizedBox(width: 20),
        _premiumStatCard(
          "Senaryolar",
          "scenarios",
          Icons.map_rounded,
          const Color(0xFF8B5CF6),
          const Color(0xFF6D28D9),
        ),
        const SizedBox(width: 20),
        _premiumStatCard(
          "Hikayeler",
          "stories",
          Icons.menu_book_rounded,
          const Color(0xFFF59E0B),
          const Color(0xFFD97706),
        ),
        const SizedBox(width: 20),
        _premiumStatCard(
          "Videolar",
          "videos",
          Icons.play_circle_fill_rounded,
          const Color(0xFFEC4899),
          const Color(0xFFBE185D),
        ),
      ],
    );
  }

  Widget _premiumStatCard(
    String title,
    String col,
    IconData icon,
    Color color1,
    Color color2,
  ) {
    return Expanded(
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection(col).snapshots(),
        builder: (context, snapshot) {
          final count = snapshot.hasData ? snapshot.data!.docs.length : 0;

          return Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color1, color2],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: color1.withOpacity(0.4),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(icon, color: Colors.white, size: 28),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "$count",
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        height: 1.1,
                      ),
                    ),
                    Text(
                      title,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _systemAnalysis() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.purple.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.analytics_rounded,
                color: Colors.purple,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              "İçerik İstatistikleri",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1E293B),
              ),
            ),
          ],
        ),
        const SizedBox(height: 25),

        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('scenarios')
              .snapshots(),
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
                _miniBox("Aktif Senaryo", senaryo, Colors.purple),
                const SizedBox(width: 16),
                _miniBox("Toplam Soru", soru, Colors.indigo),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _userMetrics() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.indigo.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.groups_rounded,
                color: Colors.indigo,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              "Kullanıcı Metrikleri",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1E293B),
              ),
            ),
          ],
        ),
        const SizedBox(height: 25),

        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('users').snapshots(),
          builder: (context, snapshot) {
            int total = 0;
            if (snapshot.hasData) {
              total = snapshot.data!.docs.length;
            }

            return Row(
              children: [_miniBox("Kayıtlı Kahramanlar", total, Colors.indigo)],
            );
          },
        ),
      ],
    );
  }

  Widget _actionCenter(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF3B82F6), Color(0xFF8B5CF6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF3B82F6).withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.picture_as_pdf_rounded,
              color: Colors.white,
              size: 32,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            "Verileri Raporla",
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Sistemdeki tüm gelişimi, kullanıcı verilerini ve içerik raporlarını tek tuşla PDF formatında dışa aktarın.",
            style: TextStyle(
              color: Colors.white.withOpacity(0.85),
              fontSize: 14,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF6366F1),
              minimumSize: const Size(double.infinity, 55),
              elevation: 5,
              shadowColor: Colors.black.withOpacity(0.2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            onPressed: () async {
              await ReportService().sistemRaporuOlustur();
            },
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.download_rounded, size: 20),
                SizedBox(width: 8),
                Text(
                  "PDF RAPORU OLUŞTUR",
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _miniBox(String label, int value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
        decoration: BoxDecoration(
          color: color.withOpacity(0.06),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.15), width: 1.5),
        ),
        child: Column(
          children: [
            Text(
              "$value",
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w900,
                color: color,
                height: 1.0,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: Colors.blueGrey.shade600,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _card(Widget child) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            blurRadius: 25,
            color: Colors.black.withOpacity(0.04),
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(color: Colors.grey.shade100, width: 2),
      ),
      child: child,
    );
  }
}
