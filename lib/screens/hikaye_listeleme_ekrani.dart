import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:zorbalik_uygulamasi/app_theme.dart';
import 'package:zorbalik_uygulamasi/screens/hikaye_detay_ekrani.dart';
import 'package:flutter_animate/flutter_animate.dart';

class HikayeListelemeEkrani extends StatelessWidget {
  const HikayeListelemeEkrani({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9), // Daha modern, açık bir zemin
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text("KAHRAMANLIK ÖYKÜLERİ",
            style: TextStyle(fontSize: 18, color: Color(0xFF4A90E2), letterSpacing: 1.5)),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF1E293B)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('stories').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppColors.anaMavi));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return _buildEmptyState();
          }

          return GridView.builder(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2, // Çocuklar için daha keşif odaklı 2'li grid
              crossAxisSpacing: 15,
              mainAxisSpacing: 15,
              childAspectRatio: 0.85,
            ),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var data = snapshot.data!.docs[index].data() as Map<String, dynamic>;
              return _buildHeroCard(context, data, index)
                  .animate(delay: (index * 15).ms)
                  .fadeIn(duration: 300.ms)
                  .slideY(begin: 0.05, curve: Curves.easeOutQuad);
            },
          );
        },
      ),
    );
  }

  Widget _buildHeroCard(BuildContext context, Map<String, dynamic> data, int index) {
    // Çocukların dikkatini çekecek canlı renk paleti
    List<Color> kartRenkleri = [
      const Color(0xFFFF9F1C), const Color(0xFF2EC4B6),
      const Color(0xFFE71D36), const Color(0xFF3A86FF)
    ];
    Color renk = kartRenkleri[index % kartRenkleri.length];

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (c) => HikayeDetayEkrani(
            feedbackMessage: data['feedbackMessage'] ?? "",
            baslik: data['baslik'] ?? "Eğitici Öykü",
            gorselYolu: data['gorselYolu'] ?? "assets/image/books.png",
            temaRengi: renk,
            hikayeMetni: data['hikayeMetni'] ?? data['icerik'] ?? "",
          ),
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [BoxShadow(color: renk.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 5))],
        ),
        child: Column(
          children: [
            Expanded(
              flex: 3,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(color: renk.withOpacity(0.1), borderRadius: const BorderRadius.vertical(top: Radius.circular(30))),
                child: Icon(Icons.auto_stories_rounded, size: 50, color: renk),
              ),
            ),
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  data['baslik'] ?? "Macera Başlıyor",
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: Color(0xFF334155)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.menu_book_rounded, size: 80, color: Colors.grey),
          const SizedBox(height: 20),
          Text("Henüz bir hikaye yok.\nKütüphanemiz hazırlanıyor!",
              textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}