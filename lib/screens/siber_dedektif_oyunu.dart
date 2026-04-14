import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:confetti/confetti.dart';
import 'package:zorbalik_uygulamasi/app_theme.dart';

class SiberDedektifOyunu extends StatefulWidget {
  const SiberDedektifOyunu({super.key});

  @override
  State<SiberDedektifOyunu> createState() => _SiberDedektifOyunuState();
}

class _SiberDedektifOyunuState extends State<SiberDedektifOyunu> {
  late ConfettiController _confettiController;
  final User? _currentUser = FirebaseAuth.instance.currentUser;

  List<Map<String, dynamic>> _soruHavuzu = [];
  int _currentIndex = 0;
  int _puan = 0;
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

      List<Map<String, dynamic>> kalanlar = [...guvenliListesi, ...tehlikeliListesi];
      kalanlar.shuffle();
      while (finalSet.length < 5 && kalanlar.isNotEmpty) {
        finalSet.add(kalanlar.removeAt(0));
      }

      finalSet.shuffle();

      setState(() {
        _soruHavuzu = finalSet;
        if (_soruHavuzu.isEmpty && _bilinenSoruIds.isNotEmpty) {
           _bilinenSoruIds.clear(); 
           _verileriYukle(); 
           return;
        }
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Veri yükleme hatası: $e");
      setState(() => _isLoading = false);
    }
  }

  IconData _getIconFromName(String name) {
    switch (name) {
      case 'vpn_key': return Icons.vpn_key_rounded;
      case 'thumb_up': return Icons.thumb_up_rounded;
      case 'location_off': return Icons.location_off_rounded;
      case 'group_remove': return Icons.group_remove_rounded;
      case 'school': return Icons.school_rounded;
      case 'security': return Icons.security_rounded;
      case 'warning': return Icons.warning_amber_rounded;
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
      _puan += 20;
      _bilinenSoruIds.add(mevcutSoru["id"]);
      _confettiController.play();
      _showFeedback(true, mevcutSoru["aciklama"], mevcutSoru["gercekIkon"]);
    } else {
      _showFeedback(false, mevcutSoru["aciklama"], mevcutSoru["gercekIkon"]);
    }

    Future.delayed(const Duration(milliseconds: 2000), () {
      if (mounted) {
        setState(() {
          _isProcessing = false;
          if (_currentIndex < _soruHavuzu.length - 1 && _currentIndex < 4) { 
            _currentIndex++;
          } else {
            _oyunBitti = true;
            _ilerlemeyiTamamlaVeSenkronizeEt();
          }
        });
      }
    });
  }

