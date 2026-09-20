import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../utils/app_logger.dart';

class AnalyticsService {
  final FirebaseFunctions _functions = FirebaseFunctions.instanceFor(
    region: 'europe-west1',
  );

  /// Görevi tamamlar ve puanı/rozetleri sunucu tarafında doğrulanmış şekilde işler.
  Future<void> gorevTamamla({
    required String uid,
    required String gorevId,
    required String gorevTipi,
    dynamic
    verificationData, // KANIT: Senaryo için cevaplar, Dedektif için kararlar
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      debugPrint("AnalyticsService: Kullanıcı oturum açmamış! (UID: $uid)");
      throw Exception("Oturum bulunamadı.");
    }

    try {
      // Sadece "senaryo" ve "dedektif" görevleri Cloud Function çağırır (Puan kazanır).
      if (gorevTipi == 'senaryo' || gorevTipi == 'dedektif') {
        debugPrint("Bulut fonksiyonu çağrılıyor: completeTask ($gorevId)");

        final result = await _functions.httpsCallable('completeTask').call({
          'taskId': gorevId,
          'taskType': gorevTipi,
          'proof': verificationData ?? [],
        });

        if (kDebugMode) debugPrint("Görev tamamlandı sonucu: ${result.data}");
      } else {
        // Hikaye ve Video için sadece ilerleme listesi güncellenir, puan verilmez.
        String? listeAdi;
        if (gorevTipi == 'hikaye') {
          listeAdi = 'okunan_hikayeler';
        } else if (gorevTipi == 'video') {
          listeAdi = 'izlenen_videolar';
        }

        if (listeAdi != null) {
          await FirebaseFirestore.instance
              .collection('usersProgress')
              .doc(uid)
              .update({
                listeAdi: FieldValue.arrayUnion([gorevId]),
                'sonGuncelleme': FieldValue.serverTimestamp(),
              });
          if (kDebugMode)
            debugPrint("İlerleme kaydedildi (Puan verilmedi): $gorevId");
        }
      }
    } on FirebaseFunctionsException catch (e, stack) {
      AppLogger.error("Görev İşleme Hatası (Functions)", e, stack);
      // Eğer unauthenticated hatası alıyorsak token yenilemeyi deneyebiliriz
      if (e.code == 'unauthenticated') {
        debugPrint("Oturum hatası tespit edildi, token yenileniyor...");
        await user.getIdToken(true);
      }
      rethrow;
    } catch (e, stack) {
      AppLogger.error("Görev İşleme Hatası (Genel)", e, stack);
      rethrow;
    }
  }

  Future<void> bolumTamamla(
    String uid,
    int ignoredPuan,
    String bolumId, {
    dynamic proof,
  }) async {
    await gorevTamamla(
      uid: uid,
      gorevId: bolumId,
      gorevTipi: 'senaryo',
      verificationData: proof,
    );
  }

  Future<void> aktiviteGuncelle(
    String uid,
    int ignoredPuan, {
    dynamic proof,
  }) async {
    // Dedektif oyunu için Cloud Function üzerinden puanlı işlem yapılır.
    await gorevTamamla(
      uid: uid,
      gorevId: 'dedektif_oyunu',
      gorevTipi: 'dedektif',
      verificationData: proof,
    );
  }

  Future<void> sureEkle(String uid, int dakika) async {
    try {
      // Audit CRIT-02 Fix: Use dot notation to avoid overwriting nested 'karar_yapisi'
      await FirebaseFirestore.instance
          .collection('usersProgress')
          .doc(uid)
          .update({
            'istatistikler.toplam_sure_dk': FieldValue.increment(dakika),
            'sonGuncelleme': FieldValue.serverTimestamp(),
          });
    } catch (e) {
      debugPrint("Süre Ekleme Hatası: $e");
    }
  }

  Future<void> hataKaydet(String uid) async {
    try {
      // Audit CRIT-02 Fix: Use dot notation to avoid overwriting nested 'karar_yapisi'
      await FirebaseFirestore.instance
          .collection('usersProgress')
          .doc(uid)
          .update({
            'istatistikler.hatali_cevaplar': FieldValue.increment(1),
            'sonGuncelleme': FieldValue.serverTimestamp(),
          });
    } catch (e) {
      debugPrint("Hata Kaydetme Hatası: $e");
    }
  }
}
