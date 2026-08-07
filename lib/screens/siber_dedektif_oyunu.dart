import 'dart:math';
import 'package:flutter/material.dart';
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

    if (dogruMu) {
      _kazanilanPuan += 20;
      _bilinenSoruIds.add(mevcutSoru["id"]);
      _confettiController.play();
    } else {
      if (_currentUser != null) {
        // Hatalı cevapta yapay zekanın analizi için soruyu kaydediyoruz.
        _aiAnalysisService.logMistake(_currentUser!.uid, "Dedektif Oyunu Hatası: ${mevcutSoru["metin"]}");
      }
    }

    _showFeedback(dogruMu, mevcutSoru["aciklama"], mevcutSoru["gercekIkon"]);

    Future.delayed(const Duration(milliseconds: 2200), () {
      if (mounted) {
        setState(() {
          _isProcessing = false;
          if (_currentIndex < _soruHavuzu.length - 1) {
            _currentIndex++;
          } else {
            _oyunBitti = true;
            _verileriSenkronizeEt();
          }
        });
      }
    });
  }

  void _showFeedback(bool isCorrect, String msg, IconData icon) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(isCorrect ? "HARİKA! $msg" : "DİKKAT! $msg")),
          ],
        ),
        backgroundColor: isCorrect ? Colors.green.shade600 : Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _verileriSenkronizeEt() async {
    if (_currentUser == null) return;
    try {
      await AnalyticsService().aktiviteGuncelle(_currentUser!.uid, _kazanilanPuan);
      await FirebaseFirestore.instance.collection('usersProgress').doc(_currentUser!.uid).update({
        'bilinen_dedektif_sorulari': _bilinenSoruIds,
        'sonGuncelleme': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint("Senkronizasyon hatası: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F9FF),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: AppColors.anaMavi, size: 30),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text("KAHRAMAN DEDEKTİF",
            style: TextStyle(fontWeight: FontWeight.w900, color: AppColors.anaMavi, letterSpacing: 1.5 , fontSize: 18)),
        centerTitle: true,
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
            // İlerleme Barı
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("DAVA İLERLEMESİ", style: TextStyle(fontWeight: FontWeight.w900, color: Colors.blueGrey, fontSize: 11)),
                      Text("${_currentIndex + 1}/${_soruHavuzu.length}", style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.anaMavi)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: LinearProgressIndicator(
                      value: (_currentIndex + 1) / _soruHavuzu.length,
                      backgroundColor: Colors.white,
                      valueColor: const AlwaysStoppedAnimation<Color>(AppColors.anaMavi),
                      minHeight: 14,
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(),
            // Kart Alanı
            Draggable(
              feedback: Material(color: Colors.transparent, child: _buildCard(soru, opacity: 0.8)),
              childWhenDragging: Opacity(opacity: 0.2, child: _buildCard(soru)),
              onDragEnd: (details) {
                if (details.offset.dx < -100) _kararVer("TEHLİKELİ");
                else if (details.offset.dx > 100) _kararVer("GÜVENLİ");
              },
              child: _buildCard(soru),
            ).animate().slideY(begin: 0.2, duration: 600.ms, curve: Curves.easeOutBack).fadeIn(),
            const Spacer(),
            // Butonlar
            Padding(
              padding: const EdgeInsets.only(bottom: 40),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _actionButton("TEHLİKELİ", const Color(0xFFFF5252), Icons.gpp_bad_rounded),
                  _actionButton("GÜVENLİ", const Color(0xFF4CAF50), Icons.verified_user_rounded),
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

  Widget _buildCard(Map<String, dynamic> soru, {double opacity = 1.0}) {
    final size = MediaQuery.of(context).size;
    return Container(
      width: size.width * 0.88,
      constraints: BoxConstraints(
        minHeight: size.height * 0.35,
        maxHeight: size.height * 0.52,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(opacity),
        borderRadius: BorderRadius.circular(45),
        boxShadow: [
          BoxShadow(color: AppColors.anaMavi.withOpacity(0.12), blurRadius: 40, offset: const Offset(0, 20)),
        ],
        border: Border.all(color: AppColors.anaMavi.withOpacity(0.15), width: 8),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(37),
        child: Stack(
          children: [
            Positioned(
              right: -30, top: -30,
              child: Icon(Icons.search_rounded, size: 180, color: AppColors.anaMavi.withOpacity(0.03)),
            ),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(color: Colors.amber.shade100, borderRadius: BorderRadius.circular(15)),
                    child: Text("GİZEMLİ MESAJ", style: TextStyle(fontWeight: FontWeight.w900, color: Colors.amber.shade900, fontSize: 11, letterSpacing: 1)),
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: Center(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.of(context).size.width * 0.75,
                          ),
                          child: Text(
                            soru["metin"],
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF1A1D2E),
                              height: 1.4,
                              decoration: TextDecoration.none,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _actionButton(String label, Color color, IconData icon) {
    return Column(
      children: [
        GestureDetector(
          onTap: () => _kararVer(label),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: color.withOpacity(0.4), blurRadius: 20, offset: const Offset(0, 10))],
            ),
            child: Icon(icon, color: Colors.white, size: 35),
          ),
        ).animate(onPlay: (c) => c.repeat(reverse: true)).scale(begin: const Offset(1, 1), end: const Offset(1.05, 1.05), duration: 2.seconds),
        const SizedBox(height: 12),
        Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 1, decoration: TextDecoration.none)),
      ],
    );
  }

  Widget _buildResultArea() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.stars_rounded, size: 120, color: Colors.orangeAccent).animate().scale(duration: 800.ms, curve: Curves.bounceOut),
            const SizedBox(height: 20),
            const Text("GÖREV TAMAMLANDI!", style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: AppColors.anaMavi)),
            const SizedBox(height: 10),
            Text("Harika bir dedektifsin!\n$_kazanilanPuan Puan kazandın.", textAlign: TextAlign.center, style: const TextStyle(fontSize: 18, color: Colors.blueGrey, fontWeight: FontWeight.w600)),
            const SizedBox(height: 40),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.anaMavi,
                minimumSize: const Size(double.infinity, 65),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                elevation: 10,
              ),
              onPressed: () => Navigator.pop(context),
              child: const Text("AKADEMİYE DÖN", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
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
          const Icon(Icons.verified_rounded, size: 100, color: Colors.green).animate().shake(),
          const SizedBox(height: 20),
          const Text("HİÇ GİZEM KALMADI!", style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.anaMavi)),
          const SizedBox(height: 40),
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Geri Dön", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
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