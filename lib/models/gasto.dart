class Gasto {
  final int? id;
  final String concepto;
  final double monto;
  final String area;
  final DateTime fecha;

  Gasto({
    this.id,
    required this.concepto,
    required this.monto,
    required this.area,
    required this.fecha,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'concepto': concepto,
      'monto': monto,
      'area': area,
      'fecha': fecha.toIso8601String(),
    };
  }

  factory Gasto.fromMap(Map<String, dynamic> map) {
    return Gasto(
      id: map['id'] as int?,
      concepto: map['concepto'] as String,
      monto: (map['monto'] as num).toDouble(),
      area: map['area'] as String,
      fecha: DateTime.parse(map['fecha'] as String),
    );
  }

  Gasto copyWith({
    int? id,
    String? concepto,
    double? monto,
    String? area,
    DateTime? fecha,
  }) {
    return Gasto(
      id: id ?? this.id,
      concepto: concepto ?? this.concepto,
      monto: monto ?? this.monto,
      area: area ?? this.area,
      fecha: fecha ?? this.fecha,
    );
  }
}
