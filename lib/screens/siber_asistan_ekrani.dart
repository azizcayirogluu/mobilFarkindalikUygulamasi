import 'package:zorbalik_uygulamasi/injection_container.dart';
import 'package:zorbalik_uygulamasi/services/ad_manager.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:zorbalik_uygulamasi/services/tts_service.dart';
import 'package:zorbalik_uygulamasi/services/ai_analysis_service.dart';
import 'package:zorbalik_uygulamasi/screens/siber_imdat_ekrani.dart';

class SiberAsistanEkrani extends StatefulWidget {
  const SiberAsistanEkrani({super.key});

  @override
  State<SiberAsistanEkrani> createState() => _SiberAsistanEkraniState();
}

class _SiberAsistanEkraniState extends State<SiberAsistanEkrani> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final AdManager _adManager = AdManager();
  final TtsService _ttsService = sl<TtsService>();
  final AiAnalysisService _aiAnalysisService = sl<AiAnalysisService>();
  final User? _currentUser = sl<FirebaseAuth>().currentUser;

  List<Map<String, String>> _mesajlar = [];
  bool _yukleniyor = false;
  bool _sesAcik = false;

  int _anlikPuan = 0;
  int _anlikRozet = 0;
  int _gorevSayisi = 0;
  int _kalanHak = 5;
  String _kullaniciAdi = "Kahraman";
  String _yasGrubu = "6-12";
  List<String> _sonHatalar = [];
  bool _isExempt = false;

  Color _seciliRenk = const Color(0xFF009688);

  @override
  void initState() {
    super.initState();
    _verileriYukle();
    _reklamYukle();
  }

  void _reklamYukle() {
    _adManager.loadRewardedAd(
      onAdLoaded: () {
        if (mounted) setState(() {});
      },
    );
  }

  void _enerjiBittiUyarisi() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        title: const Text(
          "Enerjin Azaldı! ⚡",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: const Text(
          "Kahraman Dostum ile daha fazla konuşmak için kısa bir video izleyip +5 enerji kazanmak ister misin? ✨",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Sonra"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _seciliRenk,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(context);
              _adManager.showRewardedAd(
                onUserEarnedReward: () async {
                  _showSnack(
                    "Enerjin yolda! Kısa bir süre içinde hesabına tanımlanacak. ⚡",
                  );

                  try {
                    // Sunucudaki ödül verme fonksiyonunu çağır
                    final HttpsCallable grantRewardFn = FirebaseFunctions
                        .instanceFor(region: 'europe-west1')
                        .httpsCallable('grantAdReward');
                    await grantRewardFn.call();

                    // Firestore'daki değişikliği görmek için kısa bir süre bekleyip yenileyebiliriz.
                    await Future.delayed(const Duration(seconds: 1));
                    await _verileriYukle();
                  } catch (e) {
                    debugPrint("Ödül işleme hatası: $e");
                    _showSnack("Enerji eklenirken bir sorun oluştu.");
                  }
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
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(m), backgroundColor: _seciliRenk));
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
          _kalanHak = pData['gemini_hakki'] ?? 5;

          if (pData.containsKey('sohbet_gecmisi')) {
            final rawHistory = pData['sohbet_gecmisi'] as List? ?? [];
            _mesajlar = rawHistory.map((item) {
              final map = item as Map<String, dynamic>;

              // Rol normalizasyonu: Sadece 'user' veya 'assistant' olacak
              String rol = map['rol']?.toString().toLowerCase() ?? 'user';
              if (rol == 'kullanici') rol = 'user';
              if (rol == 'model' || rol == 'bot' || rol == 'robot')
                rol = 'assistant';

              return {'rol': rol, 'metin': map['metin']?.toString() ?? ''};
            }).toList();
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

  Future<void> _mesajGonder(String metin) async {
    if (metin.trim().isEmpty || _yukleniyor) return;

    // LİMİT KONTROLÜ (Client-side hızlı kontrol)
    if (!_isExempt && _kalanHak <= 0) {
      _enerjiBittiUyarisi();
      return;
    }

    final Map<String, String> kullaniciMesaji = {"rol": "user", "metin": metin};

    setState(() {
      _mesajlar.add(kullaniciMesaji);
      _yukleniyor = true;
      if (!_isExempt) _kalanHak--; // İyimser güncelleme
    });

    _controller.clear();
    _scrollToBottom();
    // _mesajKaydet sunucuya devredildi

    try {
      // Fonksiyonu tam çağrıldığı anda, europe-west1 bölgesi ile oluşturalım
      final HttpsCallable callable = FirebaseFunctions.instanceFor(
        region: 'europe-west1',
      ).httpsCallable('geminiChat');

      final result = await callable
          .call({'mesaj': _sanitizeForAi(metin)})
          .timeout(const Duration(seconds: 20));

      if (!mounted) return;

      final data = result.data as Map?;
      String botCevabi = data?['cevap']?.toString() ?? '';

      if (data?.containsKey('newLimit') == true) {
        final nl = data!['newLimit'];
        if (nl is int && nl >= 0) {
          setState(() => _kalanHak = nl);
        }
      }

      // TEHLİKE TESPİTİ (Gelişmiş Regex: [TEHLIKE_TESPIT], [TEHLİKETESPİT] vb. hepsini yakalar)
      final dangerRegex = RegExp(
        r'\[TEHL[Iİ]KE_?TESP[Iİ]T\]',
        caseSensitive: false,
      );
      final bool tehlikeVarMi =
          data?['riskLevel'] == 'IMMINENT' || dangerRegex.hasMatch(botCevabi);

      if (tehlikeVarMi) {
        // Etiketi kullanıcı görmeden tertemiz siliyoruz
        botCevabi = botCevabi.replaceAll(dangerRegex, "").trim();
      }

      // Sunucunun ayrı risk alanı metin filtresinden önce değerlendirildi.
      botCevabi = _sanitizeBotResponse(botCevabi);

      if (botCevabi.isEmpty) {
        botCevabi =
            "Sana yardımcı olamıyorum, ama bir yetişkine veya öğretmene danışabilirsin. 💙";
      }

      final Map<String, String> botMesaji = {
        "rol": "assistant",
        "metin": botCevabi,
      };

      setState(() {
        _mesajlar.add(botMesaji);
        _yukleniyor = false;
      });

      // _mesajKaydet sunucuya devredildi
      if (_sesAcik) _ttsService.speak(_emojileriTemizle(botCevabi));

      if (tehlikeVarMi) {
        Future.delayed(const Duration(seconds: 1), () {
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
      if (mounted) setState(() => _yukleniyor = false);
      _hataMesajiGoster(e.message ?? "Bir hata oluştu.");
    } catch (e) {
      debugPrint("Siber Asistan Hatası: $e");
      if (mounted) setState(() => _yukleniyor = false);
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
          "Kahraman Dostum'a şu an ulaşılamıyor. Lütfen biraz sonra tekrar dene. 💙";
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
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_currentUser == null)
      return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('usersProgress')
          .doc(_currentUser!.uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data!.exists) {
          final data = snapshot.data!.data() as Map<String, dynamic>;
          _anlikPuan = data['toplam_puan'] ?? 0;
          _anlikRozet = (data['rozetler'] as List? ?? []).length;
          _gorevSayisi = (data['tamamlanan_bolumler'] as List? ?? []).length;
          _kalanHak = data['gemini_hakki'] ?? 5;
        }

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
      },
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(25)),
      ),
      title: InkWell(
        onTap: _showKahramanDostumInfo,
        borderRadius: BorderRadius.circular(15),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                backgroundColor: _seciliRenk.withOpacity(0.1),
                child: Icon(Icons.smart_toy_rounded, color: _seciliRenk),
              ),
              const SizedBox(width: 10),
              Flexible(
                child: Text(
                  "Kahraman Dostum",
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  style: TextStyle(
                    color: Colors.blueGrey.shade900,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
              Icon(Icons.info_outline_rounded, size: 14, color: Colors.blueGrey.withOpacity(0.5)),
            ],
          ),
        ),
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
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade200, width: 0.5),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _badgeChip(Icons.stars_rounded, "$_anlikPuan TP", Colors.orange),
          _badgeChip(
            Icons.emoji_events_rounded,
            "$_anlikRozet",
            Colors.deepPurpleAccent,
          ),
          if (!_isExempt)
            _badgeChip(Icons.bolt_rounded, "$_kalanHak", Colors.amber.shade700),
        ],
      ),
    );
  }

  Widget _badgeChip(IconData i, String l, Color c) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(i, color: c, size: 14),
      const SizedBox(width: 4),
      Text(
        l,
        style: TextStyle(
          color: Colors.blueGrey.shade800,
          fontWeight: FontWeight.w900,
          fontSize: 11,
        ),
      ),
    ],
  );

  Widget _buildGameBubble(Map<String, String> m) {
    bool isMe = m["rol"] == "user" || m["rol"] == "kullanici";
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
      "Zorbalık nedir ❔",
      "Siber zorbalık nedir? 💻",
      "Zorbalığa uğradığımda ne yapabilirim ❓",
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
      final HttpsCallable callable = FirebaseFunctions.instanceFor(
        region: 'europe-west1',
      ).httpsCallable('clearGeminiHistory');
      await callable.call();

      if (!mounted) return;
      setState(() {
        _mesajlar.clear();
      });
      _ilkMesaj();
    } catch (e) {
      debugPrint("Sohbet temizleme hatası: $e");
      _showSnack("Sohbet temizlenemedi.");
    }
  }

  void _ilkMesaj() {
    String m =
        "Selam $_kullaniciAdi! 🤖 Ben senin Kahraman Dostunum. Her türlü zorbalığa karşı birlikte güçlenmeye hazır mısın? ✨ İstersen seninle eğitici bir oyun oynayabiliriz, 'Hadi oyun oynayalım' demen yeterli! 🎮";
    final Map<String, String> botMesaji = {"rol": "assistant", "metin": m};
    setState(() {
      _mesajlar.add(botMesaji);
    });
    if (_sesAcik) _ttsService.speak(_emojileriTemizle(m));
  }

  void _showKahramanDostumInfo() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _KahramanDostumInfoSheet(seciliRenk: _seciliRenk),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _ttsService.stop();
    _adManager.dispose();
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

