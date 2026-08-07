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
    return UserProgressModel(
      uid: map['uid'] ?? '',
      toplamPuan: map['toplam_puan'] ?? 0,
      riskDurumu: map['riskDurumu'],
      riskNedeni: map['riskNedeni'],
      sonHatalar: List<String>.from(map['sonHatalar'] ?? []),
      rozetler: List<String>.from(map['rozetler'] ?? []),
      istatistikler: map['istatistikler'] != null ? StatisticsModel.fromMap(map['istatistikler']) : null,
      updatedAt: map['updatedAt'] != null ? DateTime.parse(map['updatedAt']) : null,
    );
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
    return StatisticsModel(
      toplamSureDk: map['toplamSureDk'] ?? 0,
      hataliCevaplar: map['hataliCevaplar'] ?? 0,
      empati: map['empati'] ?? 0,
      dikkat: map['dikkat'] ?? 0,
      yardim: map['yardim'] ?? 0,
    );
  }
}
