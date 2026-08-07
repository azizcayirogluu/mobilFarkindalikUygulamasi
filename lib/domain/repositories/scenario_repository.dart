import '../../data/models/scenario_model.dart';

abstract class ScenarioRepository {
  Future<List<ScenarioModel>> getScenarios();
}
