class UserProgressModel {
  String uid;
  int toplamPuan;
  String? riskDurumu;
  String? riskNedeni;
  List<String> sonHatalar;
  List<String> rozetler;
  StatisticsModel? istatistikler;
  DateTime? updatedAt;

  UserProgressModel({
    required this.uid,
    this.toplamPuan = 0,
    this.riskDurumu,
    this.riskNedeni,
    this.sonHatalar = const [],
    this.rozetler = const [],
    this.istatistikler,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'toplam_puan': toplamPuan,
      'riskDurumu': riskDurumu,
      'riskNedeni': riskNedeni,
      'sonHatalar': sonHatalar,
      'rozetler': rozetler,
      'istatistikler': istatistikler?.toMap(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  factory UserProgressModel.fromMap(Map<String, dynamic> map) {
    try {
      final rawStats = map['istatistikler'];
      return UserProgressModel(
        uid: map['uid'] is String ? map['uid'] as String : '',
        toplamPuan: (map['toplam_puan'] as num?)?.toInt() ?? 0,
        riskDurumu: map['riskDurumu'] is String ? map['riskDurumu'] as String : null,
        riskNedeni: map['riskNedeni'] is String ? map['riskNedeni'] as String : null,
        sonHatalar: (map['sonHatalar'] as List? ?? const [])
            .whereType<String>()
            .toList(growable: false),
        rozetler: (map['rozetler'] as List? ?? const [])
            .whereType<String>()
            .toList(growable: false),
        istatistikler: rawStats is Map
            ? StatisticsModel.fromMap(Map<String, dynamic>.from(rawStats))
            : null,
        updatedAt: map['updatedAt'] == null
            ? null
            : DateTime.tryParse(map['updatedAt'].toString()),
      );
    } catch (_) {
      return UserProgressModel(uid: '');
    }
  }
}

class StatisticsModel {
  int toplamSureDk;
  int hataliCevaplar;
  int empati;
  int dikkat;
  int yardim;

  StatisticsModel({
    this.toplamSureDk = 0,
    this.hataliCevaplar = 0,
    this.empati = 0,
    this.dikkat = 0,
    this.yardim = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'toplamSureDk': toplamSureDk,
      'hataliCevaplar': hataliCevaplar,
      'empati': empati,
      'dikkat': dikkat,
      'yardim': yardim,
    };
  }

  factory StatisticsModel.fromMap(Map<String, dynamic> map) {
    final kararYapisi = map['karar_yapisi'] as Map?;

    return StatisticsModel(
      toplamSureDk: (map['toplam_sure_dk'] as num?)?.toInt() ??
          (map['toplamSureDk'] as num?)?.toInt() ??
          0,
      hataliCevaplar: (map['hatali_cevaplar'] as num?)?.toInt() ??
          (map['hataliCevaplar'] as num?)?.toInt() ??
          0,
      empati: (kararYapisi?['empati'] as num?)?.toInt() ??
          (map['empati'] as num?)?.toInt() ??
          0,
      dikkat: (kararYapisi?['dikkat'] as num?)?.toInt() ??
          (map['dikkat'] as num?)?.toInt() ??
          0,
      yardim: (kararYapisi?['yardim'] as num?)?.toInt() ??
          (map['yardim'] as num?)?.toInt() ??
          0,
    );
  }
}
