import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/repositories/scenario_repository.dart';
import '../models/scenario_model.dart';

class ScenarioRepositoryImpl implements ScenarioRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Future<List<ScenarioModel>> getScenarios() async {
    try {
      final snapshot = await _firestore.collection('scenarios').get();
      return snapshot.docs.map((doc) => ScenarioModel.fromMap(doc.id, doc.data())).toList();
    } catch (e) {
      return [];
    }
  }
}
