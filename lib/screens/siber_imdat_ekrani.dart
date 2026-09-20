import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_animate/flutter_animate.dart';

class SiberImdatEkrani extends StatefulWidget {
  const SiberImdatEkrani({super.key});

  @override
  State<SiberImdatEkrani> createState() => _SiberImdatEkraniState();
}

class _SiberImdatEkraniState extends State<SiberImdatEkrani> {
  final List<Map<String, dynamic>> _savunmaAdimlari = [
    {
      "baslik": "Kanıt Topla",
      "alt": "Ekran görüntüsü almayı unutma!",
      "ikon": Icons.camera_enhance_rounded,
      "tamam": false
    },
    {
      "baslik": "Kalkanı Aç",
      "alt": "Zorbalık yapanı hemen engelle!",
      "ikon": Icons.shield_rounded,
      "tamam": false
    },
    {
      "baslik": "Yardım İste",
      "alt": "Güvendiğin bir büyüğüne anlat.",
      "ikon": Icons.record_voice_over_rounded,
      "tamam": false
    },
    {
      "baslik": "Sessiz Kalma",
      "alt": "Durumu Kahraman Rehberinle paylaş.",
      "ikon": Icons.volunteer_activism_rounded,
      "tamam": false
    },
  ];

  Future<void> _ara(String num) async {
    try {
      final Uri uri = Uri.parse("tel:$num");
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        _hataGoster("Arama yapılamadı. 📞");
      }
    } catch (e) {
      _hataGoster("Hata oluştu.");
    }
  }

  Future<void> _haritaGit(String yer) async {
    try {
      final Uri uri = Uri.parse("https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(yer)}");
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {}
  }

  void _hataGoster(String mesaj) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mesaj, style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildSliverAppBar(),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle("ACİL YARDIM HATLARI 🚨"),
                  const SizedBox(height: 16),
                  _buildEmergencySection(),
                  const SizedBox(height: 32),
                  _buildSectionTitle("KAHRAMAN SAVUNMA KİTİ 🛡️"),
                  const SizedBox(height: 12),
                  const Text(
                    "Güvende kalmak için bu adımları aktifleştir!",
                    style: TextStyle(color: Colors.blueGrey, fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 20),
                  _buildDefenseGrid(),
                  const SizedBox(height: 32),
                  _buildSectionTitle("YAKIN YARDIM NOKTALARI 📍"),
                  const SizedBox(height: 16),
                  _buildModernMapGrid(),
                  const SizedBox(height: 60),
                  _buildLegalFooter(),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 160,
      pinned: true,
      backgroundColor: const Color(0xFFEF4444),
      elevation: 0,
      leading: Padding(
        padding: const EdgeInsets.all(8.0),
        child: CircleAvatar(
          backgroundColor: Colors.white24,
          child: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 16),
            onPressed: () => Navigator.pop(context),
          ),
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        centerTitle: true,
        title: const Text("GÜVENLİK MERKEZİ", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 1)),
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(colors: [Color(0xFFEF4444), Color(0xFFDC2626)], begin: Alignment.topLeft, end: Alignment.bottomRight),
          ),
          child: Center(child: Opacity(opacity: 0.15, child: const Icon(Icons.shield_rounded, size: 120, color: Colors.white))),
        ),
      ),
    );
  }

  Widget _buildEmergencySection() {
    return Row(
      children: [
        _panicButton("112", "POLİS / AMBULANS", const Color(0xFFEF4444)),
        const SizedBox(width: 16),
        _panicButton("183", "DESTEK HATTI", const Color(0xFFF59E0B)),
      ],
    );
  }

  Widget _panicButton(String num, String label, Color color) {
    return Expanded(
      child: GestureDetector(
        onTap: () => _ara(num),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: color.withOpacity(0.2), width: 2),
            boxShadow: [BoxShadow(color: color.withOpacity(0.08), blurRadius: 15, offset: const Offset(0, 8))],
          ),
          child: Column(
            children: [
              Text(num, style: TextStyle(color: color, fontSize: 28, fontWeight: FontWeight.w900)),
              const SizedBox(height: 4),
              Text(label, style: const TextStyle(color: Colors.blueGrey, fontSize: 9, fontWeight: FontWeight.w800)),
            ],
          ),
        ),
      ),
    ).animate(onPlay: (c) => c.repeat(reverse: true)).scale(begin: const Offset(1, 1), end: const Offset(1.02, 1.02), duration: 2.seconds);
  }

  Widget _buildDefenseGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.1,
      ),
      itemCount: _savunmaAdimlari.length,
      itemBuilder: (context, index) => _defenseCard(index),
    );
  }

  Widget _defenseCard(int index) {
    final item = _savunmaAdimlari[index];
    final bool isDone = item["tamam"];
    final Color color = isDone ? const Color(0xFF10B981) : const Color(0xFF6366F1);

    return GestureDetector(
      onTap: () => setState(() => _savunmaAdimlari[index]["tamam"] = !isDone),
      child: AnimatedContainer(
        duration: 300.ms,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDone ? color.withOpacity(0.05) : Colors.white,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: isDone ? color : const Color(0xFFF1F5F9), width: 2.5),
          boxShadow: [if (!isDone) BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(item["ikon"], color: color, size: 32),
            const SizedBox(height: 12),
            Text(item["baslik"], style: TextStyle(color: Color(0xFF1E293B), fontWeight: FontWeight.w900, fontSize: 14)),
            const SizedBox(height: 2),
            Text(item["alt"], textAlign: TextAlign.center, style: TextStyle(color: Colors.blueGrey, fontSize: 9, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    ).animate(target: isDone ? 1 : 0).shimmer(duration: 1.seconds);
  }

  Widget _buildModernMapGrid() {
    return Row(
      children: [
        _mapBtn("Polis Merkezi", Icons.local_police_rounded, const Color(0xFF3B82F6), "en yakın polis merkezi"),
        const SizedBox(width: 16),
        _mapBtn("Sosyal Yardım", Icons.volunteer_activism, const Color(0xFF10B981), "en yakın sosyal hizmetler"),
      ],
    );
  }

  Widget _mapBtn(String title, IconData icon, Color color, String query) {
    return Expanded(
      child: InkWell(
        onTap: () => _haritaGit(query),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFFF1F5F9))),
          child: Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 10),
              Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 11, color: Color(0xFF1E293B)))),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String t) => Text(t, style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF1E293B), fontSize: 13, letterSpacing: 1));

  Widget _buildLegalFooter() {
    return Column(
      children: [
        const Divider(),
        const SizedBox(height: 16),
        Text(
          "Yalnız değilsin, her zaman bir yardım yolu vardır.\nTehlike anında vakit kaybetmeden 112'yi ara.",
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 11, color: Colors.grey.shade500, height: 1.6, fontStyle: FontStyle.italic),
        ),
      ],
    );
  }
}
