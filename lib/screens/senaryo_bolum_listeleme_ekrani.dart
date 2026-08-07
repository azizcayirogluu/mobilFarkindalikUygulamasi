import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:zorbalik_uygulamasi/app_theme.dart';
import 'senaryo_detay_ekrani.dart';

class SenaryoBolumListelemeEkrani extends StatefulWidget {
  final String docId;
  final String kategoriBaslik;

  const SenaryoBolumListelemeEkrani({super.key, required this.docId, required this.kategoriBaslik});

  @override
  State<SenaryoBolumListelemeEkrani> createState() => _SenaryoBolumListelemeEkraniState();
}

class _SenaryoBolumListelemeEkraniState extends State<SenaryoBolumListelemeEkrani> {
  final User? _currentUser = FirebaseAuth.instance.currentUser;
  late Stream<DocumentSnapshot> _userProgressStream;
  late Future<DocumentSnapshot> _userFuture;
  late Stream<DocumentSnapshot> _scenarioStream;

  @override
  void initState() {
    super.initState();
    if (_currentUser != null) {
      final uid = _currentUser!.uid;
      _userProgressStream = FirebaseFirestore.instance.collection('usersProgress').doc(uid).snapshots();
      _userFuture = FirebaseFirestore.instance.collection('users').doc(uid).get();
      _scenarioStream = FirebaseFirestore.instance.collection('scenarios').doc(widget.docId).snapshots();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_currentUser == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: AppColors.zemin,
      body: StreamBuilder<DocumentSnapshot>(
        // Kullanıcının ilerleme verilerini anlık olarak çeker
        stream: _userProgressStream,
        builder: (context, userProgressSnap) {
          List<String> tamamlananlar = [];
          if (userProgressSnap.hasData && userProgressSnap.data!.exists) {
            final userData = userProgressSnap.data!.data() as Map<String, dynamic>?;
            tamamlananlar = List<String>.from(userData?['tamamlanan_bolumler'] ?? []);
          }

          return FutureBuilder<DocumentSnapshot>(
            // Kullanıcının yaş grubunu öğrenmek için profil verisini çeker
              future: _userFuture,
              builder: (context, userSnap) {
                if (userSnap.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());

                String kullaniciYasGrubu = "6-12";
                if (userSnap.hasData && userSnap.data!.exists) {
                  kullaniciYasGrubu = (userSnap.data!.data() as Map<String, dynamic>)['yasGrubu'] ?? "6-12";
                }

                return StreamBuilder<DocumentSnapshot>(
                  // Seçilen kategoriye  ait bölümleri çeker
                  stream: _scenarioStream,
                  builder: (context, scenarioSnapshot) {
                    if (scenarioSnapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                    if (!scenarioSnapshot.hasData || !scenarioSnapshot.data!.exists) return const Center(child: Text("Görevler bulunamadı."));

                    var scenarioData = scenarioSnapshot.data!.data() as Map<String, dynamic>?;
                    List tumBolumler = scenarioData?['bolumler'] ?? [];

                    // Yaş Grubu Filtreleme:
                    List filtrelenmisBolumler = tumBolumler.where((bolum) {
                      List sorular = bolum['sorular'] ?? [];
                      return sorular.any((soru) => (soru['yasGrubu'] ?? "6-12") == kullaniciYasGrubu);
                    }).toList();

                    // Bu kategoriye ait bitirilen toplam bölüm sayısı
                    int buKategoriBitenSayisi = tamamlananlar.where((id) => id.startsWith("${widget.docId}_")).length;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildCleanHeader(context, buKategoriBitenSayisi),
                        Expanded(
                          child: filtrelenmisBolumler.isEmpty
                              ? _buildNoContentState()
                              : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(25, 20, 25, 100),
                            physics: const BouncingScrollPhysics(),
                            itemCount: filtrelenmisBolumler.length,
                            itemBuilder: (context, index) {
                              // Orijinal listedeki indexi bulur
                              int gercekIndex = tumBolumler.indexOf(filtrelenmisBolumler[index]);
                              String bId = "${widget.docId}_$gercekIndex";
                              bool bittiMi = tamamlananlar.contains(bId);

                              // Kilit Mantığı: İlk bölüm veya bir önceki bölüm tamamlanmışsa bu bölüm açılır
                              bool acikMi = index == 0 || tamamlananlar.contains("${widget.docId}_${tumBolumler.indexOf(filtrelenmisBolumler[index-1])}");
                              bool sonMu = index == filtrelenmisBolumler.length - 1;
                              bool suAnkiGorevMi = acikMi && !bittiMi;

                              // Bölümlerin liste akışında aşağıdan yukarıya süzülerek gelmesi için animasyon
                              return TweenAnimationBuilder<double>(
                                tween: Tween(begin: 0.0, end: 1.0),
                                duration: Duration(milliseconds: 300 + (index * 100)),
                                curve: Curves.easeOutCubic,
                                builder: (context, value, child) {
                                  return Opacity(
                                    opacity: value,
                                    child: Transform.translate(
                                      offset: Offset(0, 30 * (1 - value)),
                                      child: _buildMissionStep(filtrelenmisBolumler[index], gercekIndex, acikMi, bittiMi, sonMu, suAnkiGorevMi),
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                        ),
                      ],
                    );
                  },
                );
              }
          );
        },
      ),
    );
  }

  // Uygun yaş grubunda içerik yoksa gösterilen ekran
  Widget _buildNoContentState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.auto_awesome_rounded, size: 80, color: Colors.blueGrey.withOpacity(0.3)),
          const SizedBox(height: 20),
          const Text("Henüz sana uygun görevimiz yok.\nÇok yakında burada olacak! 🛡️", textAlign: TextAlign.center, style: TextStyle(color: Colors.blueGrey, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  // Geri butonu ve bitirilen görev sayısını içeren üst alan
  Widget _buildCleanHeader(BuildContext context, int tamamlananSayisi) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: AppColors.yaziRengi),
                  onPressed: () => Navigator.pop(context),
                  style: IconButton.styleFrom(backgroundColor: AppColors.zemin, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                ),
                _buildScoreBadge(tamamlananSayisi),
              ],
            ),
            const SizedBox(height: 15),
            Text(widget.kategoriBaslik, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: AppColors.yaziRengi, letterSpacing: -0.5)),
            const Text("Görevlerini tamamla ve rütbeni yükselt.", style: TextStyle(fontSize: 13, color: Colors.grey, fontWeight: FontWeight.w500)),
            const SizedBox(height: 5),
          ],
        ),
      ),
    );
  }

  // Tamamlanan görev sayısını gösteren rozet
  Widget _buildScoreBadge(int tamamlananSayisi) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        gradient: AppColors.anaGradient,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: AppColors.anaMavi.withOpacity(0.2), blurRadius: 8, offset: const Offset(0, 4))],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.stars_rounded, color: Colors.amber, size: 18),
          const SizedBox(width: 6),
          Text("$tamamlananSayisi Görev Bitti", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
        ],
      ),
    );
  }

  // Listenin her bir adımını oluşturan tasarım
  Widget _buildMissionStep(dynamic bolum, int index, bool acik, bool bitti, bool sonMu, bool suAnkiGorevMi) {
    String? amac = bolum['bolumAmaci'];

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Yol Çizgisi ve İkon: Görevler arasındaki bağlantı çizgisini ve durum ikonunu çizer
          Column(
            children: [
              _buildMissionIcon(bitti, acik, suAnkiGorevMi),
              if (!sonMu)
                Expanded(
                  child: Container(
                    width: 2,
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: bitti ? Colors.green.withOpacity(0.3) : Colors.grey.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 15),
          Expanded(
            child: GestureDetector(
              onTap: acik ? () => Navigator.push(context, MaterialPageRoute(builder: (c) => SenaryoDetayEkrani(docId: widget.docId, bolumIndex: index))) : null,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.only(bottom: 25),
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: bitti ? Colors.green.withOpacity(0.2) : (suAnkiGorevMi ? AppColors.anaMavi.withOpacity(0.3) : Colors.transparent), width: 1.5),
                  boxShadow: [BoxShadow(color: suAnkiGorevMi ? AppColors.anaMavi.withOpacity(0.05) : Colors.black.withOpacity(0.02), blurRadius: 12, offset: const Offset(0, 6))],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("GÖREV ${index + 1}", style: TextStyle(color: acik ? AppColors.accentMavi : Colors.grey, fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: 1)),
                        if (bitti) const Icon(Icons.verified_rounded, color: Colors.green, size: 18),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(bolum['bolumAdi'] ?? "...", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 17, color: acik ? AppColors.yaziRengi : Colors.grey.shade400)),

                    // Bölüm Amacı: Eğer bölüm kilitli değilse kazanılacak yetkinliği gösterir
                    if (acik && amac != null && amac.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.anaMavi.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.track_changes_rounded, size: 14, color: AppColors.anaMavi),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                amac,
                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.blueGrey.shade700, fontStyle: FontStyle.italic),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    if (suAnkiGorevMi)
                      const Padding(padding: EdgeInsets.only(top: 8.0), child: Text("Hadi Başlayalım! 🚀", style: TextStyle(color: AppColors.anaMavi, fontSize: 11, fontWeight: FontWeight.bold))),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Görevin durumuna göre ikon tasarımı
  Widget _buildMissionIcon(bool bitti, bool acik, bool suAnkiGorevMi) {
    if (suAnkiGorevMi) {
      return Container(
        width: 42, height: 42,
        decoration: BoxDecoration(shape: BoxShape.circle, gradient: AppColors.anaGradient, boxShadow: [BoxShadow(color: AppColors.anaMavi.withOpacity(0.3), blurRadius: 10)]),
        child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 22),
      );
    }
    return Container(
      width: 42, height: 42,
      decoration: BoxDecoration(shape: BoxShape.circle, color: bitti ? Colors.green : Colors.white, border: Border.all(color: bitti ? Colors.green : Colors.grey.shade300, width: 2)),
      child: Icon(bitti ? Icons.check_rounded : Icons.lock_outline_rounded, color: bitti ? Colors.white : Colors.grey.shade400, size: 18),
    );
  }
}