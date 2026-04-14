import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_animate/flutter_animate.dart';

class SiberImdatEkrani extends StatefulWidget {
  const SiberImdatEkrani({super.key});

  @override
  State<SiberImdatEkrani> createState() => _SiberImdatEkraniState();
}

class _SiberImdatEkraniState extends State<SiberImdatEkrani> {
  // Güvenlik Kontrol Listesi Verileri
  final List<Map<String, dynamic>> _kontrolListesi = [
    {"baslik": "Ekran görüntüsü (kanıt) aldım", "tamamlandi": false},
    {"baslik": "Zorbalık yapanı hemen engelledim", "tamamlandi": false},
    {"baslik": "Güvendiğim bir büyüğüme anlattım", "tamamlandi": false},
    {"baslik": "Siber Asistan ile durumu paylaştım", "tamamlandi": false},
  ];

  Future<void> _ara(String num) async => await launchUrl(Uri.parse("tel:$num"));

  Future<void> _haritaGit(String yer) async {
    // URL yapısını düzelttim
    final url = "https://www.google.com/maps/search/${Uri.encodeComponent(yer)}";
    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FD),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildSliverAppBar(),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildEmergencySection(),
                  const SizedBox(height: 30),
                  _buildSectionTitle("YARDIM NOKTALARI"),
                  const SizedBox(height: 15),
                  _buildModernMapGrid(),
                  const SizedBox(height: 30),
                  _buildSectionTitle("GÜVENLİ ADIMLAR"),
                  const SizedBox(height: 15),
                  _buildChecklistSection(), // Kontrol Listesi Buraya Geldi
                  const SizedBox(height: 40),
                  _buildLegalFooter(),
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
      expandedHeight: 180,
      floating: false,
      pinned: true,
      backgroundColor: const Color(0xFFE74C3C),
      flexibleSpace: FlexibleSpaceBar(
        centerTitle: true,
        title: const Text("GÜVENLİK MERKEZİ",
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Colors.white)),
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFE74C3C), Color(0xFFC0392B)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Opacity(
            opacity: 0.2,
            child: const Icon(Icons.security, size: 150, color: Colors.white),
          ),
        ),
      ),
    );
  }

  Widget _buildEmergencySection() {
    return Row(
      children: [
        Expanded(child: _buildPanicCapsule("112", "ACİL SERVİS", const Color(0xFFE74C3C), Icons.emergency_share)),
        const SizedBox(width: 15),
        Expanded(child: _buildPanicCapsule("183", "DESTEK HATTI", const Color(0xFFF39C12), Icons.support_agent_rounded)),
      ],
    );
  }

  Widget _buildPanicCapsule(String num, String label, Color color, IconData icon) {
    return GestureDetector(
      onTap: () => _ara(num),
      child: Container(
        height: 160,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(35),
          boxShadow: [
            BoxShadow(color: color.withOpacity(0.15), blurRadius: 20, offset: const Offset(0, 10))
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 30),
            ),
            const SizedBox(height: 10),
            Text(num, style: TextStyle(color: color, fontSize: 32, fontWeight: FontWeight.bold)),
            Text(label, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 10, color: Colors.grey)),
          ],
        ),
      ),
    ).animate(onPlay: (c) => c.repeat()).shimmer(delay: 3.seconds, duration: 1500.ms);
  }

  Widget _buildModernMapGrid() {
    return Row(
      children: [
        Expanded(child: _buildMapCard("Polis", Icons.local_police_rounded, Colors.blueAccent, "en yakın polis merkezi")),
        const SizedBox(width: 15),
        Expanded(child: _buildMapCard("Yardım", Icons.volunteer_activism, Colors.green, "en yakın sosyal hizmetler")),
      ],
    );
  }

  Widget _buildMapCard(String title, IconData icon, Color color, String query) {
    return InkWell(
      onTap: () => _haritaGit(query),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(25),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(width: 10),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
      ),
    );
  }

  Widget _buildChecklistSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(35),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20)],
      ),
      child: Column(
        children: [
          ..._kontrolListesi.asMap().entries.map((entry) {
            return _buildCheckItem(entry.key);
          }).toList(),
          const SizedBox(height: 15),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Row(
              children: [
                Icon(Icons.lightbulb_outline, color: Colors.orange, size: 20),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    "Bu adımları takip etmek seni daha güvende tutar!",
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.orange),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.1);
  }

  Widget _buildCheckItem(int index) {
    bool isDone = _kontrolListesi[index]["tamamlandi"];
    return GestureDetector(
      onTap: () {
        setState(() {
          _kontrolListesi[index]["tamamlandi"] = !isDone;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
        decoration: BoxDecoration(
          color: isDone ? Colors.green.withOpacity(0.1) : const Color(0xFFF8F9FB),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDone ? Colors.green.withOpacity(0.3) : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isDone ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
              color: isDone ? Colors.green : Colors.grey.shade400,
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Text(
                _kontrolListesi[index]["baslik"],
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: isDone ? Colors.green.shade700 : Colors.blueGrey.shade800,
                  decoration: isDone ? TextDecoration.lineThrough : null,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String t) => Text(t, style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF2C3E50), fontSize: 13, letterSpacing: 1.2));

  Widget _buildLegalFooter() {
    return Center(
      child: Text("Yalnız değilsin, her zaman bir yardım yolu vardır.\nTehlike anında vakit kaybetmeden 112'yi ara.",
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 11, color: Colors.grey.shade500, height: 1.5, fontStyle: FontStyle.italic),
      ),
    );
  }
}