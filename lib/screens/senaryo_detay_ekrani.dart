import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:confetti/confetti.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:zorbalik_uygulamasi/app_theme.dart';
import 'package:zorbalik_uygulamasi/services/analytics_service.dart';
import 'package:zorbalik_uygulamasi/services/tts_service.dart';
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
  late ConfettiController _confettiController;
  final User? _currentUser = FirebaseAuth.instance.currentUser;

  List _sorular = [];
  int _currentIndex = 0;
  bool _cevapVerildiMi = false;
  int? _secilenIndeks;
  bool _isLoading = true;
  bool _sesAcik = false;
  int _dogruCevapSayisi = 0;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 2));
    _verileriYukle();
  }

  Future<void> _soruyuVeSecenekleriSeslendir(Map soruData) async {
    if (!_sesAcik || !mounted) return;

    await _ttsService.speak(soruData['soru'] ?? "");
    await Future.delayed(const Duration(milliseconds: 1000));

    List secenekler = soruData['secenekler'] ?? [];
    for (int i = 0; i < secenekler.length; i++) {
      if (!_sesAcik || _cevapVerildiMi || !mounted) break;
      String harf = String.fromCharCode(65 + i);
      String secenekMetni = "$harf şıkkı. ${secenekler[i]['metin']}";
      await _ttsService.speak(secenekMetni);
      await Future.delayed(const Duration(milliseconds: 700));
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

    if (secenek['dogru'] == true) {
      _dogruCevapSayisi++;
      _confettiController.play();
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (mounted) _sonraki();
      });
    } else {
      if (_currentUser != null) _analyticsService.hataKaydet(_currentUser!.uid);
      _showFeedback(secenek['feedback'] ?? "Harika bir denemeydi ama bu doğru yol değil...");
    }
  }

  void _sonraki() {
    _ttsService.stop();
    if (_currentIndex < _sorular.length - 1) {
      setState(() {
        _currentIndex++;
        _cevapVerildiMi = false;
        _secilenIndeks = null;
      });
      if (_sesAcik) _soruyuVeSecenekleriSeslendir(_sorular[_currentIndex]);
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
      height: size.height * 0.25, width: double.infinity,
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(30), border: Border.all(color: Colors.white, width: 5)),
      child: ClipRRect(borderRadius: BorderRadius.circular(25), child: CachedNetworkImage(imageUrl: url, fit: BoxFit.cover, placeholder: (context, url) => const Center(child: CircularProgressIndicator()))),
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
    if (basarili) await _bolumuTamamlaVeSenkronizeEt();
    if (!mounted) return;
    showDialog(context: context, barrierDismissible: false, builder: (c) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(35)),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        Text(basarili ? "MÜKEMMEL! 🏆" : "TEKRAR DENE! 💪", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 24)),
        const SizedBox(height: 30),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: basarili ? Colors.green : AppColors.anaMavi, minimumSize: const Size(double.infinity, 55), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
          onPressed: () { Navigator.pop(c); Navigator.pop(context); },
          child: Text(basarili ? "BİTİR" : "TEKRAR DENE", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        )
      ]),
    ));
  }

  Future<void> _bolumuTamamlaVeSenkronizeEt() async {
    if (_currentUser == null) return;
    final String uid = _currentUser!.uid;
    final String buBolumId = "${widget.docId}_${widget.bolumIndex}";

    try {
      final progressRef = FirebaseFirestore.instance.collection('usersProgress').doc(uid);
      final userSnap = await progressRef.get();

      if (userSnap.exists) {
        List bitti = List.from(userSnap.data()?['tamamlanan_bolumler'] ?? []);
        if (!bitti.contains(buBolumId)) {
          // Eğer bölüm ilk kez tamamlanıyorsa puan ver ve listeye ekle
          await _analyticsService.bolumTamamla(uid, 100, buBolumId);
        }
      } else {
        // Eğer kullanıcı progress dökümanı yoksa (yeni kayıt gibi)
        await _analyticsService.bolumTamamla(uid, 100, buBolumId);
      }
    } catch (e) {
      debugPrint("Senkronizasyon hatası: $e");
    }
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _ttsService.stop();
    super.dispose();
  }
}