  void _showFeedback(bool isCorrect, String msg, IconData icon) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(isCorrect ? "HARİKA! $msg" : "DİKKAT! $msg")),
          ],
        ),
        backgroundColor: isCorrect ? Colors.green : Colors.redAccent,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      ),
    );
  }

  Future<void> _ilerlemeyiTamamlaVeSenkronizeEt() async {
    if (_currentUser == null) return;
    try {
      final ref = FirebaseFirestore.instance.collection('usersProgress').doc(_currentUser!.uid);
      final doc = await ref.get();
      final data = doc.data() ?? {};

      List tamamlananlar = List.from(data['tamamlanan_bolumler'] ?? []);
      List okunanHikayeler = List.from(data['okunan_hikayeler'] ?? []);

      if (!tamamlananlar.contains("siber_dedektif")) {
        tamamlananlar.add("siber_dedektif");
      }

      int senaryoSayisi = tamamlananlar.where((id) => !id.toString().contains("siber_dedektif") && !id.toString().contains("ayak_izi_temizligi")).length;
      
      int senaryoPuani = senaryoSayisi * 100;
      int hikayePuani = okunanHikayeler.length * 10;
      int dedektifPuani = _bilinenSoruIds.length * 20;

      int yeniToplamPuan = senaryoPuani + hikayePuani + dedektifPuani;

      await ref.set({
        'toplam_puan': yeniToplamPuan,
        'tamamlanan_bolumler': tamamlananlar,
        'bilinen_dedektif_sorulari': _bilinenSoruIds,
        'sonGuncelleme': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint("Senkronizasyon hatası: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F7FF),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.anaMavi),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text("SİBER DEDEKTİF", style: TextStyle(fontWeight: FontWeight.w900, color: AppColors.anaMavi, letterSpacing: 1.2)),
        centerTitle: true,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16, top: 8, bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(color: Colors.amber.withOpacity(0.2), borderRadius: BorderRadius.circular(15)),
            child: Row(
              children: [
                const Icon(Icons.stars_rounded, color: Colors.orange, size: 20),
                const SizedBox(width: 4),
                Text("$_puan", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.orange)),
              ],
            ),
          )
        ],
      ),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : _soruHavuzu.isEmpty 
              ? _buildEmptyState()
              : Stack(
                  children: [
                    if (!_oyunBitti) _buildGameArea() else _buildResultArea(),
                    Align(
                      alignment: Alignment.topCenter,
                      child: ConfettiWidget(
                        confettiController: _confettiController,
                        blastDirectionality: BlastDirectionality.explosive,
                        colors: const [Colors.green, Colors.blue, Colors.yellow, Colors.pink],
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.auto_awesome, size: 100, color: Colors.amber).animate(onPlay: (c) => c.repeat()).shimmer(duration: 2.seconds, color: Colors.white.withOpacity(0.2)),
            const SizedBox(height: 25),
            const Text("TÜM GİZEMLER ÇÖZÜLDÜ!", textAlign: TextAlign.center, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: AppColors.anaMavi)),
            const SizedBox(height: 15),
            const Text("Harika bir iş çıkardın dedektif! Şimdilik tüm ipuçlarını değerlendirdin. Yeni görevler gelene kadar akademiyi gezmeye ne dersin?", textAlign: TextAlign.center, style: TextStyle(color: Colors.blueGrey, fontSize: 16)),
            const SizedBox(height: 40),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.anaMavi, minimumSize: const Size(double.infinity, 60), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
              onPressed: () => Navigator.pop(context), 
              child: const Text("AKADEMİYE DÖN", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))
            )
          ],
        ),
      ),
    );
  }

  Widget _buildGameArea() {
    final soru = _soruHavuzu[_currentIndex];
    return Column(
      children: [
        const SizedBox(height: 20),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("DAVA İLERLEMESİ", style: TextStyle(fontWeight: FontWeight.w900, color: Colors.blueGrey, fontSize: 12)),
                  Text("${_currentIndex + 1}/5", style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.anaMavi)),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: (_currentIndex + 1) / 5,
                  backgroundColor: Colors.white,
                  valueColor: const AlwaysStoppedAnimation<Color>(AppColors.anaMavi),
                  minHeight: 12,
                ),
              ),
            ],
          ),
        ),
        const Spacer(),
        Draggable(
          feedback: _buildCard(soru, opacity: 0.8),
          childWhenDragging: Opacity(opacity: 0.2, child: _buildCard(soru)),
          onDragEnd: (details) {
            if (details.offset.dx < -80) _kararVer("TEHLİKELİ");
            else if (details.offset.dx > 80) _kararVer("GÜVENLİ");
          },
          child: _buildCard(soru),
        ).animate().slideY(begin: 0.2, duration: 500.ms, curve: Curves.easeOutBack).fadeIn(),
        const Spacer(),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 40),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _actionButton("TEHLİKELİ", const Color(0xFFFF5252), Icons.report_gmailerrorred_rounded),
              _actionButton("GÜVENLİ", const Color(0xFF4CAF50), Icons.verified_user_rounded),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCard(Map<String, dynamic> soru, {double opacity = 1.0}) {
    return Container(
      width: MediaQuery.of(context).size.width * 0.82,
      height: MediaQuery.of(context).size.height * 0.42,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(opacity),
        borderRadius: BorderRadius.circular(35),
        boxShadow: [
          BoxShadow(color: AppColors.anaMavi.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, 10)),
          const BoxShadow(color: Colors.white, spreadRadius: -2, blurRadius: 0),
        ],
        border: Border.all(color: Colors.white, width: 6),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: AppColors.anaMavi.withOpacity(0.05), shape: BoxShape.circle),
            child: const Icon(Icons.search_rounded, size: 70, color: AppColors.anaMavi),
          ).animate(onPlay: (c) => c.repeat()).shimmer(duration: 2.seconds, color: Colors.white.withOpacity(0.2)),
          const SizedBox(height: 30),
          const Text("GİZEMLİ MESAJ", style: TextStyle(fontWeight: FontWeight.w900, color: Colors.blueGrey, fontSize: 12, letterSpacing: 2)),
          const SizedBox(height: 15),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 25),
            child: Text(
              soru["metin"],
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: Color(0xFF2D3142), height: 1.4, decoration: TextDecoration.none, fontFamily: 'Roboto'),
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
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: color.withOpacity(0.4), blurRadius: 15, offset: const Offset(0, 8))]
            ),
            child: Icon(icon, color: Colors.white, size: 35),
          ),
        ),
        const SizedBox(height: 12),
        Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 1)),
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
            const Icon(Icons.stars_rounded, size: 120, color: Colors.orangeAccent).animate().scale(duration: 600.ms, curve: Curves.bounceOut),
            const SizedBox(height: 25),
            const Text("DOSYA KAPANDI!", style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: AppColors.yaziRengi)),
            const SizedBox(height: 10),
            Text("Harika dedektiflik yaptın!\nBu görevden $_puan puan topladın.", textAlign: TextAlign.center, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.blueGrey)),
            const SizedBox(height: 45),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.anaMavi,
                minimumSize: const Size(double.infinity, 65),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                elevation: 8,
                shadowColor: AppColors.anaMavi.withOpacity(0.5)
              ),
              onPressed: () => Navigator.pop(context),
              child: const Text("DEVAM ET", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
            ),
          ],
        ),
      ),
    ).animate().fadeIn().scale();
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }
}
