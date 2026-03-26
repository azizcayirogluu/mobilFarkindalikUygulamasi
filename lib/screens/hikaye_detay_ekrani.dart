import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:zorbalik_uygulamasi/app_theme.dart';

import '../services/analytics_service.dart';

class HikayeDetayEkrani extends StatefulWidget {
  final String baslik;
  final String gorselYolu;
  final Color temaRengi;
  final String hikayeMetni;

  const HikayeDetayEkrani({
    super.key,
    required this.baslik,
    required this.gorselYolu,
    required this.temaRengi,
    required this.hikayeMetni,
  });

  @override
  State<HikayeDetayEkrani> createState() => _HikayeDetayEkraniState();
}

class _HikayeDetayEkraniState extends State<HikayeDetayEkrani> {
  final FlutterTts flutterTts = FlutterTts();
  bool isReading = false;
  final User? _currentUser = FirebaseAuth.instance.currentUser;

  @override
  void dispose() {
    flutterTts.stop();
    super.dispose();
  }

  Future<void> _hikayeyiBitir() async {
    // 1. Kullanıcı Kontrolü
    if (_currentUser == null) {
      debugPrint("Hata: Kullanıcı bulunamadı.");
      return;
    }

    final String uid = _currentUser!.uid;
    final docRef = FirebaseFirestore.instance.collection('usersProgress').doc(uid);

    try {
      // 2. İstatistiklere Süre Ekleme (AnalyticsService sömürülüyor)
      // Her hikaye bitirme işlemi veritabanına +2 dakika eğitim süresi yazar.
      await AnalyticsService().sureEkle(uid, 2);

      // 3. Puan ve İlerleme Güncelleme (Transaction ile güvenli işlem)
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        DocumentSnapshot snapshot = await transaction.get(docRef);

        if (!snapshot.exists) {
          // Doküman yoksa (Yeni kullanıcı ilk kez hikaye okuyorsa)
          transaction.set(docRef, {
            'uid': uid,
            'okunan_hikayeler': [widget.baslik],
            'toplam_puan': 10,
            'sonGuncelleme': FieldValue.serverTimestamp(),
            'istatistikler': {
              'hatali_cevaplar': 0,
              'toplam_sure_dk': 2,
            }
          });
        } else {
          // Doküman varsa mevcut verileri çek
          var data = snapshot.data() as Map<String, dynamic>;
          List okunanlar = data['okunan_hikayeler'] as List? ?? [];

          // Eğer bu hikaye daha önce okunmadıysa puan ver
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

      // 4. Kullanıcıya Geri Bildirim ve Ekrandan Çıkış
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Harika! Hikayeyi bitirdin ve 10 puan kazandın! 🌟"),
            backgroundColor: AppColors.basariYesili,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context); // Hikaye detayından listeye geri dön
      }
    } catch (e) {
      debugPrint("Firestore hatası: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Bir hata oluştu, ilerlemen kaydedilemedi.")),
        );
      }
    }
  }

  Future<void> _seslendir() async {
    if (isReading) {
      await flutterTts.stop();
      setState(() => isReading = false);
    } else {
      await flutterTts.setLanguage("tr-TR");
      await flutterTts.setPitch(1.0);
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
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            expandedHeight: 240,
            pinned: true,
            elevation: 0,
            backgroundColor: widget.temaRengi,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [widget.temaRengi, widget.temaRengi.withOpacity(0.7)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: Center(
                  child: Hero(
                    tag: widget.baslik,
                    child: widget.gorselYolu.startsWith("http")
                        ? Image.network(widget.gorselYolu, height: 180, fit: BoxFit.contain)
                        : Image.asset(widget.gorselYolu, height: 180, fit: BoxFit.contain),
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 30),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(35)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          widget.baslik,
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF2D3142),
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: _seslendir,
                        child: CircleAvatar(
                          backgroundColor: widget.temaRengi.withOpacity(0.1),
                          radius: 25,
                          child: Icon(
                            isReading ? Icons.stop_rounded : Icons.play_arrow_rounded,
                            color: widget.temaRengi,
                            size: 35,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Divider(color: widget.temaRengi.withOpacity(0.2), thickness: 2),
                  const SizedBox(height: 20),
                  Text(
                    widget.hikayeMetni,
                    style: const TextStyle(
                      fontSize: 18,
                      height: 1.8,
                      color: Colors.black87,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 120),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomSheet: Container(
        padding: const EdgeInsets.all(20),
        color: Colors.white,
        child: ElevatedButton(
          onPressed: _hikayeyiBitir,
          style: ElevatedButton.styleFrom(
            backgroundColor: widget.temaRengi,
            minimumSize: const Size(double.infinity, 65),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            elevation: 5,
            shadowColor: widget.temaRengi.withOpacity(0.4),
          ),
          child: const Text(
            "OKUMAYI TAMAMLADIM 🌟",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
          ),
        ),
      ),
    );
  }
}