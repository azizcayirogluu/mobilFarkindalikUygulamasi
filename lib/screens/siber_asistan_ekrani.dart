import 'package:zorbalik_uygulamasi/injection_container.dart';
import 'package:zorbalik_uygulamasi/services/storage_service.dart';
import 'package:zorbalik_uygulamasi/services/ad_manager.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:zorbalik_uygulamasi/services/tts_service.dart';
import 'package:zorbalik_uygulamasi/services/ai_analysis_service.dart';
import 'package:zorbalik_uygulamasi/screens/siber_imdat_ekrani.dart';
import 'package:flutter_animate/flutter_animate.dart';

class SiberAsistanEkrani extends StatefulWidget {
  const SiberAsistanEkrani({super.key});

  @override
  State<SiberAsistanEkrani> createState() => _SiberAsistanEkraniState();
}

class _SiberAsistanEkraniState extends State<SiberAsistanEkrani> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final AdManager _adManager = AdManager();
  bool _isAdReady = false;

  // MERKEZİ SİSTEMDEN ÇEKİLEN SERVİSLER
  final TtsService _ttsService = sl<TtsService>();
  final AiAnalysisService _aiAnalysisService = sl<AiAnalysisService>();
  final User? _currentUser = sl<FirebaseAuth>().currentUser;

  List<Map<String, String>> _mesajlar = [];
  bool _yukleniyor = false;
  bool _sesAcik = true;

  int _anlikPuan = 0;
  int _anlikRozet = 0;
  int _gorevSayisi = 0;
  String _kullaniciAdi = "Kahraman";
  String _yasGrubu = "6-12";
  List<String> _sonHatalar = [];
  bool _isExempt = false; // Limitlerden muaf mı? (Admin/Premium)

  Color _seciliRenk = const Color(0xFF009688);

  // Cloud Functions referansı (API anahtarları sunucuda)
  final HttpsCallable _geminiChatFn = FirebaseFunctions.instanceFor(
    region: 'europe-west1',
  ).httpsCallable('geminiChat');

  @override
  void initState() {
    super.initState();
    _verileriYukle();
    _reklamYukle();
  }

  void _reklamYukle() {
    _adManager.loadRewardedAd(onAdLoaded: () => setState(() => _isAdReady = true));
  }

  void _enerjiBittiUyarisi() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        title: const Text("Enerjin Azaldı! ⚡", style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text("Kahraman Dostum ile daha fazla konuşmak için kısa bir video izleyip +5 enerji kazanmak ister misin? ✨"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Sonra")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: _seciliRenk, foregroundColor: Colors.white),
            onPressed: () {
              Navigator.pop(context);
              _adManager.showRewardedAd(
                onUserEarnedReward: () async {
                  await StorageService().addRewardedMessages(5);
                  setState(() {});
                  _showSnack("Harika! +5 Mesaj kazandın. 🎉");
                },
                onAdClosed: () => _reklamYukle(),
              );
            },
            child: const Text("İzle ve Kazan! 🎬"),
          ),
        ],
      ),
    );
  }

  void _showSnack(String m) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m), backgroundColor: _seciliRenk));
  }

  Future<void> _verileriYukle() async {
    if (_currentUser == null) return;
    try {
      final String uid = _currentUser!.uid;

      final results = await Future.wait([
        FirebaseFirestore.instance.collection('usersProgress').doc(uid).get(),
        FirebaseFirestore.instance.collection('users').doc(uid).get(),
        _aiAnalysisService.getMistakes(uid),
      ]);

      if (!mounted) return;

      final progressDoc = results[0] as DocumentSnapshot;
      final userDoc = results[1] as DocumentSnapshot;
      _sonHatalar = results[2] as List<String>;

      if (_sonHatalar.isNotEmpty) {
        _aiAnalysisService.clearMistakes(
          uid,
        ); // Hataları asistan öğrendikten sonra temizle
      }

      if (progressDoc.exists) {
        var pData = progressDoc.data() as Map<String, dynamic>;
        setState(() {
          _anlikPuan = pData['toplam_puan'] ?? 0;
          _anlikRozet = (pData['rozetler'] as List? ?? []).length;
          _gorevSayisi = (pData['tamamlanan_bolumler'] as List? ?? []).length;
          _kullaniciAdi = _currentUser!.displayName ?? "Kahraman";

          if (pData.containsKey('sohbet_gecmisi')) {
            _mesajlar = List<Map<String, String>>.from(
              (pData['sohbet_gecmisi'] as List).map(
                (item) => Map<String, String>.from(item),
              ),
            );
          }
        });
      }

      if (userDoc.exists) {
        var uData = userDoc.data() as Map<String, dynamic>;
        setState(() {
          _yasGrubu = uData['yasGrubu'] ?? "6-12";
          // Admin veya Premium olanlar limitlerden muaftır
          _isExempt = uData['isAdmin'] == true || uData['isPremium'] == true;
        });
      }

      if (_mesajlar.isEmpty)
        _ilkMesaj();
      else
        _scrollToBottom();
    } catch (e) {
      debugPrint("Veri yükleme hatası: $e");
      _hataMesajiGoster(e.toString());
      _ilkMesaj();
    }
  }

  String _sanitizeForAi(String metin) {
    return metin
        .replaceAll(RegExp(r'[\r\n]+'), ' ')
        .replaceAll(
          RegExp(
            r'<[^>]*>|[`*_~>]|system:|assistant:|user:',
            caseSensitive: false,
          ),
          '',
        )
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  List<Map<String, String>> _recentMessagesForAi() {
    final List<Map<String, String>> recent = _mesajlar.length > 12
        ? _mesajlar.sublist(_mesajlar.length - 12)
        : List<Map<String, String>>.from(_mesajlar);
    return recent
        .map(
          (m) => {
            'rol': m['rol'] ?? '',
            'metin': _sanitizeForAi(m['metin'] ?? ''),
          },
        )
        .where((m) => m['metin']?.isNotEmpty == true)
        .toList();
  }

  String _sanitizeBotResponse(String metin) {
    final filtered = _sanitizeForAi(metin);
    final yasakli = [
      'intihar',
      'kendine zarar',
      'öldür',
      'silah',
      'uyuşturucu',
      'pornografi',
      'cinsel',
      'tecavüz',
      'fuhuş',
      'şiddet',
      'savaş',
    ];
    final lower = filtered.toLowerCase();
    if (yasakli.any((item) => lower.contains(item))) {
      return "Bu konuda size yardımcı olamam, ama bir yetişkine danışmandan yardım isteyebilirsin. 💙";
    }
    return filtered;
  }

  String _emojileriTemizle(String metin) {
    // Tüm emoji aralıklarını kapsayan düzeltilmiş Regex
    final regex = RegExp(
      r'[\u{1F600}-\u{1F64F}\u{1F300}-\u{1F5FF}\u{1F680}-\u{1F6FF}\u{1F700}-\u{1F77F}\u{1F780}-\u{1F7FF}\u{1F800}-\u{1F8FF}\u{1F900}-\u{1F9FF}\u{1FA00}-\u{1FA6F}\u{1FA70}-\u{1FAFF}\u{2600}-\u{26FF}\u{2700}-\u{27BF}]+',
      unicode: true,
    );
    // Emojileri temizle ve oluşan çift boşlukları tek boşluğa indir
    return metin.replaceAll(regex, '').replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  Future<void> _mesajKaydet(Map<String, String> mesaj) async {
    if (_currentUser == null) return;
    try {
      final docRef = FirebaseFirestore.instance
          .collection('usersProgress')
          .doc(_currentUser!.uid);

      // Sohbet geçmişini son 20 mesajla sınırla (daha az veri, daha az maliyet)
      const int maxMesaj = 20;

      // update yerine set + merge kullanarak 'permission-denied' ve 'missing document' hatalarını önlüyoruz.
      if (_mesajlar.length > maxMesaj) {
        await docRef.set({
          'sohbet_gecmisi': _mesajlar.sublist(_mesajlar.length - maxMesaj),
          'son_mesaj_tarihi': FieldValue.serverTimestamp(),
          'uid': _currentUser!.uid,
        }, SetOptions(merge: true));
      } else {
        await docRef.set({
          'sohbet_gecmisi': FieldValue.arrayUnion([mesaj]),
          'son_mesaj_tarihi': FieldValue.serverTimestamp(),
          'uid': _currentUser!.uid,
        }, SetOptions(merge: true));
      }
    } catch (e) {
      debugPrint("Kayıt hatası: $e");
    }
  }

  Future<void> _mesajGonder(String metin) async {
    if (metin.trim().isEmpty || _yukleniyor) return;

    // LİMİT KONTROLÜ (Sadece muaf olmayan normal kullanıcılar için)
    if (!_isExempt) {
      if (StorageService().getRemainingMessages() <= 0) {
        _enerjiBittiUyarisi();
        return;
      }
      // Hakkı kullan
      await StorageService().useMessage();
    }

    final Map<String, String> kullaniciMesaji = {
      "rol": "kullanici",
      "metin": metin,
    };

    setState(() {
      _mesajlar.add(kullaniciMesaji);
      _yukleniyor = true;
    });

    _controller.clear();
    _scrollToBottom();
    _mesajKaydet(kullaniciMesaji);

    try {
      // Fonksiyonu tam çağrıldığı anda, europe-west1 bölgesi ile oluşturalım
      final HttpsCallable callable = FirebaseFunctions.instanceFor(
        region: 'europe-west1',
      ).httpsCallable('geminiChat');

      final result = await callable.call({
        'mesaj': _sanitizeForAi(metin),
        'gecmis': _recentMessagesForAi(),
        'kullaniciBilgileri': {
          'kullaniciAdi': _sanitizeForAi(_kullaniciAdi),
          'yasGrubu': _sanitizeForAi(_yasGrubu),
          'puan': _anlikPuan,
          'gorevSayisi': _gorevSayisi,
          'rozetSayisi': _anlikRozet,
          'sonHatalar': _sonHatalar,
        },
      });

      if (!mounted) return;

      final data = result.data as Map?;
      String botCevabi = data?['cevap'] ?? '';
      botCevabi = _sanitizeBotResponse(botCevabi);

      // TEHLİKE TESPİTİ (Gelişmiş Regex: [TEHLIKE_TESPIT], [TEHLİKETESPİT] vb. hepsini yakalar)
      final dangerRegex = RegExp(r'\[TEHL[Iİ]KE_?TESP[Iİ]T\]', caseSensitive: false);
      bool tehlikeVarMi = dangerRegex.hasMatch(botCevabi);

      if (tehlikeVarMi) {
        // Etiketi kullanıcı görmeden tertemiz siliyoruz
        botCevabi = botCevabi.replaceAll(dangerRegex, "").trim();
      }

      if (botCevabi.isEmpty) {
        botCevabi = "Sana yardımcı olamıyorum, ama bir yetişkine veya öğretmene danışabilirsin. 💙";
      }

      final Map<String, String> botMesaji = {"rol": "bot", "metin": botCevabi};

      setState(() {
        _mesajlar.add(botMesaji);
        _yukleniyor = false;
      });

      _mesajKaydet(botMesaji);
      if (_sesAcik) _ttsService.speak(_emojileriTemizle(botCevabi));

      if (tehlikeVarMi) {
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SiberImdatEkrani()),
            );
          }
        });
      }
    } on FirebaseFunctionsException catch (e) {
      debugPrint("Cloud Function Hatası: ${e.code} - ${e.message}");
      setState(() => _yukleniyor = false);
      _hataMesajiGoster(e.message ?? "Bir hata oluştu.");
    } catch (e) {
      debugPrint("Siber Asistan Hatası: $e");
      setState(() => _yukleniyor = false);
      _hataMesajiGoster("Bağlantı hatası. İnternetini kontrol et.");
    }
    _scrollToBottom();
  }

  void _hataMesajiGoster(String error) {
    String mesaj =
        "Kahraman Dostum'un devreleri biraz ısındı, kısa bir mola verelim mi? 🤖";
    if (error.contains("429")) {
      mesaj =
          "Kahraman Dostum şu an çok meşgul, 1 dakika sonra tekrar dener misin? ☕";
    } else if (error.contains("400") || error.contains("invalid")) {
      mesaj = "Bir şeyler karıştı, lütfen sohbeti temizleyip tekrar dene. 🛠️";
    } else if (error.contains("not found") || error.contains("404")) {
      mesaj =
          "Kahraman Dostum'a şu an ulaşılamıyor, API anahtarını kontrol edelim. 🔑";
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          mesaj,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.orangeAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 300), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildStatsHeader(),
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 10,
              ),
              itemCount: _mesajlar.length,
              itemBuilder: (context, index) =>
                  _buildGameBubble(_mesajlar[index]),
            ),
          ),
          if (_yukleniyor) _buildTypingIndicator(),
          _buildQuickActions(),
          _buildModernInput(),
        ],
      ),
    );
  }

  Widget _buildVolumeIndicator() {
    return ValueListenableBuilder<bool>(
      valueListenable: _ttsService.isSpeaking,
      builder: (context, isSpeaking, _) {
        if (!isSpeaking) return const SizedBox.shrink();
        return Positioned(
          top: 100,
          right: 20,
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _seciliRenk,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.volume_up_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
        );
      },
    );
  }

  Widget _buildStaticBackground() {
    return Positioned.fill(
      child: Opacity(
        opacity: 0.05,
        child: CustomPaint(
          painter: StaticBackgroundPainter(color: _seciliRenk),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(25)),
      ),
      title: Row(
        children: [
          CircleAvatar(
            backgroundColor: _seciliRenk.withOpacity(0.1),
            child: Icon(Icons.smart_toy_rounded, color: _seciliRenk),
          ),
          const SizedBox(width: 10),
          Text(
            "Kahraman Dostum",
            style: TextStyle(
              color: Colors.blueGrey.shade900,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: Icon(
            _sesAcik ? Icons.volume_up : Icons.volume_off,
            color: _seciliRenk,
          ),
          onPressed: () {
            setState(() => _sesAcik = !_sesAcik);
            if (!_sesAcik) _ttsService.stop();
          },
        ),
        IconButton(
          icon: const Icon(Icons.refresh, color: Colors.redAccent),
          onPressed: _sohbetiTemizle,
        ),
      ],
    );
  }

  Widget _buildStatsHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _badgeChip(Icons.stars, "$_anlikPuan TP", Colors.orange),
          const SizedBox(width: 10),
          _badgeChip(
            Icons.emoji_events,
            "$_anlikRozet Rozet",
            Colors.deepPurpleAccent,
          ),
        ],
      ),
    );
  }

  Widget _badgeChip(IconData i, String l, Color c) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(
      color: c,
      borderRadius: BorderRadius.circular(15),
    ),
    child: Row(
      children: [
        Icon(i, color: Colors.white, size: 16),
        const SizedBox(width: 5),
        Text(
          l,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ],
    ),
  );

  Widget _buildGameBubble(Map<String, String> m) {
    bool isMe = m["rol"] == "kullanici";
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Row(
        mainAxisAlignment: isMe
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isMe)
            Padding(
              padding: const EdgeInsets.only(right: 8, top: 5),
              child: CircleAvatar(
                radius: 15,
                backgroundColor: Colors.white,
                child: Icon(Icons.smart_toy, size: 18, color: _seciliRenk),
              ),
            ),
          Container(
            margin: const EdgeInsets.only(bottom: 15),
            padding: const EdgeInsets.all(14),
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.70,
            ),
            decoration: BoxDecoration(
              color: isMe ? _seciliRenk : Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(20),
                topRight: const Radius.circular(20),
                bottomLeft: Radius.circular(isMe ? 20 : 0),
                bottomRight: Radius.circular(isMe ? 0 : 20),
              ),
              border: isMe ? null : Border.all(color: Colors.grey.shade200),
            ),
            child: Text(
              m["metin"]!,
              style: TextStyle(
                color: isMe ? Colors.white : Colors.black87,
                fontWeight: FontWeight.w500,
                fontSize: 15,
                height: 1.3,
              ),
            ),
          ),
          if (isMe)
            Padding(
              padding: const EdgeInsets.only(left: 8, top: 5),
              child: CircleAvatar(
                radius: 15,
                backgroundColor: _seciliRenk.withOpacity(0.2),
                child: Icon(Icons.person, size: 18, color: _seciliRenk),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    List<String> sorular = [
      "Hadi oyun oynayalım! 🎮",
      "Zorbalık nedir? ❔",
      "Siber zorbalık nedir? 💻",
      "Zorbalığa uğradığımda ne yapabilirim? ❓",
      "İnternette nasıl güvende kalırım? 🛡️",
      "Puanım nasıl? 🏆",
    ];
    return SizedBox(
      height: 42,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: sorular.length,
        itemBuilder: (context, i) => Padding(
          padding: const EdgeInsets.only(right: 8),
          child: ActionChip(
            label: Text(
              sorular[i],
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: _seciliRenk,
              ),
            ),
            backgroundColor: Colors.white,
            onPressed: () => _mesajGonder(sorular[i]),
          ),
        ),
      ),
    );
  }

  Widget _buildTypingIndicator() => const Padding(
    padding: EdgeInsets.all(8),
    child: Center(
      child: Text(
        "Kahraman Dostum düşünüyor...",
        style: TextStyle(
          fontSize: 12,
          color: Colors.blueGrey,
          fontStyle: FontStyle.italic,
        ),
      ),
    ),
  );

  Widget _buildModernInput() {
    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        10,
        16,
        MediaQuery.of(context).padding.bottom + 10,
      ),
      color: Colors.white,
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(25),
              ),
              child: TextField(
                controller: _controller,
                decoration: const InputDecoration(
                  hintText: "Kahraman Dostum'a yaz...",
                  border: InputBorder.none,
                ),
                onSubmitted: (val) => _mesajGonder(val),
              ),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: () => _mesajGonder(_controller.text),
            child: CircleAvatar(
              backgroundColor: _seciliRenk,
              child: const Icon(Icons.bolt, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _sohbetiTemizle() async {
    if (_currentUser == null) return;
    try {
      await FirebaseFirestore.instance
          .collection('usersProgress')
          .doc(_currentUser!.uid)
          .update({'sohbet_gecmisi': FieldValue.delete()});
      if (!mounted) return;
      setState(() {
        _mesajlar.clear();
      });
      _ilkMesaj();
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  void _ilkMesaj() {
    String m =
        "Selam $_kullaniciAdi! 🤖 Ben senin Kahraman Dostunum. Her türlü zorbalığa karşı birlikte güçlenmeye hazır mısın? ✨ İstersen seninle eğitici bir oyun oynayabiliriz, 'Hadi oyun oynayalım' demen yeterli! 🎮";
    final Map<String, String> botMesaji = {"rol": "bot", "metin": m};
    setState(() {
      _mesajlar.add(botMesaji);
    });
    if (_sesAcik) _ttsService.speak(_emojileriTemizle(m));
    _mesajKaydet(botMesaji);
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _ttsService.stop();
    super.dispose();
  }
}

class StaticBackgroundPainter extends CustomPainter {
  final Color color;
  StaticBackgroundPainter({required this.color});
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    canvas.drawCircle(Offset(size.width * 0.1, size.height * 0.2), 40, paint);
    canvas.drawCircle(Offset(size.width * 0.9, size.height * 0.5), 60, paint);
    canvas.drawCircle(Offset(size.width * 0.3, size.height * 0.8), 30, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
