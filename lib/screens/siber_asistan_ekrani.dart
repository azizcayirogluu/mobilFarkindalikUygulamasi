import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:zorbalik_uygulamasi/app_theme.dart';
import 'package:zorbalik_uygulamasi/injection_container.dart';
import 'package:zorbalik_uygulamasi/services/tts_service.dart';
import 'package:zorbalik_uygulamasi/services/ad_manager.dart';
import 'package:zorbalik_uygulamasi/utils/app_logger.dart';
import 'package:zorbalik_uygulamasi/screens/siber_imdat_ekrani.dart';

class SiberAsistanEkrani extends StatefulWidget {
  const SiberAsistanEkrani({super.key});

  @override
  State<SiberAsistanEkrani> createState() => _SiberAsistanEkraniState();
}

class _SiberAsistanEkraniState extends State<SiberAsistanEkrani> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final TtsService _ttsService = sl<TtsService>();
  final AdManager _adManager = sl<AdManager>();
  final User? _currentUser = FirebaseAuth.instance.currentUser;

  final List<Map<String, String>> _mesajlar = [];
  bool _yukleniyor = false;
  bool _sesAcik = false;
  bool _isExempt = false;
  int _kalanHak = 5;

  final Color _botColor = const Color(0xFF6366F1);
  final Color _userColor = const Color(0xFF10B981);

  @override
  void initState() {
    super.initState();
    _adManager.loadRewardedAd(onAdLoaded: () {});
    _verileriYukle();
  }

  Future<void> _verileriYukle() async {
    final user = _currentUser;
    if (user == null) return;
    final uid = user.uid;

    try {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (mounted && userDoc.exists) {
        setState(() {
          _isExempt = userDoc.data()?['isAdmin'] == true || userDoc.data()?['isPremium'] == true;
        });
      }

      final progressDoc = await FirebaseFirestore.instance.collection('usersProgress').doc(uid).get();
      if (mounted && progressDoc.exists) {
        final pData = progressDoc.data();
        if (pData != null) {
          setState(() {
            _kalanHak = pData['gemini_hakki'] ?? 5;
            if (pData['sohbet_gecmisi'] != null) {
              _mesajlar.clear();
              for (var item in (pData['sohbet_gecmisi'] as List)) {
                // KRİTİK: Firebase'deki 'rol' anahtarını (kullanici/asistan) kontrol et
                String r = (item['rol'] ?? item['role'] ?? 'asistan').toString().toLowerCase();
                _mesajlar.add({
                  'role': (r == 'kullanici' || r == 'user') ? 'user' : 'assistant',
                  'metin': item['metin'] ?? item['text'] ?? '',
                });
              }
            }
          });
        }
      }

      if (_mesajlar.isEmpty) _ilkMesajEkle();
      _scrollToBottom();
    } catch (e) {
      debugPrint("Veri yükleme hatası: $e");
    }
  }

  void _ilkMesajEkle() {
    final ad = _currentUser?.displayName ?? "Kahraman";
    setState(() {
      _mesajlar.add({
        "role": "assistant",
        "metin": "Selam $ad! 🤖 Bugün siber dünyada neler yaptın? Merak ettiğin her şeyi bana sorabilirsin! ✨"
      });
    });
  }

  Future<void> _sohbetiTemizle() async {
    final onay = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text("Sohbeti Silelim mi? 🗑️", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        content: const Text("Konuşmalarımız tamamen silinecek. Yeni bir başlangıca hazır mısın?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text("VAZGEÇ", style: TextStyle(color: Colors.grey))),
          TextButton(onPressed: () => Navigator.pop(c, true), child: const Text("EVET, SİL", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold))),
        ],
      ),
    );

    if (onay == true && _currentUser != null) {
      setState(() { _mesajlar.clear(); _ilkMesajEkle(); });
      try {
        await FirebaseFirestore.instance.collection('usersProgress').doc(_currentUser!.uid).update({'sohbet_gecmisi': FieldValue.delete()});
      } catch (e) { debugPrint(e.toString()); }
    }
  }

  Future<void> _mesajGonder(String metin) async {
    final temizMetin = metin.trim();
    if (temizMetin.isEmpty || _yukleniyor) return;
    if (!_isExempt && _kalanHak <= 0) { _enerjiUyarisi(); return; }

    setState(() {
      _mesajlar.add({"role": "user", "metin": temizMetin});
      _yukleniyor = true;
    });
    _controller.clear();
    _scrollToBottom();

    try {
      final callable = FirebaseFunctions.instanceFor(region: 'europe-west1').httpsCallable('geminiChat');
      final result = await callable.call({'mesaj': temizMetin});
      if (!mounted) return;
      final data = result.data as Map?;
      final botCevabi = data?['cevap']?.toString() ?? 'Buradayım Kahraman! 💙';

      setState(() {
        _yukleniyor = false;
        _mesajlar.add({"role": "assistant", "metin": botCevabi});
        if (data?['newLimit'] != null) _kalanHak = data!['newLimit'];
      });

      if (_sesAcik) _ttsService.speak(botCevabi);
      if (data?['riskLevel'] == 'IMMINENT') _tehlikeYonlendirmesi();
    } catch (e) {
      if (mounted) setState(() { _yukleniyor = false; _mesajlar.add({"role": "assistant", "metin": "Bağlantıda ufak bir sorun oldu, tekrar dener misin? 🤖"}); });
    }
    _scrollToBottom();
  }

  void _tehlikeYonlendirmesi() {
    Future.delayed(1.seconds, () { if (mounted) Navigator.push(context, MaterialPageRoute(builder: (_) => const SiberImdatEkrani())); });
  }

  void _enerjiUyarisi() {
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text("Enerjin Bitti! ⚡", style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text("Siber Asistan'ın biraz dinlenmesi gerek. Reklam izleyerek +5 hak kazanabilirsin!"),
        actions: [ 
          TextButton(onPressed: () => Navigator.pop(c), child: const Text("VAZGEÇ", style: TextStyle(color: Colors.grey))),
          TextButton(
            onPressed: () {
              Navigator.pop(c);
              _reklamIzle();
            }, 
            child: Text("REKLAM İZLE 📺", style: TextStyle(fontWeight: FontWeight.bold, color: _botColor)),
          ),
        ],
      ),
    );
  }

  void _reklamIzle() {
    _adManager.showRewardedAd(
      onUserEarnedReward: () async {
        try {
          final callable = FirebaseFunctions.instanceFor(region: 'europe-west1').httpsCallable('grantAdReward');
          await callable.call();
          setState(() {
            _kalanHak += 5;
          });
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Harika! +5 Enerji Kazandın! ⚡"),
                backgroundColor: Colors.green,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        } catch (e) {
          AppLogger.error("Ödül işleme hatası", e);
        }
      },
      onAdClosed: () {
        _adManager.loadRewardedAd(onAdLoaded: () {});
      },
    );
  }

  @override
  void dispose() {
    _ttsService.stop();
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(_scrollController.position.maxScrollExtent, duration: 300.ms, curve: Curves.easeOut);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildStatsBar(),
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
              physics: const BouncingScrollPhysics(),
              itemCount: _mesajlar.length,
              itemBuilder: (context, index) {
                final msg = _mesajlar[index];
                // KESİN HİZALAMA KONTROLÜ
                final isMe = msg['role'] == 'user';
                return _ChatBubble(
                  msg: msg,
                  color: isMe ? _userColor : _botColor,
                  isMe: isMe,
                ).animate().fadeIn(duration: 200.ms).slideY(begin: 0.02);
              },
            ),
          ),
          if (_yukleniyor) _buildTypingIndicator(),
          _buildQuickActions(),
          _buildInputArea(),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      toolbarHeight: 65,
      backgroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: Color(0xFF475569)),
        onPressed: () => Navigator.pop(context),
      ),
      centerTitle: true,
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.smart_toy_rounded, color: Color(0xFF6366F1), size: 20),
          const SizedBox(width: 8),
          const Text("Kahraman Dostum", style: TextStyle(color: Color(0xFF1E293B), fontWeight: FontWeight.w900, fontSize: 16)),
        ],
      ),
      actions: [
        IconButton(icon: const Icon(Icons.delete_sweep_rounded, color: Colors.redAccent, size: 22), onPressed: _sohbetiTemizle),
        IconButton(
          icon: Icon(_sesAcik ? Icons.volume_up_rounded : Icons.volume_off_rounded, color: _botColor, size: 22), 
          onPressed: () {
            setState(() {
              _sesAcik = !_sesAcik;
              if (!_sesAcik) _ttsService.stop();
            });
          },
        ),
        const SizedBox(width: 4),
      ],
    );
  }

  Widget _buildStatsBar() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 20),
      decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 5)]),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _StatChip(icon: Icons.bolt_rounded, label: _isExempt ? "Sınırsız Güç" : "$_kalanHak Enerji", color: Colors.amber.shade700),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(left: 20, bottom: 10),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(color: _botColor.withOpacity(0.1), borderRadius: BorderRadius.circular(15)),
            child: Text("Yazıyor...", style: TextStyle(color: _botColor, fontSize: 11, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    final actions = ["Zorbalık nedir? ❓", "Oyun oynayalım! 🎮", "Nasıl güvende kalırım 🛡️"];
    return Container(
      height: 44,
      margin: const EdgeInsets.only(bottom: 4),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: actions.length,
        itemBuilder: (context, i) => Padding(
          padding: const EdgeInsets.only(right: 8),
          child: ActionChip(
            label: Text(actions[i], style: TextStyle(color: _botColor, fontWeight: FontWeight.bold, fontSize: 11)),
            backgroundColor: Colors.white,
            side: BorderSide(color: _botColor.withOpacity(0.1)),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            onPressed: () => _mesajGonder(actions[i]),
          ),
        ),
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: EdgeInsets.fromLTRB(16, 8, 16, MediaQuery.of(context).padding.bottom + 8),
      decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -2))]),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(20)),
              child: TextField(
                controller: _controller,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                decoration: const InputDecoration(hintText: "Mesajını yaz...", border: InputBorder.none, contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 10)),
                onSubmitted: _mesajGonder,
              ),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: () => _mesajGonder(_controller.text),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: _botColor, shape: BoxShape.circle),
              child: const Icon(Icons.send_rounded, color: Colors.white, size: 18),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  final Map<String, String> msg;
  final Color color;
  final bool isMe;
  const _ChatBubble({required this.msg, required this.color, required this.isMe});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: isMe ? color : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(isMe ? 18 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 18),
          ),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 5, offset: const Offset(0, 2))],
          border: isMe ? null : Border.all(color: const Color(0xFFF1F5F9), width: 1),
        ),
        child: Text(
          msg['metin']!,
          style: TextStyle(color: isMe ? Colors.white : const Color(0xFF334155), fontSize: 14, height: 1.4, fontWeight: FontWeight.w500),
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _StatChip({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 11, color: color)),
        ],
      ),
    );
  }
}
