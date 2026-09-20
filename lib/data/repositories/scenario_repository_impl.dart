import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/repositories/scenario_repository.dart';
import '../models/scenario_model.dart';

class ScenarioRepositoryImpl implements ScenarioRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<ScenarioModel>? _cachedScenarios;
  DateTime? _lastFetchTime;

  @override
  Future<List<ScenarioModel>> getScenarios() async {
    if (_cachedScenarios != null &&
        DateTime.now().difference(_lastFetchTime ?? DateTime(0)).inMinutes < 10) {
      return _cachedScenarios!;
    }

    try {
      final snapshot = await _firestore.collection('scenarios').get();
      final scenarios = snapshot.docs
          .map((doc) => ScenarioModel.fromMap(doc.id, doc.data()))
          .toList();

      _cachedScenarios = scenarios;
      _lastFetchTime = DateTime.now();

      return scenarios;
    } catch (e) {
      return _cachedScenarios ?? [];
    }
  }
}