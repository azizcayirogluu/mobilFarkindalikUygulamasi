import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
      "baslik": "Kanıtını Koru",
      "alt": "Mesajları veya ekran görüntülerini sakla.",
      "ikon": Icons.camera_enhance_rounded,
      "tamam": false
    },
    {
      "baslik": "Engelle",
      "alt": "Sana kötü davranan kişiyi engelleyebilirsin.",
      "ikon": Icons.shield_rounded,
      "tamam": false
    },
    {
      "baslik": "Birine Anlat",
      "alt": "Güvendiğin bir yetişkinden yardım iste.",
      "ikon": Icons.record_voice_over_rounded,
      "tamam": false
    },
    {
      "baslik": "Güvende Kal",
      "alt": "Tartışmadan uzaklaş ve güvenli bir yere geç.",
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
      final Uri uri = Uri.parse(
          "https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(yer)}");
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
    final double bottomInset = MediaQuery.paddingOf(context).bottom + 40;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          title: const FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              "Güvenlik Merkezi",
              style: TextStyle(
                color: Color(0xFF1E293B),
                fontWeight: FontWeight.w900,
                fontSize: 20,
                letterSpacing: -0.5,
              ),
            ),
          ),
          leading: Padding(
            padding: const EdgeInsets.only(left: 12),
            child: Center(
              child: Container(
                width: 38,
                height: 38,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x0F4F46E5),
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: IconButton(
                  padding: EdgeInsets.zero,
                  icon: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    size: 16,
                    color: Color(0xFF475569),
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
          ),
        ),
        body: SafeArea(
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(20, 10, 20, bottomInset),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeaderBanner(),
                      const SizedBox(height: 20),
                      _buildSafetyPromptCard(),
                      const SizedBox(height: 28),
                      _buildSectionTitle("ACİL YARDIM HATLARI 🚨"),
                      const SizedBox(height: 14),
                      _buildEmergencySection(),
                      const SizedBox(height: 28),
                      _buildSectionTitle("KAHRAMAN SAVUNMA KİTİ 🛡️"),
                      const SizedBox(height: 6),
                      const Text(
                        "Kendini korumak için bu adımları uygulayabilirsin:",
                        style: TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildDefenseGrid(),
                      const SizedBox(height: 28),
                      _buildSectionTitle("YARDIM ALABİLECEĞİN YERLER 📍"),
                      const SizedBox(height: 14),
                      _buildPlacesGrid(),
                      const SizedBox(height: 40),
                      _buildReassuringFooter(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: const Color(0xFF3B82F6).withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.shield_rounded,
              color: Color(0xFF3B82F6),
              size: 28,
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Yanındayız Kahraman 💙",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF1E293B),
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  "Yalnız değilsin. Yardım istemek güçlü olmaktır.",
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w600,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.05);
  }

  Widget _buildSafetyPromptCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFEFF6FF), Color(0xFFE0F2FE)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFBAE6FD), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.check_circle_outline_rounded, color: Color(0xFF0284C7), size: 22),
              SizedBox(width: 8),
              Text(
                "Şu anda güvende misin?",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF0369A1),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            "Birisi sana kötü davranıyorsa veya kendini güvende hissetmiyorsan yardım isteyebilirsin.",
            style: TextStyle(
              fontSize: 13,
              color: Color(0xFF334155),
              fontWeight: FontWeight.w500,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _ara("183"),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0284C7),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                elevation: 0,
              ),
              icon: const Icon(Icons.record_voice_over_rounded, size: 20),
              label: const FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  "Bir Yetişkinden Yardım İste 🤝",
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
                ),
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 50.ms).slideY(begin: 0.05);
  }

  Widget _buildEmergencySection() {
    return Row(
      children: [
        _buildEmergencyCard(
          number: "112",
          title: "Polis • Ambulans",
          subtitle: "Acil bir tehlike varsa ara",
          color: const Color(0xFFEF4444),
          icon: Icons.emergency_rounded,
          onTap: () => _ara("112"),
        ),
        const SizedBox(width: 14),
        _buildEmergencyCard(
          number: "183",
          title: "Destek Hattı",
          subtitle: "Destek ve danışmanlık için",
          color: const Color(0xFF3B82F6),
          icon: Icons.headset_mic_rounded,
          onTap: () => _ara("183"),
        ),
      ],
    );
  }

  Widget _buildEmergencyCard({
    required String number,
    required String title,
    required String subtitle,
    required Color color,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: color.withValues(alpha: 0.3), width: 2),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.08),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: color, size: 20),
                  ),
                  Text(
                    number,
                    style: TextStyle(
                      color: color,
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF1E293B),
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  height: 1.25,
                ),
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.05);
  }

  Widget _buildDefenseGrid() {
    final double screenWidth = MediaQuery.sizeOf(context).width;
    final double calculatedRatio = math.max(0.85, screenWidth / 420);

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
        childAspectRatio: calculatedRatio,
      ),
      itemCount: _savunmaAdimlari.length,
      itemBuilder: (context, index) => _defenseCard(index),
    );
  }

  Widget _defenseCard(int index) {
    final item = _savunmaAdimlari[index];
    final bool isDone = item["tamam"] == true;
    final Color color = isDone ? const Color(0xFF10B981) : const Color(0xFF6366F1);

    return InkWell(
      onTap: () => setState(() => _savunmaAdimlari[index]["tamam"] = !isDone),
      borderRadius: BorderRadius.circular(22),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDone ? color.withValues(alpha: 0.06) : Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: isDone ? color : const Color(0xFFE2E8F0),
            width: 2,
          ),
          boxShadow: [
            if (!isDone)
              const BoxShadow(
                color: Color(0x05000000),
                blurRadius: 8,
                offset: Offset(0, 3),
              ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(item["ikon"], color: color, size: 22),
                ),
                Icon(
                  isDone ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                  color: isDone ? color : const Color(0xFFCBD5E1),
                  size: 20,
                ),
              ],
            ),
            const SizedBox(height: 10),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                item["baslik"],
                style: const TextStyle(
                  color: Color(0xFF1E293B),
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Expanded(
              child: Text(
                item["alt"],
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  height: 1.3,
                ),
              ),
            ),
          ],
        ),
      ),
    ).animate(target: isDone ? 1 : 0).shimmer(duration: 800.ms);
  }

  Widget _buildPlacesGrid() {
    return Row(
      children: [
        _mapBtn(
          "Polis Merkezi",
          "Polisten yardım al",
          Icons.local_police_rounded,
          const Color(0xFF3B82F6),
          "en yakın polis merkezi",
        ),
        const SizedBox(width: 14),
        _mapBtn(
          "Sosyal Destek",
          "Destek hizmetlerine ulaş",
          Icons.volunteer_activism_rounded,
          const Color(0xFF10B981),
          "en yakın sosyal hizmetler",
        ),
      ],
    );
  }

  Widget _mapBtn(
      String title,
      String subtitle,
      IconData icon,
      Color color,
      String query,
      ) {
    return Expanded(
      child: InkWell(
        onTap: () => _haritaGit(query),
        borderRadius: BorderRadius.circular(22),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
            boxShadow: const [
              BoxShadow(
                color: Color(0x05000000),
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(height: 12),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                    color: Color(0xFF1E293B),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  height: 1.25,
                ),
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(delay: 150.ms).slideY(begin: 0.05);
  }

  Widget _buildSectionTitle(String t) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Text(
        t,
        style: const TextStyle(
          fontWeight: FontWeight.w900,
          color: Color(0xFF1E293B),
          fontSize: 13,
          letterSpacing: 1,
        ),
      ),
    );
  }

  Widget _buildReassuringFooter() {
    return Column(
      children: [
        const Divider(color: Color(0xFFE2E8F0)),
        const SizedBox(height: 16),
        Text(
          "Yalnız değilsin, her zaman bir yardım yolu vardır.\nTehlike anında vakit kaybetmeden 112'yi ara.",
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
            height: 1.5,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
