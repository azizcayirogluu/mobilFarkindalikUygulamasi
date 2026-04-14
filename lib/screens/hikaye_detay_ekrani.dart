import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../services/analytics_service.dart';

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
  final FlutterTts flutterTts = FlutterTts();
  bool isReading = false;
  final User? _currentUser = FirebaseAuth.instance.currentUser;
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    flutterTts.stop();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _hikayeyiBitir() async {
    if (_currentUser == null) return;

    final String uid = _currentUser!.uid;
    final docRef = FirebaseFirestore.instance.collection('usersProgress').doc(uid);

    try {
      await AnalyticsService().sureEkle(uid, 2);

      await FirebaseFirestore.instance.runTransaction((transaction) async {
        DocumentSnapshot snapshot = await transaction.get(docRef);

        if (!snapshot.exists) {
          transaction.set(docRef, {
            'uid': uid,
            'okunan_hikayeler': [widget.baslik],
            'toplam_puan': 10,
            'sonGuncelleme': FieldValue.serverTimestamp(),
          });
        } else {
          var data = snapshot.data() as Map<String, dynamic>;
          List okunanlar = data['okunan_hikayeler'] as List? ?? [];

          if (!okunanlar.contains(widget.baslik)) {
            int mevcutPuan = data['toplam_puan'] ?? 0;
            transaction.update(docRef, {
              'okunan_hikayeler': FieldValue.arrayUnion([widget.baslik]),
              'toplam_puan': mevcutPuan + 10,
              'sonGuncelleme': FieldValue.serverTimestamp(),
            });
          }
        }
      });

      if (mounted) {
        _showSuccessDialog();
      }
    } catch (e) {
      debugPrint("Hata: $e");
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.stars_rounded, size: 80, color: Colors.amber),
            const SizedBox(height: 20),
            Text(widget.baslik, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
            const SizedBox(height: 10),
            Text(
              widget.feedbackMessage.isNotEmpty ? widget.feedbackMessage : "Harika bir iş çıkardın! Bu hikayeden çok şey öğrendin. 🌟",
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, color: Colors.blueGrey),
            ),
            const SizedBox(height: 25),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: widget.temaRengi,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
              ),
              onPressed: () {
                Navigator.pop(context); // Dialogu kapat
                Navigator.pop(context); // Ekrana dön
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
      await flutterTts.stop();
      setState(() => isReading = false);
    } else {
      await flutterTts.setLanguage("tr-TR");
      await flutterTts.setPitch(1.1);
      await flutterTts.setSpeechRate(0.5);
      flutterTts.setCompletionHandler(() => setState(() => isReading = false));
      setState(() => isReading = true);
      await flutterTts.speak(widget.hikayeMetni);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        controller: _scrollController,
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            elevation: 0,
            backgroundColor: widget.temaRengi,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 16.0),
                child: CircleAvatar(
                  backgroundColor: Colors.white.withOpacity(0.3),
                  child: IconButton(
                    icon: Icon(isReading ? Icons.stop_rounded : Icons.volume_up_rounded, color: Colors.white),
                    onPressed: _seslendir,
                  ),
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [widget.temaRengi, widget.temaRengi.withOpacity(0.5)],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 40, left: 0, right: 0,
                    child: Hero(
                      tag: widget.baslik,
                      child: widget.gorselYolu.startsWith("http")
                          ? Image.network(widget.gorselYolu, height: 180, fit: BoxFit.contain)
                          : Image.asset(widget.gorselYolu, height: 180, fit: BoxFit.contain),
                    ).animate().scale(duration: 600.ms, curve: Curves.bounceInOut),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Container(
              transform: Matrix4.translationValues(0, -30, 0),
              padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 40),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(40)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.baslik.toUpperCase(),
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      color: widget.temaRengi,
                      letterSpacing: 1.1,
                    ),
                  ).animate().fade().slideX(begin: -0.2),
                  const SizedBox(height: 10),
                  Container(height: 5, width: 60, decoration: BoxDecoration(color: widget.temaRengi.withOpacity(0.3), borderRadius: BorderRadius.circular(10))),
                  const SizedBox(height: 30),
                  Text(
                    widget.hikayeMetni,
                    style: TextStyle(
                      fontSize: 19,
                      height: 1.9,
                      color: Colors.blueGrey.shade900,
                      fontWeight: FontWeight.w500,
                      fontFamily: 'Roboto', // Varsa daha okunaklı bir font
                    ),
                  ).animate().fade(delay: 300.ms).slideY(begin: 0.1),
                  const SizedBox(height: 50),
                  _buildFeedbackCard(),
                  const SizedBox(height: 120),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomSheet: Container(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, -5))],
        ),
        child: ElevatedButton(
          onPressed: _hikayeyiBitir,
          style: ElevatedButton.styleFrom(
            backgroundColor: widget.temaRengi,
            minimumSize: const Size(double.infinity, 65),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            elevation: 8,
            shadowColor: widget.temaRengi.withOpacity(0.4),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.check_circle_outline_rounded, color: Colors.white),
              SizedBox(width: 10),
              Text(
                "OKUMAYI TAMAMLADIM",
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 1.1),
              ),
            ],
          ),
        ),
      ).animate().slideY(begin: 1.0, duration: 500.ms),
    );
  }

  Widget _buildFeedbackCard() {
    return Container(
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: widget.temaRengi.withOpacity(0.05),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: widget.temaRengi.withOpacity(0.2), width: 2),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb_circle_rounded, color: widget.temaRengi, size: 30),
              const SizedBox(width: 12),
              const Text("KAHRAMAN NOTU", style: TextStyle(fontWeight: FontWeight.w900, color: Colors.blueGrey, fontSize: 13, letterSpacing: 1.5)),
            ],
          ),
          const SizedBox(height: 15),
          Text(
            widget.feedbackMessage.isNotEmpty ? widget.feedbackMessage : "",
            style: const TextStyle(fontSize: 18, height: 1.5, fontStyle: FontStyle.italic, color: Colors.black87),
          ),
        ],
      ),
    ).animate().scale(delay: 1.seconds);
  }
}
