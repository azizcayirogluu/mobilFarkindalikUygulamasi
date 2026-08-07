import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:zorbalik_uygulamasi/injection_container.dart';
import 'package:zorbalik_uygulamasi/services/tts_service.dart';
import 'package:zorbalik_uygulamasi/services/analytics_service.dart';
class HikayeDetayEkrani extends StatefulWidget {
  final String baslik;
  final String gorselYolu;
  final Color temaRengi;
  final String hikayeMetni;
  final String feedbackMessage;

  const HikayeDetayEkrani({
    super.key,
    required this.baslik,
    required this.gorselYolu,
    required this.temaRengi,
    required this.hikayeMetni,
    required this.feedbackMessage,
  });

  @override
  State<HikayeDetayEkrani> createState() => _HikayeDetayEkraniState();
}

class _HikayeDetayEkraniState extends State<HikayeDetayEkrani> {
  final TtsService _ttsService = sl<TtsService>();
  bool isReading = false;
  final User? _currentUser = FirebaseAuth.instance.currentUser;

  @override
  void dispose() {
    _ttsService.stop();
    super.dispose();
  }

  Future<void> _hikayeyiBitir() async {
    if (_currentUser == null) return;

    final String uid = _currentUser.uid;
    // Merkezi servis üzerinden görev tamamlama (Kusursuz Rozet Sistemi)
    await AnalyticsService().gorevTamamla(
      uid: uid,
      puan: 15,
      gorevId: widget.baslik,
      gorevTipi: 'hikaye',
    );
    
    await AnalyticsService().sureEkle(uid, 2);

    if (mounted) {
      _showSuccessDialog();
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.stars_rounded, size: 80, color: Colors.amber),
            const SizedBox(height: 20),
            Text(widget.baslik, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 10),
            Text(
              widget.feedbackMessage.isNotEmpty ? widget.feedbackMessage : "Harika! Bir hikaye daha bitti.",
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: Colors.blueGrey),
            ),
            const SizedBox(height: 25),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: widget.temaRengi,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                minimumSize: const Size(double.infinity, 50),
              ),
              onPressed: () {
                Navigator.pop(context); // Diyaloğu kapat
                Navigator.pop(context); // Ekrandan çık
              },
              child: const Text("DEVAM ET", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _seslendir() async {
    if (isReading) {
      await _ttsService.stop();
      if (mounted) setState(() => isReading = false);
    } else {
      if (mounted) setState(() => isReading = true);
      try {
        await _ttsService.speak(widget.hikayeMetni);
      } catch (e) {
        debugPrint("Hikaye seslendirme hatası: $e");
      } finally {
        if (mounted) setState(() => isReading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 320,
            pinned: true,
            backgroundColor: widget.temaRengi,
            actions: [
              IconButton(
                icon: Icon(isReading ? Icons.stop_circle_rounded : Icons.play_circle_fill_rounded, color: Colors.white, size: 30),
                onPressed: _seslendir,
              ),
              const SizedBox(width: 10),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Hero(
                tag: widget.baslik,
                child: widget.gorselYolu.startsWith("http")
                    ? CachedNetworkImage(
                        imageUrl: widget.gorselYolu,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
                        errorWidget: (context, url, error) => const Icon(Icons.error),
                      )
                    : Image.asset(
                        widget.gorselYolu,
                        fit: BoxFit.cover,
                        errorBuilder: (c, e, s) => Container(
                          color: widget.temaRengi,
                          child: const Icon(Icons.book, size: 80, color: Colors.white),
                        ),
                      ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(25),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.baslik, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: widget.temaRengi)),
                  const SizedBox(height: 20),
                  Text(widget.hikayeMetni, style: const TextStyle(fontSize: 17, height: 1.6, color: Colors.black87)),
                  const SizedBox(height: 40),
                  if (widget.feedbackMessage.isNotEmpty) _buildHeroNote(),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomSheet: Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(color: Colors.white),
        child: ElevatedButton(
          onPressed: _hikayeyiBitir,
          style: ElevatedButton.styleFrom(backgroundColor: widget.temaRengi, minimumSize: const Size(double.infinity, 60), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
          child: const Text("OKUMAYI TAMAMLADIM ✅", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }

  Widget _buildHeroNote() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: widget.temaRengi.withOpacity(0.1), borderRadius: BorderRadius.circular(20), border: Border.all(color: widget.temaRengi.withOpacity(0.3))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [Icon(Icons.lightbulb, color: widget.temaRengi), const SizedBox(width: 10), const Text("KAHRAMAN NOTU", style: TextStyle(fontWeight: FontWeight.bold))]),
          const SizedBox(height: 10),
          Text(widget.feedbackMessage, style: const TextStyle(fontStyle: FontStyle.italic)),
        ],
      ),
    );
  }
}
