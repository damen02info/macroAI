class ProfileModel {
  final int id;
  final double tdeeObjetivo;
  final double metaProteinas;
  final double metaCarbos;
  final double metaGrasas;
  final String actualizadoEn;

  ProfileModel({
    required this.id,
    required this.tdeeObjetivo,
    required this.metaProteinas,
    required this.metaCarbos,
    required this.metaGrasas,
    required this.actualizadoEn,
  });

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    return ProfileModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 1,
      tdeeObjetivo: _parseDouble(json['tdee_objetivo']),
      metaProteinas: _parseDouble(json['meta_proteinas']),
      metaCarbos: _parseDouble(json['meta_carbos']),
      metaGrasas: _parseDouble(json['meta_grasas']),
      actualizadoEn: json['actualizado_en'] ?? '',
    );
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }
}