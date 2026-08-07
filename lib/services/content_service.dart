import 'package:cloud_firestore/cloud_firestore.dart';
import '../injection_container.dart';
import '../domain/repositories/content_repository.dart';

// Legacy Wrapper: UI kodlarını kırmamak için eski ContentService korunmuştur,
// Ancak arka planda yeni ContentRepository (Offline-first) mimarisini kullanır.
class ContentService {
  // get_it üzerinden servise erişim sağlanır
  final ContentRepository _repository = sl<ContentRepository>();

  Future<Map<String, dynamic>> fetchDiscoveryData() async {
    return await _repository.fetchDiscoveryData();
  }

  Stream<DocumentSnapshot> getUserProgressStream(String uid) {
    return _repository.getUserProgressStream(uid);
  }
}
