import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:zorbalik_uygulamasi/app_theme.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'senaryo_bolum_listeleme_ekrani.dart';

class SenaryoListelemeEkrani extends StatefulWidget {
  const SenaryoListelemeEkrani({super.key});

  @override
  State<SenaryoListelemeEkrani> createState() => _SenaryoListelemeEkraniState();
}

class _SenaryoListelemeEkraniState extends State<SenaryoListelemeEkrani> {
  final String? _uid = FirebaseAuth.instance.currentUser?.uid;
  Future<DocumentSnapshot>? _userFuture;

  @override
  void initState() {
    super.initState();
    if (_uid != null) {
      _userFuture = FirebaseFirestore.instance.collection('users').doc(_uid).get();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.zemin,
      appBar: AppBar(
        title: const Text("SENARYOLAR", 
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: AppColors.anaMavi , letterSpacing: 1.5)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.yaziRengi, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _uid == null || _userFuture == null
        ? const Center(child: Text("Lütfen giriş yapın."))
        : FutureBuilder<DocumentSnapshot>(
            // Önce kullanıcının yaş grubunu öğreniyoruz
            future: _userFuture,
            builder: (context, userSnap) {
              if (userSnap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              String kullaniciYasGrubu = "6-12"; // Varsayılan değer
              if (userSnap.hasData && userSnap.data!.exists) {
                final userData = userSnap.data!.data() as Map<String, dynamic>;
                kullaniciYasGrubu = userData['yasGrubu'] ?? "6-12";
              }

              return StreamBuilder<QuerySnapshot>(
                // Sorguya yaş grubu filtresini ekledik
                stream: FirebaseFirestore.instance
                    .collection('scenarios')
                    .where('yasGrubu', isEqualTo: kullaniciYasGrubu)
                    .limit(20)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.sentiment_neutral_rounded, size: 60, color: Colors.grey.shade400),
                          const SizedBox(height: 15),
                          Text("$kullaniciYasGrubu yaş grubu için henüz senaryo eklenmemiş.", 
                            style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
                    physics: const BouncingScrollPhysics(),
                    itemCount: snapshot.data!.docs.length,
                    itemBuilder: (context, index) {
                      var doc = snapshot.data!.docs[index];
                      var data = doc.data() as Map<String, dynamic>;
                      return _buildModernScenarioCard(context, data['baslik'] ?? "İsimsiz", doc.id, index)
                          .animate(delay: (index * 15).ms)
                          .fadeIn(duration: 300.ms)
                          .slideY(begin: 0.05, curve: Curves.easeOutQuad);
                    },
                  );
                },
              );
            },
          ),
    );
  }

  Widget _buildModernScenarioCard(BuildContext context, String baslik, String docId, int index) {
    final List<Color> renkler = [
      const Color(0xFF64B5F6), 
      const Color(0xFF9575CD), 
      const Color(0xFFFFB74D), 
      const Color(0xFF4DB6AC)
    ];
    final Color anaRenk = renkler[index % renkler.length];

    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: anaRenk.withOpacity(0.12),
            blurRadius: 15,
            offset: const Offset(0, 8),
          )
        ],
        border: Border.all(color: anaRenk.withOpacity(0.15), width: 1.5),
      ),
      child: InkWell(
        onTap: () => Navigator.push(
          context, 
          MaterialPageRoute(
            builder: (c) => SenaryoBolumListelemeEkrani(docId: docId, kategoriBaslik: baslik)
          )
        ),
        borderRadius: BorderRadius.circular(25),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
          child: Row(
            children: [
              Container(
                width: 65,
                height: 65,
                decoration: BoxDecoration(
                  color: anaRenk.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(Icons.psychology_alt_rounded, color: anaRenk, size: 34),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      baslik,
                      style: const TextStyle(
                        fontWeight: FontWeight.w900, 
                        fontSize: 18, 
                        color: AppColors.anaMavi,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Görevleri keşfetmek için dokun",
                      style: TextStyle(
                        color: Colors.grey.shade500, 
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

              Icon(Icons.arrow_forward_ios_rounded, color: anaRenk.withOpacity(0.4), size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
