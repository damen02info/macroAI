class MealModel {
  final int id;
  final String nombrePlato;
  final double calorias;
  final double carbohidratos;
  final double proteinas;
  final double grasas;
  final String ingredientesEstimados;
  final String fechaHora; // <-- NUEVO

  MealModel({
    required this.id,
    required this.nombrePlato,
    required this.calorias,
    required this.carbohidratos,
    required this.proteinas,
    required this.grasas,
    required this.ingredientesEstimados,
    required this.fechaHora, // <-- NUEVO
  });

  factory MealModel.fromJson(Map<String, dynamic> json) {
    return MealModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      nombrePlato: json['nombre_plato'] ?? 'Desconocido',
      calorias: _parseDouble(json['calorias']),
      carbohidratos: _parseDouble(json['carbohidratos']),
      proteinas: _parseDouble(json['proteinas']),
      grasas: _parseDouble(json['grasas']),
      ingredientesEstimados: json['ingredientes_estimados'] ?? '',
      fechaHora: json['fecha_hora'] ?? '', // <-- NUEVO
    );
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }
}