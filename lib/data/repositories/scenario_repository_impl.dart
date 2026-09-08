import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/repositories/scenario_repository.dart';
import '../models/scenario_model.dart';

class ScenarioRepositoryImpl implements ScenarioRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // --- MALİYET OPTİMİZASYONU: SENARYO ÖNBELLEĞİ ---
  List<ScenarioModel>? _cachedScenarios;
  DateTime? _lastFetchTime;

  @override
  Future<List<ScenarioModel>> getScenarios() async {
    // 1. Önbellek Kontrolü: 10 dakika içinde veri çekilmişse cache'den dön.
    if (_cachedScenarios != null && _lastFetchTime != null) {
      if (DateTime.now().difference(_lastFetchTime!).inMinutes < 10) {
        return _cachedScenarios!;
      }
    }

    try {
      final snapshot = await _firestore.collection('scenarios').get();
      final scenarios = snapshot.docs
          .map((doc) => ScenarioModel.fromMap(doc.id, doc.data()))
          .toList();

      // 2. Önbelleği güncelle
      _cachedScenarios = scenarios;
      _lastFetchTime = DateTime.now();

      return scenarios;
    } catch (e) {
      // Hata durumunda (örn. offline) cache varsa onu dön
      return _cachedScenarios ?? [];
    }
  }
}