class Pedido {
  final int? id;
  final String codigoSeguimiento;
  final int clienteId;
  final String nombreCliente;
  final DateTime fecha;
  final String estado;
  final double total;

  static const String estadoPendiente = 'Pendiente';
  static const String estadoEnProduccion = 'En Producción';
  static const String estadoFinalizado = 'Finalizado';
  static const String estadoEntregado = 'Entregado';

  static const List<String> estadosDisponibles = [
    estadoPendiente,
    estadoEnProduccion,
    estadoFinalizado,
    estadoEntregado,
  ];

  Pedido({
    this.id,
    required this.codigoSeguimiento,
    required this.clienteId,
    required this.nombreCliente,
    required this.fecha,
    required this.estado,
    required this.total,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'codigoSeguimiento': codigoSeguimiento,
      'clienteId': clienteId,
      'nombreCliente': nombreCliente,
      'fecha': fecha.toIso8601String(),
      'estado': estado,
      'total': total,
    };
  }

  factory Pedido.fromMap(Map<String, dynamic> map) {
    return Pedido(
      id: map['id'] as int?,
      codigoSeguimiento: map['codigoSeguimiento'] as String,
      clienteId: map['clienteId'] as int,
      nombreCliente: map['nombreCliente'] as String,
      fecha: DateTime.parse(map['fecha'] as String),
      estado: map['estado'] as String,
      total: (map['total'] as num).toDouble(),
    );
  }

  Pedido copyWith({
    int? id,
    String? codigoSeguimiento,
    int? clienteId,
    String? nombreCliente,
    DateTime? fecha,
    String? estado,
    double? total,
  }) {
    return Pedido(
      id: id ?? this.id,
      codigoSeguimiento: codigoSeguimiento ?? this.codigoSeguimiento,
      clienteId: clienteId ?? this.clienteId,
      nombreCliente: nombreCliente ?? this.nombreCliente,
      fecha: fecha ?? this.fecha,
      estado: estado ?? this.estado,
      total: total ?? this.total,
    );
  }
}
