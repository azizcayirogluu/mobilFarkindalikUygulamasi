import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_animate/flutter_animate.dart';

class SiberAsistanEkrani extends StatefulWidget {
  const SiberAsistanEkrani({super.key});

  @override
  State<SiberAsistanEkrani> createState() => _SiberAsistanEkraniState();
}

class _SiberAsistanEkraniState extends State<SiberAsistanEkrani> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FlutterTts flutterTts = FlutterTts();
  final User? _currentUser = FirebaseAuth.instance.currentUser;

  List<Map<String, String>> _mesajlar = [];
  List<Map<String, dynamic>> _history = [];
  bool _yukleniyor = false;
  bool _sesAcik = true;

  int _anlikPuan = 0;
  int _anlikRozet = 0;
  String _kullaniciAdi = "Kahraman";

  Color _seciliRenk = const Color(0xFF009688);
  final List<Color> _pastelRenkler = [
    const Color(0xFF009688), // Teal
    const Color(0xFFEC407A), // Pembe
    const Color(0xFF7E57C2), // Mor
    const Color(0xFFFFA726), // Turuncu
    const Color(0xFF42A5F5), // Mavi
  ];

  final String _apiKey = "AIzaSyAdZNBH2ppWqLEhp_ZmtQfpJ3dLHjJnMdU";

  @override
  void initState() {
    super.initState();
    _initTts();
    _verileriYukle();
  }

  Future<void> _initTts() async {
    await flutterTts.setLanguage("tr-TR");
    await flutterTts.setPitch(1.3);
    await flutterTts.setSpeechRate(0.55);
    await flutterTts.setVolume(1.0);
  }

  Future<void> _verileriYukle() async {
    if (_currentUser == null) return;
    try {
      var userDoc = await FirebaseFirestore.instance.collection('usersProgress').doc(_currentUser!.uid).get();
      if (userDoc.exists) {
        var data = userDoc.data()!;
        setState(() {
          _anlikPuan = data['toplam_puan'] ?? 0;
          _anlikRozet = (data['rozetler'] as List? ?? []).length;
          _kullaniciAdi = _currentUser!.displayName ?? "Kahraman";

          if (data.containsKey('sohbet_gecmisi')) {
            _mesajlar = List<Map<String, String>>.from(
              (data['sohbet_gecmisi'] as List).map((item) => Map<String, String>.from(item))
            );
            
            _history = _mesajlar.map((m) => {
              "role": m["rol"] == "kullanici" ? "user" : "model",
              "parts": [{"text": m["metin"]}]
            }).toList();
          }
        });
        
        if (_mesajlar.isEmpty) {
          _ilkMesaj();
        } else {
          _scrollToBottom();
        }
      }
    } catch (e) {
      debugPrint("Veri yükleme hatası: $e");
      _ilkMesaj();
    }
  }

  Future<void> _sesliOku(String metin) async {
    if (_sesAcik) {
      String temiz = metin.replaceAll(RegExp(r'[*_#>]'), '');
      temiz = temiz.replaceAll(RegExp(r'[\u{1F600}-\u{1F64F}\u{1F300}-\u{1F5FF}\u{1F680}-\u{1F6FF}\u{1F1E6}-\u{1F1FF}\u{2600}-\u{26FF}\u{2700}-\u{27BF}]', unicode: true), '');
      await flutterTts.stop();
      if (temiz.trim().isNotEmpty) {
        await flutterTts.speak(temiz.trim());
      }
    }
  }

  // GÜNCELLEME: Mesajları usersProgress/uid içindeki 'sohbet_gecmisi' listesine ekliyoruz
  Future<void> _mesajlariKaydet() async {
    if (_currentUser == null) return;
    try {
      await FirebaseFirestore.instance
          .collection('usersProgress')
          .doc(_currentUser!.uid)
          .update({
        'sohbet_gecmisi': _mesajlar,
        'son_mesaj_tarihi': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint("Kayıt hatası: $e");
    }
  }

  Future<void> _mesajGonder(String metin) async {
    if (metin.trim().isEmpty || _yukleniyor) return;
    setState(() {
      _mesajlar.add({"rol": "kullanici", "metin": metin});
      _history.add({"role": "user", "parts": [{"text": metin}]});
      _yukleniyor = true;
    });

    _controller.clear();
    _scrollToBottom();

    try {
      final response = await http.post(
        Uri.parse('https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=$_apiKey'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "contents": _history,
          "systemInstruction": {
            "parts": [{"text": "Adın Siber Dost. $_kullaniciAdi ile konuşuyorsun. Puanı: $_anlikPuan. CEVAPLARIN ÇOK KISA OLSUN (MAX 2 CÜMLE). Bol emoji kullan."}]
          }
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final String botCevabi = data['candidates'][0]['content']['parts'][0]['text'];
        setState(() {
          _mesajlar.add({"rol": "bot", "metin": botCevabi});
          _history.add({"role": "model", "parts": [{"text": botCevabi}]});
          _yukleniyor = false;
        });

        // Tüm mesaj listesini tek seferde update ediyoruz (field olarak)
        _mesajlariKaydet();
        _sesliOku(botCevabi);
      }
    } catch (e) { setState(() => _yukleniyor = false); }
    _scrollToBottom();
  }

  // --- Tasarım Kodları (Dokunulmadı) ---
  void _scrollToBottom() {
    Future.delayed(300.ms, () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(_scrollController.position.maxScrollExtent, duration: 500.ms, curve: Curves.easeOut);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      appBar: _buildAppBar(),
      body: Stack(
        children: [
          _buildStaticBackground(),
          Column(
            children: [
              _buildStatsHeader(),
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
                  itemCount: _mesajlar.length,
                  itemBuilder: (context, index) => _buildGameBubble(_mesajlar[index]),
                ),
              ),
              if (_yukleniyor) _buildTypingIndicator(),
              _buildQuickActions(),
              _buildModernInput(),
            ],
          ),
        ],
      ),
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
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(bottom: Radius.circular(25))),
      title: Row(
        children: [
          CircleAvatar(
            backgroundColor: _seciliRenk.withOpacity(0.1),
            child: Icon(Icons.smart_toy_rounded, color: _seciliRenk),
          ),
          const SizedBox(width: 10),
          Text("Siber Dost", style: TextStyle(color: Colors.blueGrey.shade900, fontWeight: FontWeight.bold, fontSize: 18)),
        ],
      ),
      actions: [
        IconButton(
            icon: Icon(_sesAcik ? Icons.volume_up : Icons.volume_off, color: _seciliRenk),
            onPressed: () { setState(() => _sesAcik = !_sesAcik); if(!_sesAcik) flutterTts.stop(); }
        ),
        PopupMenuButton<Color>(
          icon: Icon(Icons.palette_rounded, color: _seciliRenk),
          onSelected: (Color c) => setState(() => _seciliRenk = c),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          itemBuilder: (context) => _pastelRenkler.map((c) => PopupMenuItem<Color>(
            value: c,
            child: Center(child: CircleAvatar(backgroundColor: c, radius: 15)),
          )).toList(),
        ),
        IconButton(icon: const Icon(Icons.refresh, color: Colors.redAccent), onPressed: _sohbetiTemizle),
      ],
    );
  }

  Widget _buildStatsHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        _badgeChip(Icons.stars, "$_anlikPuan TP", Colors.orange),
        const SizedBox(width: 10),
        _badgeChip(Icons.emoji_events, "$_anlikRozet Rozet", Colors.deepPurpleAccent),
      ]),
    );
  }

  Widget _badgeChip(IconData i, String l, Color c) => Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(15)), child: Row(children: [Icon(i, color: Colors.white, size: 16), const SizedBox(width: 5), Text(l, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12))]));

  Widget _buildGameBubble(Map<String, String> m) {
    bool isMe = m["rol"] == "kullanici";
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if(!isMe) Padding(
            padding: const EdgeInsets.only(right: 8, top: 5),
            child: CircleAvatar(radius: 15, backgroundColor: Colors.white, child: Icon(Icons.smart_toy, size: 18, color: _seciliRenk)),
          ),
          Container(
            margin: const EdgeInsets.only(bottom: 15),
            padding: const EdgeInsets.all(14),
            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.70),
            decoration: BoxDecoration(
              color: isMe ? _seciliRenk : Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(22),
                topRight: const Radius.circular(22),
                bottomLeft: Radius.circular(isMe ? 22 : 0),
                bottomRight: Radius.circular(isMe ? 0 : 22),
              ),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 12, offset: const Offset(0, 5))],
            ),
            child: Text(m["metin"]!, style: TextStyle(color: isMe ? Colors.white : Colors.black87, fontWeight: FontWeight.w500, fontSize: 15, height: 1.3)),
          ),
          if(isMe) Padding(
            padding: const EdgeInsets.only(left: 8, top: 5),
            child: CircleAvatar(radius: 15, backgroundColor: _seciliRenk.withOpacity(0.2), child: Icon(Icons.person, size: 18, color: _seciliRenk)),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    List<String> sorular = ["Şifrem güvenli mi? 🔑", "Zorbalık nedir? 😢", "Oyun oynayalım! 🎮", "Günün ipucunu ver! 💡", "Puanım nasıl? 🏆", "Biri beni üzüyor... 💔"];
    return SizedBox(
      height: 42,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: sorular.length,
        itemBuilder: (context, i) => Padding(
          padding: const EdgeInsets.only(right: 8),
          child: ActionChip(
            label: Text(sorular[i], style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: _seciliRenk)),
            backgroundColor: Colors.white,
            side: BorderSide(color: _seciliRenk.withOpacity(0.2)),
            onPressed: () => _mesajGonder(sorular[i]),
          ),
        ),
      ),
    );
  }

  Widget _buildTypingIndicator() => const Padding(padding: EdgeInsets.all(8), child: Center(child: Text("Siber Dost düşünüyor...", style: TextStyle(fontSize: 12, color: Colors.blueGrey, fontStyle: FontStyle.italic))));

  Widget _buildModernInput() {
    return Container(
      padding: EdgeInsets.fromLTRB(16, 10, 16, MediaQuery.of(context).padding.bottom + 10),
      color: Colors.white,
      child: Row(children: [
        Expanded(child: Container(padding: const EdgeInsets.symmetric(horizontal: 18), decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(25)), child: TextField(controller: _controller, decoration: const InputDecoration(hintText: "Siber Dost'a yaz...", border: InputBorder.none), onSubmitted: _mesajGonder))),
        const SizedBox(width: 10),
        GestureDetector(
          onTap: () => _mesajGonder(_controller.text),
          child: CircleAvatar(backgroundColor: _seciliRenk, child: const Icon(Icons.bolt, color: Colors.white)),
        ),
      ]),
    );
  }

  void _sohbetiTemizle() async {
    if (_currentUser == null) return;
    try {
      // Field'ı siliyoruz
      await FirebaseFirestore.instance.collection('usersProgress').doc(_currentUser!.uid).update({
        'sohbet_gecmisi': FieldValue.delete(),
      });
      setState(() { _mesajlar.clear(); _history.clear(); });
      _ilkMesaj();
    } catch (e) { debugPrint(e.toString()); }
  }

  void _ilkMesaj() {
    String m = "Selam $_kullaniciAdi! 🤖 Ben senin Siber Dostunum. Bugün siber dünyada harika bir maceraya hazır mısın? ✨";
    setState(() { _mesajlar.add({"rol": "bot", "metin": m}); _history.add({"role": "model", "parts": [{"text": m}]}); });
    _sesliOku(m);
    _mesajlariKaydet();
  }

  @override
  void dispose() { _controller.dispose(); _scrollController.dispose(); flutterTts.stop(); super.dispose(); }
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
    canvas.drawRect(Rect.fromLTWH(size.width * 0.7, size.height * 0.1, 40, 40), paint);
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
