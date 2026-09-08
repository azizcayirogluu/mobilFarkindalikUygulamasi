import 'dart:convert';
import 'package:flutter/services.dart';

class OfflineAIEngine {
  Map<String, dynamic>? _rulesData;

  Future<void> init() async {
    try {
      final jsonString = await rootBundle.loadString(
        'assets/data/offline_ai_responses.json',
      );
      _rulesData = jsonDecode(jsonString);
    } catch (e) {
      _rulesData = null;
    }
  }

  Future<Map<String, String>> analyzeMistakes(List<String> mistakes) async {
    if (_rulesData == null) {
      await init();
    }

    if (_rulesData == null || mistakes.isEmpty) {
      return {
        "durum": "RİSKLİ",
        "neden":
            "Şu an internete bağlı değiliz. Ancak siber dünyada güvende kalmak için lütfen tanımadığın kişilerle konuşma ve kişisel bilgilerini paylaşma.",
      };
    }

    final rules = _rulesData!['rules'] as List;
    final defaultResponse = _rulesData!['default'] as String;

    String textToAnalyze = mistakes.join(" ").toLowerCase();

    for (var rule in rules) {
      List<dynamic> keywords = rule['keywords'];
      for (var keyword in keywords) {
        if (textToAnalyze.contains(keyword.toString().toLowerCase())) {
          return {"durum": "RİSKLİ", "neden": rule['response']};
        }
      }
    }

    return {"durum": "BİLİNMİYOR", "neden": defaultResponse};
  }
}
