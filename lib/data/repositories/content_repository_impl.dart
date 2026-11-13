import 'package:cloud_firestore/cloud_firestore.dart';
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
    // 1. Önbellek Kontrolü: Eğer son 10 dakika içinde geçerli veri çekilmişse, hafızadaki veriyi dön.
    if (_cacheDiscoveryData != null &&
        (_cacheDiscoveryData!['toplamGorevSayisi'] as int? ?? 0) > 0 &&
        DateTime.now().difference(_lastFetchTime ?? DateTime(0)).inMinutes < 10) {
      return _cacheDiscoveryData!;
    }

    const source = Source.serverAndCache;

    try {
      final results = await Future.wait([
        _firestore
            .collection('scenarios')
            .limit(6)
            .get(GetOptions(source: source)),
        _firestore
            .collection('stories')
            .limit(6)
            .get(GetOptions(source: source)),
        _firestore
            .collection('videos')
            .limit(6)
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

      List<Map<String, dynamic>> senaryolar = [];
      List<Map<String, dynamic>> hikayeler = [];
      List<Map<String, dynamic>> videolar = [];

      for (var d in sSnap.docs) {
        senaryolar.add({
          "id": d.id,
          "tip": "SENARYO",
          "baslik": d.data()['baslik'] ?? "Senaryo",
          "altBaslik": d.data()['altBaslik'] ?? "Kararlarınla Olayları Yönet!",
          "renkStr": d.data()['renk'] ?? "0xFF6366F1",
          "ikonStr": d.data()['ikon'] ?? "psychology",
          "data": d.data(),
        });
      }

      for (var d in hSnap.docs) {
        hikayeler.add({
          "id": d.id,
          "tip": "HİKAYE",
          "baslik": d.data()['baslik'] ?? "Hikaye",
          "altBaslik": d.data()['altBaslik'] ?? "Yeni bir macera seni bekliyor!",
          "renkStr": d.data()['renk'] ?? "0xFFFFB74D",
          "ikonStr": "auto_stories",
          "data": d.data(),
        });
      }

      for (var d in vSnap.docs) {
        videolar.add({
          "id": d.id,
          "tip": "VİDEO",
          "baslik": d.data()['baslik'] ?? "Video",
          "altBaslik": d.data()['altBaslik'] ?? "Eğlenceli videolarla öğren!",
          "renkStr": d.data()['renk'] ?? "0xFFE57373",
          "ikonStr": "play",
          "data": d.data(),
        });
      }

      final dedektifItem = {
        "id": "siber_dedektif_game",
        "tip": "SİBER DEDEKTİF",
        "baslik": "Kahraman Dedektif 🔍",
        "altBaslik": "Olayları bir dedektif gibi incele!",
        "renkStr": "0xFF10B981",
        "ikonStr": "search",
        "data": {},
      };

      senaryolar.shuffle();
      hikayeler.shuffle();
      videolar.shuffle();

      // Farklı içerik tiplerini sıralı ve dengeli şekilde harmanla (Interleave)
      List<Map<String, dynamic>> interleaved = [];
      int maxLen = [
        senaryolar.length,
        hikayeler.length,
        videolar.length,
        1,
      ].reduce((a, b) => a > b ? a : b);

      for (int i = 0; i < maxLen; i++) {
        if (i < senaryolar.length) interleaved.add(senaryolar[i]);
        if (i < hikayeler.length) interleaved.add(hikayeler[i]);
        if (i < videolar.length) interleaved.add(videolar[i]);
        if (i == 0) interleaved.add(dedektifItem);
      }

      final cleanedPool = sanitizeDiscoveryPool(interleaved);

      final totalTasks = scenarioCount + storyCount + detectiveCount;
      final result = {
        'toplamGorevSayisi': totalTasks,
        'kesifHavuzu': cleanedPool.take(12).toList(),
      };

      if (totalTasks > 0) {
        _cacheDiscoveryData = result;
        _lastFetchTime = DateTime.now();
      }

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
        .snapshots();
  }
}
