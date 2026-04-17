import 'package:cloud_firestore/cloud_firestore.dart';

class AnalyticsService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  //Kullanıcının toplam puanını ve son işlem tarihini güncelle
  // 'SetOptions(merge: true)' sayesinde doküman veya alan yoksa otomatik oluştur
  Future<void> aktiviteGuncelle(String uid, int eklenenPuan) async {
    try {
      // Veri yoksa oluşturur, varsa sadece belirtilen alanları güncelle
      await _db.collection('usersProgress').doc(uid).set({
        // ATOMİK ARTIŞ: Veriyi çekip 1 ekleyip tekrar göndermek yerine,
        // sunucu tarafında güvenli bir şekilde artış yapılmasını sağlar.
        'toplam_puan': FieldValue.increment(eklenenPuan),
        // SERVER TIMESTAMP: Cihazın saati yerine Firebase sunucusunun güncel saatini kullan
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
        // 'istatistikler' Map'i içindeki spesifik bir alanı günceller.
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

  // Kullanıcının uygulama veya video başında geçirdiği süreyi dakika cinsinden biriktirir.
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

  // Örneğin: 'nazik', 'kararlı' veya 'yardımsever' gibi farklı kategorilerde puan biriktirir.
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