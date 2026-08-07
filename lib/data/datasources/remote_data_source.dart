import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseRemoteDataSource {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<Map<String, dynamic>>> fetchScenarios() async {
    final snap = await _firestore.collection('scenarios').get(const GetOptions(source: Source.serverAndCache));
    return snap.docs.map((d) => {"id": d.id, ...d.data()}).toList();
  }

  Future<void> syncUserProgress(String uid, Map<String, dynamic> data) async {
    await _firestore.collection('usersProgress').doc(uid).set(data, SetOptions(merge: true));
  }
}
