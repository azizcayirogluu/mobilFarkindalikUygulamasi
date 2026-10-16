import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'file_saver/file_saver.dart' as saver;

class ScenarioExportResult {
  final bool success;
  final int totalScenarios;
  final String fileName;
  final String? filePathOrName;
  final String? errorMessage;

  ScenarioExportResult({
    required this.success,
    required this.totalScenarios,
    required this.fileName,
    this.filePathOrName,
    this.errorMessage,
  });
}

class ScenarioExportService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<ScenarioExportResult> exportScenariosToJson() async {
    try {
      // 1. Fetch all scenarios from Firestore collection 'scenarios'
      final querySnapshot = await _firestore.collection('scenarios').get(
        const GetOptions(source: Source.serverAndCache),
      );

      final totalDocsInFirestore = querySnapshot.docs.length;

      if (totalDocsInFirestore == 0) {
        return ScenarioExportResult(
          success: false,
          totalScenarios: 0,
          fileName: '',
          errorMessage: 'Firestore scenarios koleksiyonunda aktarılacak hiç kayıt bulunamadı.',
        );
      }

      // 2. Convert raw Firestore documents preserving all fields and document IDs
      final List<Map<String, dynamic>> exportedScenarios = [];

      for (final doc in querySnapshot.docs) {
        final rawData = doc.data();
        final Map<String, dynamic> convertedData = {
          "id": doc.id,
          ...rawData.map((key, value) => MapEntry(key, _convertJsonValue(value))),
        };
        exportedScenarios.add(convertedData);
      }

      // 3. Verification check 1: Count match
      if (exportedScenarios.length != totalDocsInFirestore) {
        return ScenarioExportResult(
          success: false,
          totalScenarios: exportedScenarios.length,
          fileName: '',
          errorMessage:
              'Doğrulama Hatası: Çekilen senaryo sayısı ($totalDocsInFirestore) ile aktarılan (${exportedScenarios.length}) uyuşmuyor.',
        );
      }

      // 4. Construct payload map
      final exportPayload = <String, dynamic>{
        "exportDate": DateTime.now().toIso8601String(),
        "source": "firestore/scenarios",
        "totalScenarios": exportedScenarios.length,
        "scenarios": exportedScenarios,
      };

      // 5. UTF-8 JSON String conversion
      final jsonEncoder = const JsonEncoder.withIndent('  ');
      final jsonString = jsonEncoder.convert(exportPayload);

      // 6. Verification check 2: JSON re-parsing and count verification
      final reParsed = json.decode(jsonString) as Map<String, dynamic>;
      final reParsedList = reParsed['scenarios'] as List;

      if (reParsedList.length != totalDocsInFirestore) {
        return ScenarioExportResult(
          success: false,
          totalScenarios: reParsedList.length,
          fileName: '',
          errorMessage:
              'Doğrulama Hatası: Oluşturulan JSON verisindeki senaryo sayısı (${reParsedList.length}) eksik!',
        );
      }

      // 7. Dynamic File Name: kahraman_dostum_senaryolar_YYYY-MM-DD.json
      final dateStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final fileName = 'kahraman_dostum_senaryolar_$dateStr.json';

      // 8. Save/Download File
      final savedPath = await saver.saveAndShareFile(fileName, jsonString);

      return ScenarioExportResult(
        success: true,
        totalScenarios: totalDocsInFirestore,
        fileName: fileName,
        filePathOrName: savedPath,
      );
    } catch (e) {
      return ScenarioExportResult(
        success: false,
        totalScenarios: 0,
        fileName: '',
        errorMessage: 'Senaryolar dışa aktarılırken bir hata oluştu: $e',
      );
    }
  }

  static dynamic _convertJsonValue(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) {
      return value.toDate().toIso8601String();
    } else if (value is DateTime) {
      return value.toIso8601String();
    } else if (value is Map) {
      return value.map((k, v) => MapEntry(k.toString(), _convertJsonValue(v)));
    } else if (value is List) {
      return value.map((v) => _convertJsonValue(v)).toList();
    } else if (value is GeoPoint) {
      return {'latitude': value.latitude, 'longitude': value.longitude};
    } else if (value is DocumentReference) {
      return value.path;
    } else {
      return value;
    }
  }
}
