class ProgressModel {
  final int id;
  final String fecha;
  final double pesoCorporal;
  final String? fotoUrl;

  ProgressModel({
    required this.id,
    required this.fecha,
    required this.pesoCorporal,
    this.fotoUrl,
  });

  factory ProgressModel.fromJson(Map<String, dynamic> json) {
    return ProgressModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      fecha: (json['fecha'] ?? '').toString().split('T')[0],
      pesoCorporal: _parseDouble(json['peso_corporal']),
      fotoUrl: json['foto_url']?.toString(),
    );
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }
}