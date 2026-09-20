class ScenarioModel {
  String firebaseId;
  String? baslik;
  String? altBaslik;
  String? ikon;
  String? renk;
  DateTime? updatedAt;

  ScenarioModel({
    required this.firebaseId,
    this.baslik,
    this.altBaslik,
    this.ikon,
    this.renk,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'firebaseId': firebaseId,
      'baslik': baslik,
      'altBaslik': altBaslik,
      'ikon': ikon,
      'renk': renk,
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  factory ScenarioModel.fromMap(String id, Map<String, dynamic> map) {
    try {
      return ScenarioModel(
        firebaseId: id,
        baslik: map['baslik'] as String? ?? 'Başlıksız Senaryo',
        altBaslik: map['altBaslik'] as String? ?? '',
        ikon: map['ikon'] as String? ?? 'help_outline',
        renk: map['renk'] as String? ?? '0xFF9E9E9E',
        updatedAt: map['updatedAt'] != null 
            ? DateTime.tryParse(map['updatedAt'].toString()) 
            : null,
      );
    } catch (e) {
      return ScenarioModel(firebaseId: id, baslik: 'Veri Hatası');
    }
  }
}
