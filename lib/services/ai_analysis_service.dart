import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../core/ai/offline_ai_engine.dart';

class AiAnalysisService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final OfflineAIEngine _offlineEngine = OfflineAIEngine();

  // Cloud Function referansı (API anahtarı sunucuda)
  final HttpsCallable _analysisFn =
      FirebaseFunctions.instanceFor(region: 'europe-west1')
          .httpsCallable('geminiAnalysis');

  // Kullanıcının hata kayıtlarını Firestore'a ekler
  Future<void> logMistake(String uid, String mistake) async {
    try {
      // update yerine set + merge kullanıyoruz, böylece doküman yoksa bile hata almaz.
      await _firestore.collection('usersProgress').doc(uid).set({
        'son_hatalar': FieldValue.arrayUnion([mistake]),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint("Hata kaydedilemedi: $e");
    }
  }

  // Son hataları getirir
  Future<List<String>> getMistakes(String uid) async {
    try {
      // GetOptions(source: Source.serverAndCache) kullanarak çevrimdışıyken cache'den okumasına izin verdik
      final doc =
          await _firestore.collection('usersProgress').doc(uid).get(const GetOptions(source: Source.serverAndCache));
      if (doc.exists) {
        return List<String>.from(doc.data()?['son_hatalar'] ?? []);
      }
    } catch (e) {
      debugPrint("Hatalar getirilemedi: $e");
    }
    return [];
  }

  // Hataları temizler
  Future<void> clearMistakes(String uid) async {
    try {
      await _firestore.collection('usersProgress').doc(uid).set({
        'son_hatalar': [],
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint("Hatalar temizlenemedi: $e");
    }
  }

  // Yapay Zeka Risk Analizi — Cloud Function üzerinden çalışır
  // API anahtarı sunucuda, admin kontrolü sunucuda yapılır
  Future<Map<String, String>?> kullaniciyiAnalizEt(String uid) async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      bool hasInternet = connectivityResult.any((r) => r != ConnectivityResult.none);
                         
      if (!hasInternet) {
        debugPrint("Çevrimdışı mod: Gemini yerine Kural Tabanlı Motor çalışıyor.");
        final mistakes = await getMistakes(uid);
        final offlineResult = await _offlineEngine.analyzeMistakes(mistakes);
        return {
          "durum": offlineResult?["durum"] ?? "GÜVENLİ",
          "neden": "Çevrimdışı analiz: " + (offlineResult?["neden"] ?? "Sorun tespit edilmedi.")
        };
      }

      // 15 saniye içinde cevap gelmezse timeout olur ve catch'e düşer
      final result = await _analysisFn.call({'uid': uid}).timeout(const Duration(seconds: 15));

      final durum = result.data['durum'] ?? 'BİLİNMİYOR';
      final neden = result.data['neden'] ?? 'Analiz sonucu okunamadı.';

      return {"durum": durum, "neden": neden};
    } on FirebaseFunctionsException catch (e) {
      debugPrint("YZ Analiz Hatası: ${e.code} - ${e.message}");
      return {"durum": "HATA", "neden": "Sunucu şu an çok meşgul, lütfen biraz sonra tekrar dene."};
    } catch (e) {
      debugPrint("Bağlantı Hatası: $e");
      return {"durum": "HATA", "neden": "Bağlantı çok yavaş veya koptu. Lütfen internetini kontrol et."};
    }
  }
}
