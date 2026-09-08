import 'package:flutter/material.dart';
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
  int _currentReadingSession = 0; // Seslendirme çakışmalarını önlemek için session ID

  // KANIT: Bölüm boyunca verilen tüm cevapları tutar (SEC-01 & SEC-02 Fix)
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

    // Önce tüm metni tek bir paket yapalım
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
              // Client tarafında şıklar karıştırılır ama doğru cevap bilgisi saklı kalır
              secList.shuffle();
              soruMap['secenekler'] = secList;
            }
            hazirSorular.add(soruMap);
          }

          setState(() {
            _sorular = hazirSorular;
            _isLoading = false;
          });

          for (var s in hazirSorular) {
            if (s['imageUrl'] != null && s['imageUrl'].toString().isNotEmpty) {
              precacheImage(CachedNetworkImageProvider(s['imageUrl']), context);
            }
          }

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
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _cevapKontrol(int index, Map secenek) {
    if (_cevapVerildiMi) return;
    _ttsService.stop();

    setState(() {
      _secilenIndeks = index;
      _cevapVerildiMi = true;
    });

    // KANIT: Her soru için seçilen cevabı ekle (Backend doğrulaması için)
    _userAnswersProof.add({
      'soruId': _sorular[_currentIndex]['id'], // Eğer varsa ID'yi ekle
      'soru': _sorular[_currentIndex]['soru'],
      'secenek': secenek['metin'],
    });

    if (secenek['dogru'] == true) {
      _dogruCevapSayisi++;
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) _sonraki();
      });
    } else {
      if (_currentUser != null) {
        _analyticsService.hataKaydet(_currentUser!.uid);
        _aiAnalysisService.logMistake(_currentUser!.uid, "Senaryo Hatası: ${_sorular[_currentIndex]['soru']} (Seçtiği cevap: ${secenek['metin']})");
      }
      _showFeedback(secenek['feedback'] ?? "Harika bir denemeydi ama bu doğru yol değil...");
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
    if (_sorular.isEmpty) {
      return Scaffold(
        appBar: AppBar(elevation: 0, backgroundColor: Colors.transparent, leading: const CloseButton(color: Colors.grey)),
        body: const Center(child: Text("Henüz görev hazır değil.", style: TextStyle(fontWeight: FontWeight.bold))),
      );
    }

    final size = MediaQuery.of(context).size;
    final soru = _sorular[_currentIndex];
    double val = (_cevapVerildiMi && _currentIndex == _sorular.length - 1) ? 1.0 : (_currentIndex / _sorular.length);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FBFF),
      appBar: _buildAppBar(),
      body: Stack(
        children: [
          Column(
            children: [
              _buildModernProgressBar(val, size),
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.symmetric(horizontal: size.width * 0.05),
                  child: Column(
                    children: [
                      const SizedBox(height: 10),
                      if (soru['imageUrl'] != null && soru['imageUrl'].isNotEmpty) _buildHeroImage(soru['imageUrl'], size),
                      const SizedBox(height: 20),
                      _buildQuestionCard(soru['soru'], size),
                      const SizedBox(height: 25),
                      ...List.generate(soru['secenekler'].length, (i) => _buildAnimatedOption(i, soru['secenekler'][i], size)),
                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              ),
            ],
          ),
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(confettiController: _confettiController, blastDirectionality: BlastDirectionality.explosive),
          ),
          ValueListenableBuilder<bool>(
              valueListenable: _ttsService.isSpeaking,
              builder: (context, isSpeaking, _) {
                if (!isSpeaking) return const SizedBox.shrink();
                return Positioned(
                  bottom: 100, right: 20,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: const BoxDecoration(color: AppColors.anaMavi, shape: BoxShape.circle),
                    child: const Icon(Icons.record_voice_over_rounded, color: Colors.white, size: 24),
                  ).animate(onPlay: (c) => c.repeat()).shimmer(),
                );
              }
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(icon: const Icon(Icons.close_rounded, color: Colors.grey), onPressed: () => Navigator.pop(context)),
      title: Text("BÖLÜM ${widget.bolumIndex + 1}", style: const TextStyle(color: AppColors.yaziRengi, fontWeight: FontWeight.bold)),
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
    int currentNum = (_cevapVerildiMi && _currentIndex == _sorular.length - 1) ? _sorular.length : _currentIndex + 1;
    return Container(
      padding: EdgeInsets.all(size.width * 0.05),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("İlerlemen", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey)),
              Text("$currentNum / ${_sorular.length}", style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.anaMavi)),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: LinearProgressIndicator(
                value: val <= 0 ? 0.05 : val,
                minHeight: 12,
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
      height: size.height * 0.25,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white, width: 5),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15)],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(25),
        child: CachedNetworkImage(
          imageUrl: url,
          fit: BoxFit.cover,
          memCacheWidth: 800,
          maxWidthDiskCache: 1200,
          fadeInDuration: const Duration(milliseconds: 250),
          placeholder: (context, url) => Container(
            color: Colors.grey[200],
          ).animate(onPlay: (c) => c.repeat()).shimmer(duration: 200.ms),
          errorWidget: (context, url, error) => const Icon(Icons.broken_image, color: Colors.grey),
        ),
      ),
    );
  }

  Widget _buildQuestionCard(String text, Size size) {
    return Container(
      width: double.infinity, padding: EdgeInsets.all(size.width * 0.05),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(25)),
      child: Text(text, textAlign: TextAlign.center, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.yaziRengi)),
    );
  }

  Widget _buildAnimatedOption(int index, Map secenek, Size size) {
    bool isSelected = _secilenIndeks == index;
    bool isCorrect = secenek['dogru'] == true;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: () => _cevapKontrol(index, secenek),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: EdgeInsets.all(size.width * 0.04),
          decoration: BoxDecoration(
            color: isSelected ? (isCorrect ? const Color(0xFFE8F5E9) : const Color(0xFFFFEBEE)) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: isSelected ? (isCorrect ? Colors.green : Colors.redAccent) : Colors.grey.withOpacity(0.1), width: 2),
          ),
          child: Row(
            children: [
              CircleAvatar(
                  radius: 16,
                  backgroundColor: isSelected ? (isCorrect ? Colors.green : Colors.redAccent) : AppColors.anaMavi.withOpacity(0.1),
                  child: Text(String.fromCharCode(65 + index), style: TextStyle(color: isSelected ? Colors.white : AppColors.anaMavi, fontWeight: FontWeight.bold))
              ),
              const SizedBox(width: 15),
              Expanded(child: Text(secenek['metin'], style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.yaziRengi))),
              if (isSelected) Icon(isCorrect ? Icons.check_circle_rounded : Icons.cancel_rounded, color: isCorrect ? Colors.green : Colors.redAccent),
            ],
          ),
        ),
      ),
    );
  }

  void _showFeedback(String mesaj) {
    if (_sesAcik) _ttsService.speak(mesaj);
    showModalBottomSheet(
      context: context, isDismissible: false, enableDrag: false, backgroundColor: Colors.transparent,
      builder: (c) => Container(
        padding: const EdgeInsets.all(30),
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(40))),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.lightbulb_circle_rounded, color: Colors.orangeAccent, size: 70),
            const SizedBox(height: 15),
            Text(mesaj, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16, color: Colors.blueGrey)),
            const SizedBox(height: 30),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.anaMavi, minimumSize: const Size(double.infinity, 60), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
              onPressed: () { Navigator.pop(c); _sonraki(); },
              child: const Text("ANLADIM, DEVAM ET!", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
        await _bolumuTamamlaVeSenkronizeEt();
      } catch (e) {
        debugPrint("Senaryo senkronizasyon hatası: $e");
      }
    }

    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (c) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: basarili
                  ? [Colors.green.shade400, Colors.green.shade700]
                  : [Colors.blue.shade400, Colors.blue.shade700],
            ),
            borderRadius: BorderRadius.circular(30),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 40,
                backgroundColor: Colors.white,
                child: Icon(
                  basarili ? Icons.emoji_events : Icons.refresh,
                  size: 45,
                  color: basarili ? Colors.orange : Colors.blue,
                ),
              ),
              const SizedBox(height: 15),
              Text(
                basarili ? "LEVEL TAMAMLANDI!" : "HADİ BİR DAHA!",
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                basarili ? "Harika gidiyorsun! 🚀" : "Denemeye devam et, başaracaksın! 💪",
                style: const TextStyle(color: Colors.white70),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
                child: Column(
                  children: [
                    _statItem("Doğru", _dogruCevapSayisi, Colors.green),
                    _statItem("Yanlış", _sorular.length - _dogruCevapSayisi, Colors.red),
                    _statItem("Puan", oran.toStringAsFixed(0), Colors.orange),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                ),
                onPressed: () {
                  Navigator.pop(c);
                  Navigator.pop(context);
                },
                child: Text(
                  basarili ? "DEVAM ET 🚀" : "TEKRAR DENE 🔁",
                  style: TextStyle(color: basarili ? Colors.green : Colors.blue, fontWeight: FontWeight.bold),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _statItem(String title, dynamic value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
            child: Text("$value", style: TextStyle(color: color, fontWeight: FontWeight.bold)),
          )
        ],
      ),
    );
  }

  Future<void> _bolumuTamamlaVeSenkronizeEt() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      debugPrint("Hata: Oturum kapalı!");
      return;
    }
    
    final String uid = user.uid;
    final String buBolumId = "${widget.docId}_${widget.bolumIndex}";

    try {
      // Kanıt listesini de (proof) gönderiyoruz
      await _analyticsService.bolumTamamla(uid, 0, buBolumId, proof: List.from(_userAnswersProof));
      debugPrint("Senkronizasyon başarılı: $buBolumId");
    } catch (e) {
      debugPrint("Senkronizasyon hatası: $e");
      if (mounted) {
        String mesaage = "İlerlemen sunucuya kaydedilemedi! 🌐";
        if (e.toString().contains("unauthenticated")) {
          mesaage = "Oturum doğrulanamadı, lütfen tekrar dene. 🔐";
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(mesaage),
            backgroundColor: Colors.redAccent,
            action: SnackBarAction(
              label: "TEKRAR",
              textColor: Colors.white,
              onPressed: _bolumuTamamlaVeSenkronizeEt,
            ),
          ),
        );
      }
      rethrow;
    }
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _ttsService.stop();
    super.dispose();
  }
}
