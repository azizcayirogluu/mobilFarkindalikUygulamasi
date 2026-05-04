import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AiAnalysisService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Kullanıcının yanlış yaptığı bir konuyu (örn: "Şifre Paylaşımı") veritabanına ekler.
  Future<void> logMistake(String uid, String topic) async {
    try {
      final docRef = _firestore.collection('usersProgress').doc(uid);

      // FieldValue.arrayUnion ile aynı konunun tekrar tekrar eklenmesini önleyebiliriz.
      await docRef.set({
        'son_hatalar': FieldValue.arrayUnion([topic]),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint("AiAnalysisService: Hata loglama başarısız: $e");
    }
  }

  /// Yapay zekaya vermek üzere kullanıcının son hatalarını getirir.
  Future<List<String>> getMistakes(String uid) async {
    try {
      final docSnap = await _firestore.collection('usersProgress').doc(uid).get();
      if (docSnap.exists) {
        List data = docSnap.data()?['son_hatalar'] ?? [];
        return List<String>.from(data);
      }
    } catch (e) {
      debugPrint("AiAnalysisService: Hata listesi alınamadı: $e");
    }
    return [];
  }

  /// Asistan bu konuları işlediğinde veya temizlenmesi gerektiğinde çağrılır.
  Future<void> clearMistakes(String uid) async {
    try {
      await _firestore.collection('usersProgress').doc(uid).update({
        'son_hatalar': FieldValue.delete(),
      });
    } catch (e) {
      debugPrint("AiAnalysisService: Hatalar temizlenemedi: $e");
    }
  }

  /// Yöneticiler için kullanıcının risk durumunu (GUVENLI, OLABILIR, TEHLIKEDE) analiz eder
  Future<Map<String, String>?> kullaniciyiAnalizEt(String uid) async {
    try {
      final progressDoc = await _firestore.collection('usersProgress').doc(uid).get();
      if (!progressDoc.exists) return null;

      final data = progressDoc.data()!;
      List sohbetGecmisi = data['sohbet_gecmisi'] ?? [];
      List sonHatalar = data['son_hatalar'] ?? [];

      String chatText = sohbetGecmisi.map((m) => "${m['rol']}: ${m['metin']}").join("\n");
      String hatalarText = sonHatalar.join(", ");

      String apiKey = dotenv.env['GEMINI_API_KEY'] ?? "";
      if (apiKey.isEmpty) {
        debugPrint("YZ Analiz Hatası: API KEY yok.");
        return null;
      }

      final model = GenerativeModel(
        model: 'gemini-1.5-flash',
        apiKey: apiKey,
        systemInstruction: Content.system(
          "Sen bir uzman psikolog ve siber güvenlik analistisin. "
          "Sana verilen çocuğun sohbet geçmişini ve eğitimde yaptığı hataları incele. "
          "Amacın çocuğun bir siber zorbalığa uğrayıp uğramadığını, şantaj/tehdit altında olup olmadığını veya riskli davranışlarda bulunup bulunmadığını tespit etmek. "
          "Dönüş formatı SADECE şu şekilde olmalı: DURUM|Açıklama "
          "DURUM sadece şu 3 kelimeden biri olabilir: GÜVENLİ, OLABİLİR, TEHLİKEDE. "
          "Açıklama ise neden bu duruma karar verdiğini belirten tek bir cümle olmalı.",
        ),
      );

      String prompt = "Veri Yok";
      if (chatText.isEmpty && hatalarText.isEmpty) {
        return {
          "durum": "GÜVENLİ",
          "neden": "Kullanıcının henüz bir etkileşimi veya hatası bulunmuyor.",
        };
      } else {
        prompt =
            "Sohbet Geçmişi:\n$chatText\n\nEğitim Hataları:\n$hatalarText\n\nLütfen bu veriyi analiz et.";
      }

      final response = await model.generateContent([Content.text(prompt)]);

      if (response.text != null && response.text!.contains('|')) {
        final parts = response.text!.split('|');
        final durum = parts[0].trim().toUpperCase();
        final neden = parts[1].trim();

        await _firestore.collection('usersProgress').doc(uid).update({
          'riskDurumu': durum,
          'riskNedeni': neden,
          'sonRiskAnalizi': FieldValue.serverTimestamp(),
        });

        return {"durum": durum, "neden": neden};
      }
    } catch (e) {
      debugPrint("YZ Analiz Hatası: $e");
    }
    return null;
  }
}
