import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:zorbalik_uygulamasi/app_theme.dart';
import 'package:flutter_animate/flutter_animate.dart';
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

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        body: StreamBuilder<DocumentSnapshot>(
        stream: _userProgressStream,
        builder: (context, userProgressSnap) {
          List<String> tamamlananlar = [];
          if (userProgressSnap.hasData && userProgressSnap.data!.exists) {
            final userData = userProgressSnap.data!.data() as Map<String, dynamic>?;
            tamamlananlar = List<String>.from(userData?['tamamlanan_bolumler'] ?? []);
          }

          return FutureBuilder<DocumentSnapshot>(
              future: _userFuture,
              builder: (context, userSnap) {
                if (userSnap.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());

                String kullaniciYasGrubu = "6-12";
                if (userSnap.hasData && userSnap.data!.exists) {
                  kullaniciYasGrubu = (userSnap.data!.data() as Map<String, dynamic>)['yasGrubu'] ?? "6-12";
                }

                return StreamBuilder<DocumentSnapshot>(
                  stream: _scenarioStream,
                  builder: (context, scenarioSnapshot) {
                    if (scenarioSnapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                    if (!scenarioSnapshot.hasData || !scenarioSnapshot.data!.exists) return const Center(child: Text("Görevler bulunamadı."));

                    var scenarioData = scenarioSnapshot.data!.data() as Map<String, dynamic>?;
                    List tumBolumler = scenarioData?['bolumler'] ?? [];

                    List filtrelenmisBolumler = tumBolumler.where((bolum) {
                      List sorular = bolum['sorular'] ?? [];
                      return sorular.any((soru) => (soru['yasGrubu'] ?? "6-12") == kullaniciYasGrubu);
                    }).toList();

                    int buKategoriBitenSayisi = tamamlananlar.where((id) => id.startsWith("${widget.docId}_")).length;

                    return Column(
                      children: [
                        _buildHeader(context, buKategoriBitenSayisi),
                        Expanded(
                          child: filtrelenmisBolumler.isEmpty
                              ? _buildEmptyState()
                              : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(25, 20, 25, 120),
                            physics: const BouncingScrollPhysics(),
                            itemCount: filtrelenmisBolumler.length,
                            itemBuilder: (context, index) {
                              int gercekIndex = tumBolumler.indexOf(filtrelenmisBolumler[index]);
                              String bId = "${widget.docId}_$gercekIndex";
                              bool bittiMi = tamamlananlar.contains(bId);

                              bool acikMi = index == 0 || tamamlananlar.contains("${widget.docId}_${tumBolumler.indexOf(filtrelenmisBolumler[index-1])}");
                              bool sonMu = index == filtrelenmisBolumler.length - 1;
                              bool suAnkiGorevMi = acikMi && !bittiMi;

                              return _buildMissionStep(filtrelenmisBolumler[index], gercekIndex, acikMi, bittiMi, sonMu, suAnkiGorevMi)
                                  .animate(delay: (index * 30).ms)
                                  .fadeIn(duration: 300.ms)
                                  .slideY(begin: 0.05, curve: Curves.easeOutQuad);
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
    ),
  );
}

  Widget _buildHeader(BuildContext context, int tamamlananSayisi) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 15, 20, 25),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: Color(0xFF475569)),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                _buildScoreBadge(tamamlananSayisi),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              widget.kategoriBaslik,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w900,
                color: Color(0xFF1E293B),
                letterSpacing: -0.5,
              ),
            ),
            const Text(
              "Görevlerini tamamla ve kahramanlığını kanıtla! 🛡️",
              style: TextStyle(
                fontSize: 13,
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScoreBadge(int count) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF6366F1), Color(0xFF4F46E5)]),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6366F1).withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.stars_rounded, color: Colors.amber, size: 18),
          const SizedBox(width: 8),
          Text(
            "$count Görev Bitti",
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildMissionStep(dynamic bolum, int index, bool acik, bool bitti, bool sonMu, bool suAnkiGorevMi) {
    String? amac = bolum['bolumAmaci'];

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              _buildMissionIcon(bitti, acik, suAnkiGorevMi),
              if (!sonMu)
                Expanded(
                  child: Container(
                    width: 3,
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: bitti ? const Color(0xFF10B981).withOpacity(0.3) : const Color(0xFFE2E8F0),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 18),
          Expanded(
            child: GestureDetector(
              onTap: acik ? () => Navigator.push(context, MaterialPageRoute(builder: (c) => SenaryoDetayEkrani(docId: widget.docId, bolumIndex: index))) : null,
              child: Container(
                margin: const EdgeInsets.only(bottom: 25),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: bitti ? const Color(0xFF10B981).withOpacity(0.2) : (suAnkiGorevMi ? const Color(0xFF6366F1).withOpacity(0.2) : Colors.transparent),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "GÖREV ${index + 1}",
                          style: TextStyle(
                            color: acik ? const Color(0xFF6366F1) : const Color(0xFF94A3B8),
                            fontWeight: FontWeight.w900,
                            fontSize: 10,
                            letterSpacing: 1.5,
                          ),
                        ),
                        if (bitti) const Icon(Icons.verified_rounded, color: Color(0xFF10B981), size: 20),
                        if (!acik) const Icon(Icons.lock_rounded, color: Color(0xFFCBD5E1), size: 16),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      bolum['bolumAdi'] ?? "...",
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                        color: acik ? const Color(0xFF1E293B) : const Color(0xFF94A3B8),
                        height: 1.2,
                      ),
                    ),
                    if (acik && amac != null && amac.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.auto_awesome_rounded, size: 14, color: Color(0xFF6366F1)),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                amac,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF475569),
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    if (suAnkiGorevMi)
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Row(
                          children: [
                            const Text(
                              "Hadi Başlayalım! 🚀",
                              style: TextStyle(
                                color: Color(0xFF6366F1),
                                fontSize: 12,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMissionIcon(bool bitti, bool acik, bool suAnkiGorevMi) {
    if (suAnkiGorevMi) {
      return Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(colors: [Color(0xFF6366F1), Color(0xFF4F46E5)]),
          boxShadow: [BoxShadow(color: const Color(0xFF6366F1).withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4))],
        ),
        child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 24),
      );
    }
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: bitti ? const Color(0xFF10B981) : Colors.white,
        border: Border.all(
          color: bitti ? const Color(0xFF10B981) : const Color(0xFFE2E8F0),
          width: 3,
        ),
      ),
      child: Icon(
        bitti ? Icons.check_rounded : Icons.lock_outline_rounded,
        color: bitti ? Colors.white : const Color(0xFF94A3B8),
        size: 20,
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(30),
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.rocket_launch_rounded, size: 60, color: const Color(0xFFCBD5E1)),
          ),
          const SizedBox(height: 24),
          const Text(
            "Yolculuk Hazırlanıyor!",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: Color(0xFF475569),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            "Sana uygun görevler çok yakında burada olacak.",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF94A3B8),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ).animate().fadeIn().scale(begin: const Offset(0.9, 0.9)),
    );
  }
}
