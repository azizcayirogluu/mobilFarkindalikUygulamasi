import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:confetti/confetti.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:zorbalik_uygulamasi/app_theme.dart';
import 'package:zorbalik_uygulamasi/services/analytics_service.dart';
import 'package:zorbalik_uygulamasi/services/tts_service.dart';
import 'package:zorbalik_uygulamasi/services/ai_analysis_service.dart';
import 'package:flutter_animate/flutter_animate.dart';

class SenaryoDetayEkrani extends StatefulWidget {
  final String docId;
  final int bolumIndex;

  const SenaryoDetayEkrani({super.key, required this.docId, required this.bolumIndex});

  @override
  State<SenaryoDetayEkrani> createState() => _SenaryoDetayEkraniState();
}

class _SenaryoDetayEkraniState extends State<SenaryoDetayEkrani> with TickerProviderStateMixin {
  final TtsService _ttsService = TtsService();
  final AnalyticsService _analyticsService = AnalyticsService();
  final AiAnalysisService _aiAnalysisService = AiAnalysisService();
  late ConfettiController _confettiController;
  final User? _currentUser = FirebaseAuth.instance.currentUser;

  List _sorular = [];
  int _currentIndex = 0;
  bool _cevapVerildiMi = false;
  int? _secilenIndeks;
  bool _isLoading = true;
  bool _sesAcik = false;
  int _dogruCevapSayisi = 0;
  int _currentReadingSession = 0; 

