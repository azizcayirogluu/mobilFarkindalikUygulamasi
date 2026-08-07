import 'package:cloud_firestore/cloud_firestore.dart';

abstract class ContentRepository {
  Future<Map<String, dynamic>> fetchDiscoveryData();
  Stream<DocumentSnapshot> getUserProgressStream(String uid);
}
