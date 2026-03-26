import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:confetti/confetti.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:zorbalik_uygulamasi/app_theme.dart';
import 'package:zorbalik_uygulamasi/services/analytics_service.dart';


class SenaryoDetayEkrani extends StatefulWidget {
  final String docId;
  final int bolumIndex;

  const SenaryoDetayEkrani({super.key, required this.docId, required this.bolumIndex});

  @override
  State<SenaryoDetayEkrani> createState() => _SenaryoDetayEkraniState();
}

class _SenaryoDetayEkraniState extends State<SenaryoDetayEkrani> with TickerProviderStateMixin {
  final FlutterTts _flutterTts = FlutterTts();
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
    _initTts();
    _verileriYukle();
  }

  Future<void> _initTts() async {
    try {
      await _flutterTts.setLanguage("tr-TR");
      await _flutterTts.setPitch(1.1);
      await _flutterTts.setSpeechRate(0.5);
      await _flutterTts.awaitSpeakCompletion(true);
    } catch (e) {
      debugPrint("TTS Hatası: $e");
    }
  }

  Future<void> _verileriYukle() async {
    try {
      final doc = await FirebaseFirestore.instance.collection('scenarios').doc(widget.docId).get();
      if (doc.exists && mounted) {
        final data = doc.data();
        final bolumler = data?['bolumler'] as List? ?? [];

        if (bolumler.isNotEmpty && widget.bolumIndex < bolumler.length) {
          setState(() {
            _sorular = List.from(bolumler[widget.bolumIndex]['sorular'] ?? []);
            for (var soru in _sorular) {
              if (soru['secenekler'] != null) {
                List seceneklerListesi = List.from(soru['secenekler']);
                seceneklerListesi.shuffle();
                soru['secenekler'] = seceneklerListesi;
              }
            }
            _isLoading = false;
          });
          if (_sesAcik) _soruyuOku(_sorular[_currentIndex]['soru']);
        }
      }
    } catch (e) {
      debugPrint("Veri yükleme hatası: $e");
    }
  }

  Future<void> _soruyuOku(String metin) async {
    if (_sesAcik && metin.isNotEmpty) {
      await _flutterTts.stop();
      await _flutterTts.speak(metin);
    }
  }

  void _cevapKontrol(int index, Map secenek) {
    if (_cevapVerildiMi) return;
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
      if (_currentUser != null) {
        AnalyticsService().hataKaydet(_currentUser!.uid);
      }
      _showFeedback(secenek['feedback'] ?? "Harika bir denemeydi ama bu doğru yol değil...");
    }
  }

  void _sonraki() {
    _flutterTts.stop();
    if (_currentIndex < _sorular.length - 1) {
      setState(() {
        _currentIndex++;
        _cevapVerildiMi = false;
        _secilenIndeks = null;
      });
      if (_sesAcik) _soruyuOku(_sorular[_currentIndex]['soru']);
    } else {
      _sonucGoster();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    final size = MediaQuery.of(context).size;
    final soru = _sorular[_currentIndex];

    double val = (_cevapVerildiMi && _currentIndex == _sorular.length - 1)
        ? 1.0
        : (_currentIndex / _sorular.length);

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
                      if (soru['imageUrl'] != null) _buildHeroImage(soru['imageUrl'], size),
                      const SizedBox(height: 20),
                      _buildQuestionCard(soru['soru'], size),
                      const SizedBox(height: 25),
                      ...List.generate(soru['secenekler'].length,
                              (i) => _buildAnimatedOption(i, soru['secenekler'][i], size)),
                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              ),
            ],
          ),
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              colors: const [Colors.blue, Colors.green, Colors.orange, Colors.pink],
            ),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      leading: IconButton(
        icon: const Icon(Icons.close_rounded, color: Colors.grey, size: 28),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text("BÖLÜM ${widget.bolumIndex + 1}",
          style: const TextStyle(color: AppColors.yaziRengi, fontWeight: FontWeight.bold, fontSize: 18)),
      actions: [
        IconButton(
          icon: Icon(_sesAcik ? Icons.volume_up_rounded : Icons.volume_off_rounded,
              color: _sesAcik ? AppColors.anaMavi : Colors.grey),
          onPressed: () {
            setState(() {
              _sesAcik = !_sesAcik;
              if (_sesAcik) {
                _soruyuOku(_sorular[_currentIndex]['soru']);
              } else {
                _flutterTts.stop();
              }
            });
          },
        ),
        const SizedBox(width: 10),
      ],
    );
  }

  Widget _buildModernProgressBar(double val, Size size) {
    int currentNum = (_cevapVerildiMi && _currentIndex == _sorular.length - 1)
        ? _sorular.length
        : _currentIndex + 1;

    return Container(
      padding: EdgeInsets.all(size.width * 0.05),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("İlerlemen", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(color: AppColors.anaMavi.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                child: Text("$currentNum / ${_sorular.length}",
                    style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.anaMavi)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: LinearProgressIndicator(
              value: val == 0 ? 0.05 : val,
              minHeight: 12,
              backgroundColor: Colors.white,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.anaMavi),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroImage(String url, Size size) {
    return Container(
      height: size.height * 0.25, width: double.infinity,
      constraints: const BoxConstraints(maxHeight: 250),
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          boxShadow: [BoxShadow(color: Colors.blue.withOpacity(0.1), blurRadius: 20, spreadRadius: 2)],
          border: Border.all(color: Colors.white, width: 5)
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(25),
        child: CachedNetworkImage(
          imageUrl: url, fit: BoxFit.cover,
          placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
          errorWidget: (context, url, error) => const Icon(Icons.broken_image),
        ),
      ),
    );
  }

  Widget _buildQuestionCard(String text, Size size) {
    return Container(
      width: double.infinity, padding: EdgeInsets.all(size.width * 0.05),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(25), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)]),
      child: Text(text, textAlign: TextAlign.center, style: TextStyle(fontSize: size.width > 600 ? 20 : 17, fontWeight: FontWeight.w800, color: AppColors.yaziRengi, height: 1.4)),
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
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 5)],
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: isSelected ? (isCorrect ? Colors.green : Colors.redAccent) : AppColors.anaMavi.withOpacity(0.1),
                child: Text(String.fromCharCode(65 + index), style: TextStyle(color: isSelected ? Colors.white : AppColors.anaMavi, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Text(secenek['metin'],
                    style: TextStyle(fontSize: size.width > 600 ? 18 : 15, fontWeight: FontWeight.w700, color: isSelected ? (isCorrect ? Colors.green[800] : Colors.red[800]) : AppColors.yaziRengi)),
              ),
              if (isSelected) Icon(isCorrect ? Icons.check_circle_rounded : Icons.cancel_rounded, color: isCorrect ? Colors.green : Colors.redAccent),
            ],
          ),
        ),
      ),
    );
  }

  void _showFeedback(String mesaj) {
    if (_sesAcik) _flutterTts.speak(mesaj);
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
            const Text("KÜÇÜK BİR İPUCU", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22, color: AppColors.yaziRengi)),
            const SizedBox(height: 10),
            Text(mesaj, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16, color: Colors.blueGrey)),
            const SizedBox(height: 30),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.anaMavi, minimumSize: const Size(double.infinity, 60), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)), elevation: 5),
              onPressed: () { Navigator.pop(c); _sonraki(); },
              child: const Text("ANLADIM, DEVAM ET!", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
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
      await _bolumuTamamlaVeRozetKontrol();
    }

    if (!mounted) return;
    showDialog(
      context: context, barrierDismissible: false,
      builder: (c) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(35)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            Text(basarili ? "MÜKEMMEL! 🏆" : "TEKRAR DENE! 💪", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 24)),
            const SizedBox(height: 20),
            _buildResultStat("Başarı Oranın", "%${oran.toInt()}"),
            const SizedBox(height: 30),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: basarili ? Colors.green : AppColors.anaMavi,
                  minimumSize: const Size(double.infinity, 55),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))
              ),
              onPressed: () {
                Navigator.pop(c);
                Navigator.pop(context);
              },
              child: Text(basarili ? "BİTİR" : "TEKRAR DENE", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            )
          ],
        ),
      ),
    );
  }

  Future<void> _bolumuTamamlaVeRozetKontrol() async {
    if (_currentUser == null) return;
    final String uid = _currentUser!.uid;
    final progressRef = FirebaseFirestore.instance.collection('usersProgress').doc(uid);

    try {
      debugPrint("DEBUG: Rozet kontrolü tetiklendi.");

      // 1. Kullanıcı Verisini Çek
      final userSnap = await progressRef.get();
      Map<String, dynamic> userData = userSnap.exists ? (userSnap.data() as Map<String, dynamic>) : {};

      int mevcutPuan = userData['toplam_puan'] ?? 0;
      List bitti = List.from(userData['tamamlanan_bolumler'] ?? []);
      List mevcutRozetler = List.from(userData['rozetler'] ?? []);
      String buBolumId = "${widget.docId}_${widget.bolumIndex}";

      // 2. İlerlemeyi Kaydet (Eğer yeni bitiyorsa)
      if (!bitti.contains(buBolumId)) {
        mevcutPuan += 100;
        bitti.add(buBolumId);

        await progressRef.set({
          'uid': uid,
          'tamamlanan_bolumler': bitti,
          'toplam_puan': mevcutPuan,
          'sonGuncelleme': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        debugPrint("DEBUG: Puan başarıyla güncellendi: $mevcutPuan");
      }

      // 3. Rozetleri Çek (Timeout ekleyerek takılmayı önle)
      debugPrint("DEBUG: Badges koleksiyonu çekiliyor...");
      final badgesSnap = await FirebaseFirestore.instance
          .collection('badges')
          .get()
          .timeout(const Duration(seconds: 10));

      List<String> yeniKazanilanlar = [];
      int benzersizSenaryoSayisi = bitti.map((id) => id.toString().split('_').first).toSet().length;

      for (var doc in badgesSnap.docs) {
        if (mevcutRozetler.contains(doc.id)) continue;

        final bData = doc.data();
        final String tip = bData['kriter_tipi']?.toString() ?? "";
        final dynamic rawHedef = bData['hedef_deger'];

        int hedef = 9999;
        if (rawHedef is num) hedef = rawHedef.toInt();
        else if (rawHedef is String) hedef = int.tryParse(rawHedef) ?? 9999;

        bool kazandiMi = false;
        if (tip == "puan" && mevcutPuan >= hedef) kazandiMi = true;
        else if (tip == "senaryo_sayisi" && (bitti.length >= hedef || benzersizSenaryoSayisi >= hedef)) kazandiMi = true;

        if (kazandiMi) {
          debugPrint("DEBUG: ROZET ŞARTLARI TUTTU -> ${doc.id}");
          yeniKazanilanlar.add(doc.id);
        }
      }

      // 4. Rozetleri Kaydet
      if (yeniKazanilanlar.isNotEmpty) {
        await progressRef.update({
          'rozetler': FieldValue.arrayUnion(yeniKazanilanlar)
        });
        debugPrint("DEBUG: Yeni rozetler yazıldı.");
        if (mounted) _yeniRozetBildirimi(yeniKazanilanlar.length);
      } else {
        debugPrint("DEBUG: Şartlar sağlanmadığı için rozet eklenmedi.");
      }

    } catch (e) {
      debugPrint("DEBUG: HATA OLUŞTU -> $e");
    }
  }

  Widget _buildResultStat(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [Text(label, style: const TextStyle(fontWeight: FontWeight.w600)), Text(value, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.anaMavi, fontSize: 18))],
      ),
    );
  }

  void _yeniRozetBildirimi(int adet) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text("TEBRİKLER! $adet YENİ ROZET KAZANDIN! 🏆"),
      backgroundColor: Colors.orangeAccent,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      duration: const Duration(seconds: 4),
    ));
  }

  @override
  void dispose() { 
    _confettiController.dispose(); 
    _flutterTts.stop(); 
    super.dispose(); 
  }
}
