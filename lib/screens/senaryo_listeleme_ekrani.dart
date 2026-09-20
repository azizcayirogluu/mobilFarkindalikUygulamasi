import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        toolbarHeight: 90,
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: const Padding(
          padding: EdgeInsets.only(top: 25),
          child: Text(
            "Kahramanlık Görevleri",
            style: TextStyle(
              color: Color(0xFF1E293B),
              fontWeight: FontWeight.w900,
              fontSize: 22,
              letterSpacing: -0.5,
            ),
          ),
        ),
        leading: Padding(
          padding: const EdgeInsets.only(left: 16, top: 25),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.indigo.withOpacity(0.06),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: IconButton(
              icon: const Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 18,
                color: Color(0xFF475569),
              ),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ),
      ),
      body: _uid == null || _userFuture == null
        ? const Center(child: Text("Lütfen giriş yapın."))
        : FutureBuilder<DocumentSnapshot>(
            future: _userFuture,
            builder: (context, userSnap) {
              if (userSnap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              String kullaniciYasGrubu = "6-12";
              if (userSnap.hasData && userSnap.data!.exists) {
                final userData = userSnap.data!.data() as Map<String, dynamic>;
                kullaniciYasGrubu = userData['yasGrubu'] ?? "6-12";
              }

              return StreamBuilder<QuerySnapshot>(
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
                    return _buildEmptyState(kullaniciYasGrubu);
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 10, 20, 100),
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
      const Color(0xFF6366F1), 
      const Color(0xFFEC4899), 
      const Color(0xFFF59E0B), 
      const Color(0xFF10B981)
    ];
    final Color anaRenk = renkler[index % renkler.length];

    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 15,
            offset: const Offset(0, 8),
          )
        ],
        border: Border.all(color: const Color(0xFFF1F5F9), width: 1.5),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => Navigator.push(
            context, 
            MaterialPageRoute(
              builder: (c) => SenaryoBolumListelemeEkrani(docId: docId, kategoriBaslik: baslik)
            )
          ),
          borderRadius: BorderRadius.circular(28),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  width: 65,
                  height: 65,
                  decoration: BoxDecoration(
                    color: anaRenk.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(Icons.psychology_alt_rounded, color: anaRenk, size: 32),
                ),
                const SizedBox(width: 18),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        baslik,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w900, 
                          fontSize: 18, 
                          color: Color(0xFF1E293B),
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Görevleri keşfetmek için dokun",
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.blueGrey.shade300, 
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(Icons.arrow_forward_ios_rounded, color: anaRenk.withOpacity(0.3), size: 14),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(String yasGrubu) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.indigo.withOpacity(0.05),
                  blurRadius: 20,
                ),
              ],
            ),
            child: const Icon(Icons.rocket_launch_rounded, size: 60, color: Color(0xFFCBD5E1)),
          ),
          const SizedBox(height: 24),
          Text(
            "$yasGrubu Yaş İçin Hazırlık!",
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: Color(0xFF475569),
            ),
          ),
          const SizedBox(height: 8),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              "Bu yaş grubuna özel yeni maceralar çok yakında burada olacak.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF94A3B8),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ).animate().fadeIn().scale(begin: const Offset(0.9, 0.9)),
    );
  }
}
