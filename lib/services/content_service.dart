import 'package:cloud_firestore/cloud_firestore.dart';

class ContentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<Map<String, dynamic>> fetchDiscoveryData() async {
    int toplamBolumler = 0;
    int toplamHikayeler = 0;

    final results = await Future.wait([
      _firestore.collection('scenarios').get(),
      _firestore.collection('stories').get(),
      _firestore.collection('videos').limit(5).get(),
    ]);

    final sSnap = results[0];
    final hSnap = results[1];
    final vSnap = results[2];

    List<Map<String, dynamic>> senaryoOnerileri = [];
    for (var d in sSnap.docs) {
      final data = d.data();
      final bolumler = (data['bolumler'] as List?) ?? [];
      toplamBolumler += bolumler.length;
      
      if (senaryoOnerileri.length < 5) {
        senaryoOnerileri.add({
          "id": d.id, 
          "tip": "SENARYO", 
          "baslik": data['baslik'] ?? "Senaryo",
          "altBaslik": data['altBaslik'] ?? "Kararlarınla yönet.",
          "renkStr": data['renk'], 
          "ikonStr": data['ikon'], 
          "data": data,
        });
      }
    }

    toplamHikayeler = hSnap.docs.length;
    List<Map<String, dynamic>> hikayeOnerileri = [];
    for (var d in hSnap.docs.take(5)) {
      final data = d.data();
      hikayeOnerileri.add({
        "id": d.id, 
        "tip": "HİKAYE", 
        "baslik": data['baslik'] ?? "Hikaye",
        "altBaslik": data['altBaslik'] ?? "Gerçek deneyimler.",
        "renkStr": data['renk'] ?? "0xFFFFB74D", 
        "ikonStr": "auto_stories", 
        "data": data,
      });
    }

    List<Map<String, dynamic>> videoOnerileri = [];
    for (var d in vSnap.docs) {
      final data = d.data();
      videoOnerileri.add({
        "id": d.id, 
        "tip": "VİDEO", 
        "baslik": data['baslik'] ?? "Video",
        "altBaslik": data['altBaslik'] ?? "İzle ve öğren.",
        "renkStr": data['renk'] ?? "0xFFE57373", 
        "ikonStr": "play", 
        "data": data,
      });
    }

    List<Map<String, dynamic>> finalHavuz = [...senaryoOnerileri, ...hikayeOnerileri, ...videoOnerileri];
    finalHavuz.shuffle();

    return {
      'toplamGorevSayisi': toplamBolumler + toplamHikayeler,
      'kesifHavuzu': finalHavuz.take(4).toList(),
    };
  }

  Stream<DocumentSnapshot> getUserProgressStream(String uid) {
    return _firestore.collection('usersProgress').doc(uid).snapshots();
  }
}