class _KahramanDostumInfoSheet extends StatelessWidget {
  final Color seciliRenk;
  const _KahramanDostumInfoSheet({required this.seciliRenk});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).padding.bottom + 20,
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 30),
              // Üst Bölüm
              CircleAvatar(
                radius: 40,
                backgroundColor: seciliRenk.withOpacity(0.1),
                child: Icon(Icons.smart_toy_rounded, size: 45, color: seciliRenk),
              ),
              const SizedBox(height: 16),
              Text(
                "Kahraman Dostum",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: Colors.blueGrey.shade900,
                ),
              ),
              Text(
                "Senin öğrenme arkadaşın! 🌟",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: seciliRenk,
                ),
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  "Kahraman Dostum; sorularını cevaplamak, birlikte eğitici oyunlar oynamak ve öğrenirken sana eşlik etmek için tasarlanmış yapay zeka destekli arkadaşındır.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.blueGrey.shade700,
                    height: 1.5,
                  ),
                ),
              ),
              const SizedBox(height: 30),
              // Neler Yapabilirim?
              _buildSectionTitle("✨ Neler yapabilirim?"),
              const SizedBox(height: 12),
              _buildFeatureGrid(),
              const SizedBox(height: 30),
              // Yapay Zeka Altyapısı
              _buildSectionTitle("🧠 Yapay zekâ altyapısı"),
              const SizedBox(height: 12),
              _buildAiCard(),
              const SizedBox(height: 30),
              // Güvenli Öğrenme
              _buildSectionTitle("🛡️ Güvenli öğrenme"),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  "Kahraman Dostum, eğitici, güvenli ve yaşa uygun bir öğrenme deneyimi sunmak üzere tasarlanmıştır.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.blueGrey.shade600,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
              const SizedBox(height: 40),
              // Kapat butonu
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: seciliRenk,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      "Tamam, anladım",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title.toUpperCase(),
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w900,
            color: Colors.blueGrey.shade400,
            letterSpacing: 1.2,
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureGrid() {
    final features = [
      {"icon": Icons.menu_book_rounded, "text": "Derslerinde yardımcı olur"},
      {"icon": Icons.sports_esports_rounded, "text": "Eğitici oyunlar oynar"},
      {"icon": Icons.lightbulb_rounded, "text": "Konuları daha kolay anlamanı sağlar"},
      {"icon": Icons.extension_rounded, "text": "Mini bulmacalar ve sorular hazırlar"},
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: features.map((f) => Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade100),
          ),
          child: Row(
            children: [
              Icon(f["icon"] as IconData, color: seciliRenk, size: 20),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  f["text"] as String,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.blueGrey.shade800,
                  ),
                ),
              ),
            ],
          ),
        )).toList(),
      ),
    );
  }

  Widget _buildAiCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [seciliRenk.withOpacity(0.05), Colors.blue.withOpacity(0.05)],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: seciliRenk.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                )
              ],
            ),
            child: Icon(Icons.auto_awesome, color: seciliRenk, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Gemini",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Colors.blueGrey.shade900,
                  ),
                ),
                Text(
                  "Google'ın yapay zekâ teknolojisiyle desteklenmektedir.",
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.blueGrey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
