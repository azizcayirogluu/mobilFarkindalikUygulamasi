import 'package:cloud_firestore/cloud_firestore.dart';

class AnalyticsService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Kullanıcının toplam puanını ve son işlem tarihini günceller.
  /// 'SetOptions(merge: true)' sayesinde doküman veya alan yoksa otomatik oluşturulur.
  Future<void> aktiviteGuncelle(String uid, int eklenenPuan) async {
    try {
      await _db.collection('usersProgress').doc(uid).set({
        'toplam_puan': FieldValue.increment(eklenenPuan),
        'sonGuncelleme': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      print("Başarı: Puan ve aktivite güncellendi.");
    } catch (e) {
      print("Analytics Error (aktiviteGuncelle): $e");
    }
  }

  /// Kullanıcının yaptığı hatalı seçim sayısını takip eder.
  /// 'istatistikler' haritası (Map) yoksa otomatik olarak oluşturulur.
  Future<void> hataKaydet(String uid) async {
    try {
      await _db.collection('usersProgress').doc(uid).set({
        'istatistikler': {
          'hatali_cevaplar': FieldValue.increment(1),
        },
        'sonGuncelleme': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      print("Başarı: Hata istatistiği kaydedildi.");
    } catch (e) {
      print("Analytics Error (hataKaydet): $e");
    }
  }

  /// Uygulamada geçirilen süreyi (dakika) kullanıcı profiline ekler.
  /// Admin panelindeki 'Toplam Eğitim Süresi' grafiğini bu veri besler.
  Future<void> sureEkle(String uid, int dakika) async {
    try {
      await _db.collection('usersProgress').doc(uid).set({
        'istatistikler': {
          'toplam_sure_dk': FieldValue.increment(dakika),
        },
        'sonGuncelleme': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      print("Başarı: Süre istatistiği kaydedildi.");
    } catch (e) {
      print("Analytics Error (sureEkle): $e");
    }
  }

  /// Kullanıcının karakter eğilimlerini (Empati, Cesaret, Dikkat vb.) günceller.
  /// Bu veriler Admin Panelindeki 'Karakter Gelişim Analizi' bar grafiklerini besler.
  Future<void> karakterPuaniEkle(String uid, String tip, int puan) async {
    try {
      await _db.collection('usersProgress').doc(uid).set({
        'istatistikler': {
          'karar_yapisi': {
            tip: FieldValue.increment(puan),
          }
        },
        'sonGuncelleme': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      print("Başarı: Karakter puanı ($tip) güncellendi.");
    } catch (e) {
      print("Analytics Error (karakterPuaniEkle): $e");
    }
  }
}