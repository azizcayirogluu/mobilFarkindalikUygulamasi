import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../../domain/repositories/content_repository.dart';

List<Map<String, dynamic>> sanitizeDiscoveryPool(
  List<Map<String, dynamic>> pool,
) {
  final cleaned = <Map<String, dynamic>>[];
  final seenKeys = <String>{};

  for (final item in pool) {
    final id = (item['id'] ?? '').toString().trim();
    final tip = (item['tip'] ?? '').toString().trim();
    final baslik = (item['baslik'] ?? '').toString().trim();

    if (id.isEmpty || tip.isEmpty) continue;
    if (tip == 'SENARYO' && baslik.isEmpty) continue;

    final key = '$tip:$id';
    if (seenKeys.contains(key)) continue;
    seenKeys.add(key);
    cleaned.add(item);
  }

  return cleaned;
}

class ContentRepositoryImpl implements ContentRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // --- ÖNBELLEK (CACHE) ALANI ---
  Map<String, dynamic>? _cacheDiscoveryData;
  DateTime? _lastFetchTime;

  @override
  Future<Map<String, dynamic>> fetchDiscoveryData() async {
    // 1. Önbellek Kontrolü: Eğer son 10 dakika içinde veri çekilmişse, hafızadaki veriyi dön.
    if (_cacheDiscoveryData != null && _lastFetchTime != null) {
      if (DateTime.now().difference(_lastFetchTime!).inMinutes < 10) {
        return _cacheDiscoveryData!;
      }
    }

    final connectivityResult = await Connectivity().checkConnectivity();
    bool hasInternet = connectivityResult.any(
      (r) => r != ConnectivityResult.none,
    );
    final source = hasInternet ? Source.serverAndCache : Source.cache;

    try {
      final results = await Future.wait([
        _firestore
            .collection('scenarios')
            .limit(4)
            .get(GetOptions(source: source)),
        _firestore
            .collection('stories')
            .limit(4)
            .get(GetOptions(source: source)),
        _firestore
            .collection('videos')
            .limit(5)
            .get(GetOptions(source: source)),
        _safeCount('scenarios'),
        _safeCount('stories'),
        _safeCount('detective_questions'),
        _safeCount('videos'),
      ]);

      final sSnap = results[0] as QuerySnapshot<Map<String, dynamic>>;
      final hSnap = results[1] as QuerySnapshot<Map<String, dynamic>>;
      final vSnap = results[2] as QuerySnapshot<Map<String, dynamic>>;
      final scenarioCount = results[3] as int;
      final storyCount = results[4] as int;
      final detectiveCount = results[5] as int;
      final videoCount = results[6] as int;

      List<Map<String, dynamic>> pool = [];

      for (var d in sSnap.docs) {
        pool.add({
          "id": d.id,
          "tip": "SENARYO",
          "baslik": d.data()['baslik'] ?? "Senaryo",
          "altBaslik": d.data()['altBaslik'] ?? "",
          "renkStr": d.data()['renk'],
          "ikonStr": d.data()['ikon'],
          "data": d.data(),
        });
      }
      for (var d in hSnap.docs) {
        pool.add({
          "id": d.id,
          "tip": "HİKAYE",
          "baslik": d.data()['baslik'] ?? "Hikaye",
          "altBaslik": d.data()['altBaslik'] ?? "",
          "renkStr": d.data()['renk'] ?? "0xFFFFB74D",
          "ikonStr": "auto_stories",
          "data": d.data(),
        });
      }
      for (var d in vSnap.docs) {
        pool.add({
          "id": d.id,
          "tip": "VİDEO",
          "baslik": d.data()['baslik'] ?? "Video",
          "altBaslik": d.data()['altBaslik'] ?? "",
          "renkStr": d.data()['renk'] ?? "0xFFE57373",
          "ikonStr": "play",
          "data": d.data(),
        });
      }

      pool.shuffle();
      final cleanedPool = sanitizeDiscoveryPool(pool);

      final result = {
        'toplamGorevSayisi': scenarioCount + storyCount + detectiveCount,
        'kesifHavuzu': cleanedPool.take(4).toList(),
      };

      // 2. Önbelleği Güncelle
      _cacheDiscoveryData = result;
      _lastFetchTime = DateTime.now();

      return result;
    } catch (e) {
      return _cacheDiscoveryData ?? {'toplamGorevSayisi': 0, 'kesifHavuzu': []};
    }
  }

  Future<int> _safeCount(String collectionName) async {
    try {
      final snap = await _firestore.collection(collectionName).count().get();
      return snap.count ?? 0;
    } catch (e) {
      return 0;
    }
  }

  @override
  Stream<DocumentSnapshot> getUserProgressStream(String uid) {
    return _firestore
        .collection('usersProgress')
        .doc(uid)
        .snapshots(includeMetadataChanges: true);
  }
}