  final List<Map<String, dynamic>> _userAnswersProof = [];

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 1));
    _verileriYukle();
  }

  Future<void> _soruyuVeSecenekleriSeslendir(Map soruData) async {
    if (!_sesAcik || !mounted) return;
    final sessionId = ++_currentReadingSession;

    String tamMetin = "${soruData['soru']}. ";
    List secenekler = soruData['secenekler'] ?? [];
    for (int i = 0; i < secenekler.length; i++) {
      String harf = String.fromCharCode(65 + i);
      tamMetin += "$harf şıkkı: ${secenekler[i]['metin']}. ";
    }

    try {
      if (_currentReadingSession != sessionId) return;
      await _ttsService.speak(tamMetin);
    } catch (e) {
      debugPrint("Seslendirme hatası: $e");
    }
  }

  Future<void> _verileriYukle() async {
    if (_currentUser == null) return;
    try {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(_currentUser!.uid).get();
      String kullaniciYasGrubu = userDoc.exists ? (userDoc.data()?['yasGrubu'] ?? "6-12") : "6-12";

      final doc = await FirebaseFirestore.instance.collection('scenarios').doc(widget.docId).get();
      if (doc.exists && mounted) {
        final data = doc.data();
        final bolumler = data?['bolumler'] as List? ?? [];

        if (bolumler.isNotEmpty && widget.bolumIndex < bolumler.length) {
          final tumSorularRaw = List.from(bolumler[widget.bolumIndex]['sorular'] ?? []);
          final filtrelenmisSorular = tumSorularRaw.where((s) => (s['yasGrubu'] ?? "6-12") == kullaniciYasGrubu).toList();

          final hazirSorular = [];
          for (var s in filtrelenmisSorular) {
            Map<String, dynamic> soruMap = Map<String, dynamic>.from(s);
            if (soruMap['secenekler'] != null) {
              List secList = List.from(soruMap['secenekler']);
              secList.shuffle();
              soruMap['secenekler'] = secList;
            }
            hazirSorular.add(soruMap);
          }

          setState(() {
            _sorular = hazirSorular;
            _isLoading = false;
          });

          if (_sorular.isNotEmpty && _sesAcik) {
            _soruyuVeSecenekleriSeslendir(_sorular[_currentIndex]);
          }
        } else {
           setState(() => _isLoading = false);
        }
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint("Veri yükleme hatası: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _cevapKontrol(int index, Map secenek) {
    if (_cevapVerildiMi) return;
    _ttsService.stop();

    setState(() {
      _secilenIndeks = index;
      _cevapVerildiMi = true;
    });

    _userAnswersProof.add({
      'soru': _sorular[_currentIndex]['soru'],
      'secenek': secenek['metin'],
      'dogru': secenek['dogru'] == true,
    });

    if (secenek['dogru'] == true) {
      _dogruCevapSayisi++;
      Future.delayed(const Duration(milliseconds: 600), () {
        if (mounted) _sonraki();
      });
    } else {
      if (_currentUser != null) {
        _analyticsService.hataKaydet(_currentUser!.uid);
        _aiAnalysisService.logMistake(_currentUser!.uid, "Hata: ${secenek['metin']}");
      }
      _showFeedback(secenek['feedback'] ?? "Hadi bir daha deneyelim! Gücüne inanıyoruz.");
    }
  }

  void _sonraki() {
    _currentReadingSession++; 
    _ttsService.stop();

    if (_currentIndex < _sorular.length - 1) {
      setState(() {
        _currentIndex++;
        _cevapVerildiMi = false;
        _secilenIndeks = null;
      });
      Future.delayed(const Duration(milliseconds: 300), () {
        if (_sesAcik && mounted) _soruyuVeSecenekleriSeslendir(_sorular[_currentIndex]);
      });
    } else {
      _sonucGoster();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (_sorular.isEmpty) return const Scaffold(body: Center(child: Text("Görev hazırlanıyor...")));

    final size = MediaQuery.of(context).size;
    final soru = _sorular[_currentIndex];
    double progress = (_currentIndex + 1) / _sorular.length;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: _buildAppBar(),
      body: Stack(
        children: [
          Column(
            children: [
              _buildModernProgressBar(progress, size),
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      const SizedBox(height: 10),
                      if (soru['imageUrl'] != null && soru['imageUrl'].isNotEmpty) 
                        _buildHeroImage(soru['imageUrl'], size),
                      const SizedBox(height: 20),
                      _buildQuestionCard(soru['soru']),
                      const SizedBox(height: 25),
                      ...List.generate(soru['secenekler'].length, (i) => _buildAnimatedOption(i, soru['secenekler'][i])),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ],
          ),
          ConfettiWidget(confettiController: _confettiController, blastDirectionality: BlastDirectionality.explosive),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      systemOverlayStyle: SystemUiOverlayStyle.dark,
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.close_rounded, color: Color(0xFF475569)),
        onPressed: () => Navigator.pop(context),
      ),
      centerTitle: true,
      title: Text(
        "GÖREV ${widget.bolumIndex + 1}",
        style: const TextStyle(color: Color(0xFF1E293B), fontWeight: FontWeight.w900, fontSize: 16),
      ),
      actions: [
        IconButton(
          icon: Icon(_sesAcik ? Icons.volume_up_rounded : Icons.volume_off_rounded, color: _sesAcik ? AppColors.anaMavi : Colors.grey),
          onPressed: () {
            setState(() {
              _sesAcik = !_sesAcik;
              if (_sesAcik) _soruyuVeSecenekleriSeslendir(_sorular[_currentIndex]);
              else _ttsService.stop();
            });
          },
        ),
        const SizedBox(width: 10),
      ],
    );
  }

  Widget _buildModernProgressBar(double val, Size size) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 10, 24, 20),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("MACERA YOLU 🚀", style: TextStyle(fontWeight: FontWeight.w900, color: Colors.blueGrey, fontSize: 10, letterSpacing: 1.2)),
              Text("${_currentIndex + 1} / ${_sorular.length}", style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.anaMavi, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: LinearProgressIndicator(
                value: val.clamp(0.0, 1.0),
                minHeight: 10,
                backgroundColor: Colors.white,
                valueColor: const AlwaysStoppedAnimation<Color>(AppColors.anaMavi)
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroImage(String url, Size size) {
    return Container(
      height: 220,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.white, width: 6),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(26),
        child: CachedNetworkImage(
          imageUrl: url,
          fit: BoxFit.cover,
          placeholder: (context, url) => Container(color: Colors.grey[100]).animate(onPlay: (c) => c.repeat()).shimmer(),
          errorWidget: (context, url, error) => const Icon(Icons.image_not_supported_rounded, color: Colors.grey, size: 50),
        ),
      ),
    ).animate().fadeIn().scale(begin: const Offset(0.95, 0.95));
  }

  Widget _buildQuestionCard(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFF1F5F9), width: 1.5),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF1E293B), height: 1.4),
      ),
    ).animate().slideY(begin: 0.1);
  }

  Widget _buildAnimatedOption(int index, Map secenek) {
    bool isSelected = _secilenIndeks == index;
    bool isCorrect = secenek['dogru'] == true;
    
    Color bgColor = Colors.white;
    Color borderColor = const Color(0xFFF1F5F9);
    if (isSelected) {
      bgColor = isCorrect ? const Color(0xFFECFDF5) : const Color(0xFFFEF2F2);
      borderColor = isCorrect ? const Color(0xFF10B981) : const Color(0xFFEF4444);
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: InkWell(
        onTap: () => _cevapKontrol(index, secenek),
        borderRadius: BorderRadius.circular(22),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: borderColor, width: 2),
            boxShadow: isSelected ? [] : [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 4))],
          ),
          child: Row(
            children: [
              Container(
                width: 32, height: 32,
                decoration: BoxDecoration(
                  color: isSelected 
                    ? (isCorrect ? const Color(0xFF10B981) : const Color(0xFFEF4444)) 
                    : const Color(0xFFF1F5F9),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    String.fromCharCode(65 + index),
                    style: TextStyle(
                      color: isSelected ? Colors.white : const Color(0xFF64748B),
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  secenek['metin'],
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: isSelected 
                      ? (isCorrect ? const Color(0xFF065F46) : const Color(0xFF991B1B)) 
                      : const Color(0xFF334155),
                  ),
                ),
              ),
              if (isSelected) 
                Icon(
                  isCorrect ? Icons.check_circle_rounded : Icons.cancel_rounded,
                  color: isCorrect ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(delay: (index * 100).ms).slideX(begin: 0.05);
  }

  void _showFeedback(String mesaj) {
    if (_sesAcik) _ttsService.speak(mesaj);
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
            const Icon(Icons.lightbulb_circle_rounded, color: Colors.amber, size: 70).animate(onPlay: (c) => c.repeat()).shimmer(),
            const SizedBox(height: 20),
            const Text("KAHRAMAN İPUCU", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: Colors.blueGrey, letterSpacing: 1.5)),
            const SizedBox(height: 12),
            Text(mesaj, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16, color: Color(0xFF1E293B), fontWeight: FontWeight.w600, height: 1.5)),
            const SizedBox(height: 30),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.anaMavi,
                minimumSize: const Size(double.infinity, 60),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                elevation: 0,
              ),
              onPressed: () { Navigator.pop(c); _sonraki(); },
              child: const Text("ANLADIM, DEVAM ET! 🚀", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
            )
          ],
        ),
      ),
    );
  }

  void _sonucGoster() async {
    double oran = (_dogruCevapSayisi / _sorular.length) * 100;
    bool basarili = oran >= 60;

    if (basarili) {
      _confettiController.play();
      try {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          await _analyticsService.bolumTamamla(user.uid, 0, "${widget.docId}_${widget.bolumIndex}", proof: List.from(_userAnswersProof));
        }
      } catch (e) {
        debugPrint("Senkronizasyon hatası: $e");
      }
    }

    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (c) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(35)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: basarili ? const Color(0xFFECFDF5) : const Color(0xFFFEF2F2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                basarili ? Icons.emoji_events_rounded : Icons.refresh_rounded,
                size: 60,
                color: basarili ? const Color(0xFF10B981) : const Color(0xFFEF4444),
              ),
            ).animate().scale(duration: 400.ms, curve: Curves.bounceOut),
            const SizedBox(height: 24),
            Text(
              basarili ? "TEBRİKLER KAHRAMAN!" : "TEKRAR DENEYELİM!",
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20, color: Color(0xFF1E293B)),
            ),
            const SizedBox(height: 12),
            Text(
              basarili ? "Bu görevi başarıyla tamamladın. Harika gidiyorsun!" : "Hadi bir şans daha! Başarabileceğini biliyoruz.",
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(20)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _statItem("Doğru", _dogruCevapSayisi, const Color(0xFF10B981)),
                  _statItem("Puan", oran.toInt(), const Color(0xFF6366F1)),
                ],
              ),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: basarili ? const Color(0xFF10B981) : const Color(0xFF6366F1),
                minimumSize: const Size(double.infinity, 55),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                elevation: 0,
              ),
              onPressed: () {
                Navigator.pop(c);
                Navigator.pop(context);
              },
              child: Text(
                basarili ? "DEVAM ET 🚀" : "TEKRAR DENE 🔁",
                style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statItem(String label, dynamic value, Color color) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.blueGrey)),
        const SizedBox(height: 4),
        Text("$value", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: color)),
      ],
    );
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _ttsService.stop();
    super.dispose();
  }
}
