import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class AnalyticsService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> gorevTamamla({
    required String uid,
    required int puan,
    required String gorevId,
    required String gorevTipi, 
  }) async {
    try {
      final ref = _db.collection('usersProgress').doc(uid);
      
      String listeAdi = '';
      if (gorevTipi == 'senaryo') listeAdi = 'tamamlanan_bolumler';
      else if (gorevTipi == 'hikaye') listeAdi = 'okunan_hikayeler';
      else if (gorevTipi == 'video') listeAdi = 'izlenen_videolar';
      else if (gorevTipi == 'dedektif') listeAdi = 'bilinen_dedektif_sorulari';

      // Kazanılan puana göre becerileri orantısal/rastgele artır
      int eklenecekEmpati = (puan * 0.3).ceil() + (DateTime.now().millisecond % 3);
      int eklenecekDikkat = (puan * 0.4).ceil() + (DateTime.now().millisecond % 2);
      int eklenecekYardim = (puan * 0.3).ceil() + (DateTime.now().millisecond % 4);

      await ref.set({
        'toplam_puan': FieldValue.increment(puan),
        if (listeAdi.isNotEmpty) listeAdi: FieldValue.arrayUnion([gorevId]),
        'istatistikler': {
          'karar_yapisi': {
            'empati': FieldValue.increment(eklenecekEmpati),
            'dikkat': FieldValue.increment(eklenecekDikkat),
            'yardim': FieldValue.increment(eklenecekYardim),
          }
        },
        'sonGuncelleme': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      await rozetKontrolEt(uid);
    } catch (e) {
      debugPrint("Görev Tamamlama Hatası: $e");
    }
  }

  Future<void> bolumTamamla(String uid, int puan, String bolumId) async {
    await gorevTamamla(uid: uid, puan: puan, gorevId: bolumId, gorevTipi: 'senaryo');
  }

  Future<void> aktiviteGuncelle(String uid, int puan) async {
    // Genel aktiviteler veya dedektif oyunu puanları için
    await gorevTamamla(uid: uid, puan: puan, gorevId: 'aktivite_${DateTime.now().millisecondsSinceEpoch}', gorevTipi: 'genel');
  }

  Future<void> sureEkle(String uid, int dakika) async {
    try {
      await _db.collection('usersProgress').doc(uid).set({
        'istatistikler': {'toplam_sure_dk': FieldValue.increment(dakika)},
        'sonGuncelleme': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) { debugPrint("Süre Ekleme Hatası: $e"); }
  }


  Future<void> rozetKontrolEt(String uid) async {
    try {
      final progressRef = _db.collection('usersProgress').doc(uid);
      final snap = await progressRef.get();
      if (!snap.exists) return;

      final data = snap.data()!;
      final int mevcutPuan = data['toplam_puan'] ?? 0;
      final List bitti = data['tamamlanan_bolumler'] as List? ?? [];
      final List mevcutRozetler = data['rozetler'] as List? ?? [];

      final int bitenSenaryoSayisi = bitti.length;

      final badgesSnap = await _db.collection('badges').get();
      List<String> yeniKazanilanIds = [];

      for (var doc in badgesSnap.docs) {
        if (mevcutRozetler.contains(doc.id)) continue;

        final bData = doc.data();
        final String tip = bData['kriter_tipi']?.toString() ?? "";
        final dynamic hedef = bData['hedef_deger'];
        int hedefVal = (hedef is num) ? hedef.toInt() : (int.tryParse(hedef.toString()) ?? 999);

        bool sartSaglandi = false;
        if (tip == "puan" && mevcutPuan >= hedefVal) sartSaglandi = true;
        else if (tip == "senaryo_sayisi" && bitenSenaryoSayisi >= hedefVal) sartSaglandi = true;

        if (sartSaglandi) yeniKazanilanIds.add(doc.id);
      }

      if (yeniKazanilanIds.isNotEmpty) {
        await progressRef.update({
          'rozetler': FieldValue.arrayUnion(yeniKazanilanIds),
        });
      }
    } catch (e) {
      debugPrint("Rozet Sistemi Hatası: $e");
    }
  }

  Future<void> hataKaydet(String uid) async {
    try {
      await _db.collection('usersProgress').doc(uid).set({
        'istatistikler': {'hatali_cevaplar': FieldValue.increment(1)},
        'sonGuncelleme': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) { debugPrint("Hata Kaydetme Hatası: $e"); }
  }
}
