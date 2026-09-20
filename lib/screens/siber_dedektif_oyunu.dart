import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:confetti/confetti.dart';
import 'package:zorbalik_uygulamasi/app_theme.dart';
import 'package:zorbalik_uygulamasi/services/analytics_service.dart';
import 'package:zorbalik_uygulamasi/services/ai_analysis_service.dart';

class SiberDedektifOyunu extends StatefulWidget {
  const SiberDedektifOyunu({super.key});

  @override
  State<SiberDedektifOyunu> createState() => _SiberDedektifOyunuState();
}

class _SiberDedektifOyunuState extends State<SiberDedektifOyunu> {
  late ConfettiController _confettiController;
  final User? _currentUser = FirebaseAuth.instance.currentUser;
  final AiAnalysisService _aiAnalysisService = AiAnalysisService();

  List<Map<String, dynamic>> _soruHavuzu = [];
  int _currentIndex = 0;
  int _kazanilanPuan = 0;
  bool _oyunBitti = false;
  bool _isLoading = true;
  bool _isProcessing = false;
  List<String> _bilinenSoruIds = [];

  final List<Map<String, String>> _gameProof = [];

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 1));
    _verileriYukle();
  }

  Future<void> _verileriYukle() async {
    if (_currentUser == null) return;
    try {
      final userDoc = await FirebaseFirestore.instance.collection('usersProgress').doc(_currentUser!.uid).get();
      if (userDoc.exists) {
        _bilinenSoruIds = List<String>.from(userDoc.data()?['bilinen_dedektif_sorulari'] ?? []);
      }

      final snap = await FirebaseFirestore.instance.collection('detective_questions').get();
      List<Map<String, dynamic>> guvenliListesi = [];
      List<Map<String, dynamic>> tehlikeliListesi = [];

      for (var doc in snap.docs) {
        if (!_bilinenSoruIds.contains(doc.id)) {
          final data = doc.data();
          final soru = {
            "id": doc.id,
            "metin": data['metin'] ?? "",
            "durum": data['durum'] ?? "TEHLİKELİ",
            "aciklama": data['aciklama'] ?? "",
            "gercekIkon": _getIconFromName(data['ikon'] ?? "help"),
            "gercekRenk": _getColorFromHex(data['renk'] ?? "#607D8B"),
          };
          if (soru["durum"] == "GÜVENLİ") {
            guvenliListesi.add(soru);
          } else {
            tehlikeliListesi.add(soru);
          }
        }
      }

      guvenliListesi.shuffle();
      tehlikeliListesi.shuffle();

      List<Map<String, dynamic>> finalSet = [];
      int hedefGuvenli = 2 + Random().nextInt(2);
      int hedefTehlikeli = 5 - hedefGuvenli;

      for (int i = 0; i < hedefGuvenli && guvenliListesi.isNotEmpty; i++) {
        finalSet.add(guvenliListesi.removeAt(0));
      }
      for (int i = 0; i < hedefTehlikeli && tehlikeliListesi.isNotEmpty; i++) {
        finalSet.add(tehlikeliListesi.removeAt(0));
      }

      finalSet.shuffle();

      setState(() {
        _soruHavuzu = finalSet;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Hata: $e");
      setState(() => _isLoading = false);
    }
  }

  IconData _getIconFromName(String name) {
    switch (name) {
      case 'vpn_key': return Icons.vpn_key_rounded;
      case 'thumb_up': return Icons.thumb_up_rounded;
      case 'location_off': return Icons.location_off_rounded;
      default: return Icons.help_outline_rounded;
    }
  }

  Color _getColorFromHex(String hexColor) {
    hexColor = hexColor.replaceAll("#", "");
    if (hexColor.length == 6) hexColor = "FF$hexColor";
    return Color(int.parse("0x$hexColor"));
  }

  void _kararVer(String karar) {
    if (_isProcessing || _oyunBitti || _soruHavuzu.isEmpty) return;
    setState(() => _isProcessing = true);

    final mevcutSoru = _soruHavuzu[_currentIndex];
    bool dogruMu = mevcutSoru["durum"] == karar;

    _gameProof.add({"id": mevcutSoru["id"], "choice": karar});

    if (dogruMu) {
      _kazanilanPuan += 20;
      _bilinenSoruIds.add(mevcutSoru["id"]);
    } else {
      if (_currentUser != null) {
        _aiAnalysisService.logMistake(_currentUser!.uid, "Dedektif Oyunu Hatası: ${mevcutSoru["metin"]}");
      }
    }

    _showInteractiveFeedback(dogruMu, mevcutSoru["aciklama"], mevcutSoru["gercekIkon"]);
  }

  void _nextStep() {
    setState(() {
      _isProcessing = false;
      if (_currentIndex < _soruHavuzu.length - 1) {
        _currentIndex++;
      } else {
        _oyunBitti = true;
        if (_kazanilanPuan >= 60) {
          _confettiController.play();
        }
        _verileriSenkronizeEt();
      }
    });
  }

  void _showInteractiveFeedback(bool isCorrect, String msg, IconData icon) {
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (c) => Container(
        padding: const EdgeInsets.all(32),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(40)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isCorrect ? const Color(0xFFECFDF5) : const Color(0xFFFEF2F2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isCorrect ? Icons.check_circle_rounded : Icons.warning_rounded,
                size: 60,
                color: isCorrect ? const Color(0xFF10B981) : const Color(0xFFEF4444),
              ),
            ).animate().scale(duration: 400.ms, curve: Curves.bounceOut),
            const SizedBox(height: 20),
            Text(
              isCorrect ? "HARİKA KARAR! 🏆" : "DİKKATLİ OL! 🛡️",
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 20,
                color: isCorrect ? const Color(0xFF065F46) : const Color(0xFF991B1B),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              msg,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, color: Color(0xFF475569), fontWeight: FontWeight.w600, height: 1.5),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: isCorrect ? const Color(0xFF10B981) : const Color(0xFF6366F1),
                minimumSize: const Size(double.infinity, 60),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                elevation: 0,
              ),
              onPressed: () {
                Navigator.pop(c);
                _nextStep();
              },
              child: const Text("DEVAM ET 🚀", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
            )
          ],
        ),
      ),
    );
  }

  Future<void> _verileriSenkronizeEt() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      await AnalyticsService().aktiviteGuncelle(user.uid, 0, proof: List.from(_gameProof));
    } catch (e) {
      debugPrint("Senkronizasyon hatası: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        toolbarHeight: 90,
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: const Padding(
          padding: EdgeInsets.only(top: 25),
          child: Text(
            "KAHRAMAN DEDEKTİF",
            style: TextStyle(color: Color(0xFF1E293B), fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: 1),
          ),
        ),
        leading: Padding(
          padding: const EdgeInsets.only(left: 16, top: 25),
          child: Container(
            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4))]),
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: Color(0xFF475569)),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _soruHavuzu.isEmpty
            ? _buildEmptyState()
            : _oyunBitti ? _buildResultArea() : _buildGameLayout(),
      ),
    );
  }

  Widget _buildGameLayout() {
    final soru = _soruHavuzu[_currentIndex];
    return Stack(
      children: [
        Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("DAVA İLERLEMESİ 🔍", style: TextStyle(fontWeight: FontWeight.w900, color: Colors.blueGrey, fontSize: 10, letterSpacing: 1.2)),
                      Text("${_currentIndex + 1} / ${_soruHavuzu.length}", style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF6366F1), fontSize: 12)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: LinearProgressIndicator(
                      value: (_currentIndex + 1) / _soruHavuzu.length,
                      backgroundColor: Colors.white,
                      valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF6366F1)),
                      minHeight: 12,
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(),
            _buildCard(soru).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, curve: Curves.easeOutBack),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.only(bottom: 50),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _actionButton("TEHLİKELİ", const Color(0xFFEF4444), Icons.gpp_bad_rounded),
                  _actionButton("GÜVENLİ", const Color(0xFF10B981), Icons.verified_user_rounded),
                ],
              ),
            ),
          ],
        ),
        Align(
          alignment: Alignment.topCenter,
          child: ConfettiWidget(
            confettiController: _confettiController,
            blastDirectionality: BlastDirectionality.explosive,
            colors: const [Colors.green, Colors.blue, Colors.yellow, Colors.orange],
          ),
        ),
      ],
    );
  }

  Widget _buildCard(Map<String, dynamic> soru) {
    final size = MediaQuery.of(context).size;
    return Container(
      width: size.width * 0.85,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(35),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 30, offset: const Offset(0, 15))],
        border: Border.all(color: const Color(0xFFF1F5F9), width: 2),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 15),
            decoration: const BoxDecoration(
              color: Color(0xFFF8FAFC),
              borderRadius: BorderRadius.vertical(top: Radius.circular(31)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.fingerprint_rounded, size: 18, color: Colors.blueGrey),
                const SizedBox(width: 8),
                Text("GİZEMLİ MESAJ #0${_currentIndex + 1}", style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.blueGrey, fontSize: 10, letterSpacing: 1.5)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(25, 35, 25, 45),
            child: Text(
              soru["metin"],
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: Color(0xFF1E293B),
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionButton(String label, Color color, IconData icon) {
    return Column(
      children: [
        GestureDetector(
          onTap: () => _kararVer(label),
          child: Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: color.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8))],
            ),
            child: Icon(icon, color: Colors.white, size: 32),
          ),
        ).animate(onPlay: (c) => c.repeat(reverse: true)).scale(begin: const Offset(1, 1), end: const Offset(1.08, 1.08), duration: 1.seconds),
        const SizedBox(height: 12),
        Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 1)),
      ],
    );
  }

  Widget _buildResultArea() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(35.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(30),
              decoration: BoxDecoration(color: const Color(0xFFFEF3C7), shape: BoxShape.circle),
              child: const Icon(Icons.stars_rounded, size: 80, color: Color(0xFFF59E0B)),
            ).animate().scale(duration: 400.ms, curve: Curves.bounceOut),
            const SizedBox(height: 30),
            const Text("GÖREV TAMAMLANDI!", textAlign: TextAlign.center, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xFF1E293B))),
            const SizedBox(height: 12),
            Text("Harika bir dedektifsin!\n$_kazanilanPuan Puan başarı koleksiyonuna eklendi.", textAlign: TextAlign.center, style: const TextStyle(fontSize: 15, color: Color(0xFF64748B), fontWeight: FontWeight.w600, height: 1.4)),
            const SizedBox(height: 45),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1),
                minimumSize: const Size(double.infinity, 60),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                elevation: 0,
              ),
              onPressed: () => Navigator.pop(context),
              child: const Text("AKADEMİYE DÖN 🚀", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(30),
            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
            child: const Icon(Icons.verified_rounded, size: 60, color: Color(0xFF10B981)),
          ).animate().shake(),
          const SizedBox(height: 24),
          const Text("HİÇ GİZEM KALMADI!", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF1E293B))),
          const SizedBox(height: 8),
          const Text("Bütün davaları çözdün Kahraman!", style: TextStyle(fontSize: 14, color: Color(0xFF64748B), fontWeight: FontWeight.w500)),
          const SizedBox(height: 40),
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Geri Dön", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF6366F1)))),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }
}
