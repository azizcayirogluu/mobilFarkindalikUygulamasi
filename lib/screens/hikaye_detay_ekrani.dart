import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:zorbalik_uygulamasi/injection_container.dart';
import 'package:zorbalik_uygulamasi/services/tts_service.dart';
import 'package:zorbalik_uygulamasi/services/analytics_service.dart';
import 'package:flutter_animate/flutter_animate.dart';

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
    await AnalyticsService().gorevTamamla(
      uid: uid,
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(35)),
        backgroundColor: Colors.white,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.stars_rounded, size: 80, color: Colors.amber)
                .animate(onPlay: (c) => c.repeat())
                .scale(begin: const Offset(0.8, 0.8), end: const Offset(1.1, 1.1), duration: 1.seconds),
            const SizedBox(height: 20),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                widget.baslik,
                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20, color: Color(0xFF1E293B)),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              widget.feedbackMessage.isNotEmpty ? widget.feedbackMessage : "Harika! Bir hikaye daha bitti. Sen gerçek bir kahramansın!",
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: widget.temaRengi,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                minimumSize: const Size(double.infinity, 55),
                elevation: 0,
              ),
              onPressed: () {
                Navigator.pop(context); // Diyaloğu kapat
                Navigator.pop(context); // Ekrandan çık
              },
              child: const Text("DEVAM ET 🚀", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
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
      backgroundColor: const Color(0xFFF8FAFC),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            expandedHeight: 350,
            pinned: true,
            stretch: true,
            backgroundColor: widget.temaRengi,
            leading: Padding(
              padding: const EdgeInsets.all(8.0),
              child: CircleAvatar(
                backgroundColor: Colors.black26,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: CircleAvatar(
                  backgroundColor: isReading ? Colors.white : Colors.black26,
                  child: IconButton(
                    icon: Icon(
                      isReading ? Icons.stop_rounded : Icons.play_arrow_rounded,
                      color: isReading ? widget.temaRengi : Colors.white,
                      size: 24,
                    ),
                    onPressed: _seslendir,
                  ),
                ),
              ),
              const SizedBox(width: 8),
            ],
            flexibleSpace: FlexibleSpaceBar(
              stretchModes: const [StretchMode.zoomBackground],
              background: Hero(
                tag: widget.baslik,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    widget.gorselYolu.startsWith("http")
                        ? CachedNetworkImage(
                            imageUrl: widget.gorselYolu,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(color: widget.temaRengi.withOpacity(0.1), child: const Center(child: CircularProgressIndicator())),
                            errorWidget: (context, url, error) => Container(color: widget.temaRengi, child: const Icon(Icons.error, color: Colors.white)),
                          )
                        : Image.asset(
                            widget.gorselYolu,
                            fit: BoxFit.cover,
                            errorBuilder: (c, e, s) => Container(
                              color: widget.temaRengi,
                              child: const Icon(Icons.book, size: 80, color: Colors.white),
                            ),
                          ),
                    // Görselin alt kısmına yumuşak bir geçiş
                    Positioned(
                      bottom: -1,
                      left: 0,
                      right: 0,
                      child: Container(
                        height: 30,
                        decoration: const BoxDecoration(
                          color: Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: widget.temaRengi.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      "MACERA HİKAYESİ",
                      style: TextStyle(color: widget.temaRengi, fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: 1.2),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    widget.baslik,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF1E293B),
                      letterSpacing: -0.5,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(25),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.03),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Text(
                      widget.hikayeMetni,
                      style: const TextStyle(
                        fontSize: 17,
                        height: 1.7,
                        color: Color(0xFF334155),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  if (widget.feedbackMessage.isNotEmpty) _buildHeroNote(),
                  const SizedBox(height: 120),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomSheet: Container(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: _hikayeyiBitir,
          style: ElevatedButton.styleFrom(
            backgroundColor: widget.temaRengi,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 60),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            elevation: 0,
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text("OKUMAYI TAMAMLADIM ✅", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeroNote() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: widget.temaRengi.withOpacity(0.2), width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: widget.temaRengi.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.lightbulb_rounded, color: widget.temaRengi, size: 20),
              ),
              const SizedBox(width: 12),
              const Text(
                "KAHRAMAN NOTU",
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: Color(0xFF1E293B)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            widget.feedbackMessage,
            style: const TextStyle(
              fontStyle: FontStyle.italic,
              fontSize: 14,
              color: Color(0xFF475569),
              height: 1.5,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1);
  }
}
