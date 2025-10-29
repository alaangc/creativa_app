import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/pedido.dart';
import '../../models/cliente.dart';
import '../../services/database_service.dart';

class PedidoDetalleScreen extends StatefulWidget {
  final Pedido pedido;

  const PedidoDetalleScreen({super.key, required this.pedido});

  @override
  State<PedidoDetalleScreen> createState() => _PedidoDetalleScreenState();
}

class _PedidoDetalleScreenState extends State<PedidoDetalleScreen> {
  final DatabaseService _dbService = DatabaseService();
  final NumberFormat _formatoMoneda = NumberFormat.currency(symbol: '\$', decimalDigits: 2);
  final DateFormat _formatoFecha = DateFormat('dd/MM/yyyy HH:mm');

  late Pedido _pedido;
  Cliente? _cliente;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _pedido = widget.pedido;
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    try {
      final cliente = await _dbService.obtenerClientePorId(_pedido.clienteId);
      setState(() {
        _cliente = cliente;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar datos: $e')),
        );
      }
    }
  }

  Color _getColorEstado(String estado) {
    switch (estado) {
      case 'Pendiente':
        return Colors.orange;
      case 'En Producción':
        return Colors.blue;
      case 'Finalizado':
        return Colors.green;
      case 'Entregado':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  Future<void> _cambiarEstado() async {
    final nuevoEstado = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cambiar Estado'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: Pedido.estadosDisponibles.map((estado) {
            return ListTile(
              leading: CircleAvatar(
                backgroundColor: _getColorEstado(estado),
                radius: 8,
              ),
              title: Text(estado),
              selected: estado == _pedido.estado,
              onTap: () => Navigator.pop(context, estado),
            );
          }).toList(),
        ),
      ),
    );

    if (nuevoEstado != null && nuevoEstado != _pedido.estado && _pedido.id != null) {
      try {
        await _dbService.actualizarEstadoPedido(_pedido.id!, nuevoEstado);
        setState(() {
          _pedido = _pedido.copyWith(estado: nuevoEstado);
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Estado actualizado correctamente')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al actualizar estado: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle del Pedido'),
        elevation: 2,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: _cambiarEstado,
            tooltip: 'Cambiar estado',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Código de seguimiento y estado
                  Card(
                    elevation: 4,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Icon(Icons.qr_code, size: 48),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  const Text(
                                    'Código de Seguimiento',
                                    style: TextStyle(fontSize: 12, color: Colors.grey),
                                  ),
                                  Text(
                                    _pedido.codigoSeguimiento,
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'monospace',
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Badge(
                            label: Text(
                              _pedido.estado.toUpperCase(),
                              style: const TextStyle(fontSize: 16),
                            ),
                            backgroundColor: _getColorEstado(_pedido.estado),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 8,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Información del cliente
                  Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.person, color: Colors.blue),
                              const SizedBox(width: 8),
                              const Text(
                                'Cliente',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const Divider(),
                          const SizedBox(height: 8),
                          _buildInfoRow(Icons.account_circle, 'Nombre', _pedido.nombreCliente),
                          if (_cliente != null) ...[
                            const SizedBox(height: 8),
                            _buildInfoRow(Icons.phone, 'Teléfono', _cliente!.telefono),
                            const SizedBox(height: 8),
                            _buildInfoRow(Icons.email, 'Email', _cliente!.email),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Información del pedido
                  Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.receipt_long, color: Colors.green),
                              const SizedBox(width: 8),
                              const Text(
                                'Información del Pedido',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const Divider(),
                          const SizedBox(height: 8),
                          _buildInfoRow(
                            Icons.calendar_today,
                            'Fecha',
                            _formatoFecha.format(_pedido.fecha),
                          ),
                          const SizedBox(height: 16),
                          const Divider(),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'TOTAL',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                _formatoMoneda.format(_pedido.total),
                                style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Botón para cambiar estado
                  ElevatedButton.icon(
                    onPressed: _cambiarEstado,
                    icon: const Icon(Icons.sync),
                    label: const Text('Cambiar Estado del Pedido'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      textStyle: const TextStyle(fontSize: 16),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 16),
          ),
        ),
      ],
    );
  }
}
