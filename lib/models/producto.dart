class Producto {
  final int? id;
  final String nombre;
  final String area;
  final double precio;
  final String descripcion;

  Producto({
    this.id,
    required this.nombre,
    required this.area,
    required this.precio,
    required this.descripcion,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nombre': nombre,
      'area': area,
      'precio': precio,
      'descripcion': descripcion,
    };
  }

  factory Producto.fromMap(Map<String, dynamic> map) {
    return Producto(
      id: map['id'] as int?,
      nombre: map['nombre'] as String,
      area: map['area'] as String,
      precio: (map['precio'] as num).toDouble(),
      descripcion: map['descripcion'] as String,
    );
  }

  Producto copyWith({
    int? id,
    String? nombre,
    String? area,
    double? precio,
    String? descripcion,
  }) {
    return Producto(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      area: area ?? this.area,
      precio: precio ?? this.precio,
      descripcion: descripcion ?? this.descripcion,
    );
  }
}
