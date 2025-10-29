class Cliente {
  final int? id;
  final String nombre;
  final String telefono;
  final String email;
  final DateTime fechaRegistro;

  Cliente({
    this.id,
    required this.nombre,
    required this.telefono,
    required this.email,
    required this.fechaRegistro,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nombre': nombre,
      'telefono': telefono,
      'email': email,
      'fechaRegistro': fechaRegistro.toIso8601String(),
    };
  }

  factory Cliente.fromMap(Map<String, dynamic> map) {
    return Cliente(
      id: map['id'] as int?,
      nombre: map['nombre'] as String,
      telefono: map['telefono'] as String,
      email: map['email'] as String,
      fechaRegistro: DateTime.parse(map['fechaRegistro'] as String),
    );
  }

  Cliente copyWith({
    int? id,
    String? nombre,
    String? telefono,
    String? email,
    DateTime? fechaRegistro,
  }) {
    return Cliente(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      telefono: telefono ?? this.telefono,
      email: email ?? this.email,
      fechaRegistro: fechaRegistro ?? this.fechaRegistro,
    );
  }
}
