import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:zorbalik_uygulamasi/app_theme.dart';
import 'package:zorbalik_uygulamasi/screens/hikaye_detay_ekrani.dart';

class HikayeListelemeEkrani extends StatelessWidget {
  const HikayeListelemeEkrani({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.zemin,
      appBar: AppBar(
        title: const Text("EĞİTİCİ HİKAYELER", 
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: AppColors.yaziRengi)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.yaziRengi),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('stories').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("Henüz hikaye eklenmemiş."));
          }

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 100),
            physics: const BouncingScrollPhysics(),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var doc = snapshot.data!.docs[index];
              var data = doc.data() as Map<String, dynamic>;
              return _buildStoryCard(context, data, index);
            },
          );
        },
      ),
    );
  }

  Widget _buildStoryCard(BuildContext context, Map<String, dynamic> data, int index) {
    List<Color> renkler = [Colors.orangeAccent, Colors.blueAccent, Colors.purpleAccent];
    Color anaRenk = renkler[index % renkler.length];

    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [BoxShadow(color: anaRenk.withOpacity(0.1), blurRadius: 15, offset: const Offset(0, 8))],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(25),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (c) => HikayeDetayEkrani(
              baslik: data['baslik'] ?? "Eğitici Öykü",
              gorselYolu: data['gorselYolu'] ?? "assets/books.png",
              temaRengi: anaRenk,
              hikayeMetni: data['hikayeMetni'] ?? data['icerik'] ?? "",
            ),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Row(
            children: [
              Container(
                width: 80, height: 80,
                decoration: BoxDecoration(
                  color: anaRenk.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(Icons.auto_stories_rounded, color: anaRenk, size: 35),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(data['baslik'] ?? "İsimsiz Hikaye",
                        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 17, color: AppColors.yaziRengi)),
                    const SizedBox(height: 4),
                    Text("Okumak ve öğrenmek için dokun",
                        style: TextStyle(color: Colors.grey.shade500, fontSize: 12, fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios_rounded, color: anaRenk.withOpacity(0.3), size: 18),
            ],
          ),
        ),
      ),
    );
  }
}
