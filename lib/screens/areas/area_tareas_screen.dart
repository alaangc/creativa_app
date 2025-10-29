import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/pedido.dart';
import '../../services/database_service.dart';
import 'areas_screen.dart';

class AreaTareasScreen extends StatefulWidget {
  final String area;

  const AreaTareasScreen({super.key, required this.area});

  @override
  State<AreaTareasScreen> createState() => _AreaTareasScreenState();
}

class _AreaTareasScreenState extends State<AreaTareasScreen> {
  final DatabaseService _dbService = DatabaseService();
  final NumberFormat _formatoMoneda = NumberFormat.currency(symbol: '\$', decimalDigits: 2);
  final DateFormat _formatoFecha = DateFormat('dd/MM/yyyy');

  List<Pedido> _pedidos = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _cargarPedidos();
  }

  Future<void> _cargarPedidos() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final todosPedidos = await _dbService.obtenerPedidos();

      // Filtrar solo pedidos en Pendiente o En Producción
      final pedidosActivos = todosPedidos.where((pedido) {
        return pedido.estado == Pedido.estadoPendiente ||
               pedido.estado == Pedido.estadoEnProduccion;
      }).toList();

      setState(() {
        _pedidos = pedidosActivos;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar pedidos: $e')),
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

  String _getSiguienteEstado(String estadoActual) {
    switch (estadoActual) {
      case 'Pendiente':
        return Pedido.estadoEnProduccion;
      case 'En Producción':
        return Pedido.estadoFinalizado;
      case 'Finalizado':
        return Pedido.estadoEntregado;
      default:
        return estadoActual;
    }
  }

  String _getTextoBoton(String estadoActual) {
    switch (estadoActual) {
      case 'Pendiente':
        return 'Iniciar Producción';
      case 'En Producción':
        return 'Marcar Finalizado';
      default:
        return 'Siguiente';
    }
  }

  IconData _getIconoBoton(String estadoActual) {
    switch (estadoActual) {
      case 'Pendiente':
        return Icons.play_arrow;
      case 'En Producción':
        return Icons.check_circle;
      default:
        return Icons.arrow_forward;
    }
  }

  Future<void> _cambiarEstado(Pedido pedido) async {
    final nuevoEstado = _getSiguienteEstado(pedido.estado);

    if (pedido.id == null) return;

    try {
      await _dbService.actualizarEstadoPedido(pedido.id!, nuevoEstado);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Estado actualizado a: $nuevoEstado'),
            backgroundColor: _getColorEstado(nuevoEstado),
          ),
        );
      }

      // Recargar pedidos
      await _cargarPedidos();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al actualizar estado: $e')),
        );
      }
    }
  }

  Future<void> _entregarPedido(Pedido pedido) async {
    if (pedido.id == null) return;

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar entrega'),
        content: Text('¿Marcar como entregado el pedido ${pedido.codigoSeguimiento}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Entregar'),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      try {
        await _dbService.actualizarEstadoPedido(pedido.id!, Pedido.estadoEntregado);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Pedido marcado como entregado'),
              backgroundColor: Colors.grey,
            ),
          );
        }

        await _cargarPedidos();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al entregar pedido: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorArea = AreasScreen.areasColores[widget.area] ?? Colors.grey;

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.area} - Tareas'),
        elevation: 2,
        backgroundColor: colorArea,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _pedidos.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.check_circle_outline,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No hay pedidos activos',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Todos los pedidos han sido completados',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _pedidos.length,
                  itemBuilder: (context, index) {
                    final pedido = _pedidos[index];
                    return Card(
                      elevation: 3,
                      margin: const EdgeInsets.only(bottom: 16),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        pedido.nombreCliente,
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          const Icon(Icons.qr_code, size: 16, color: Colors.grey),
                                          const SizedBox(width: 4),
                                          Text(
                                            pedido.codigoSeguimiento,
                                            style: const TextStyle(
                                              fontFamily: 'monospace',
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                Badge(
                                  label: Text(pedido.estado),
                                  backgroundColor: _getColorEstado(pedido.estado),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                                const SizedBox(width: 4),
                                Text(_formatoFecha.format(pedido.fecha)),
                                const Spacer(),
                                Text(
                                  _formatoMoneda.format(pedido.total),
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: () => _cambiarEstado(pedido),
                                    icon: Icon(_getIconoBoton(pedido.estado)),
                                    label: Text(_getTextoBoton(pedido.estado)),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: colorArea,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                    ),
                                  ),
                                ),
                                if (pedido.estado == Pedido.estadoEnProduccion) ...[
                                  const SizedBox(width: 8),
                                  ElevatedButton.icon(
                                    onPressed: () => _entregarPedido(pedido),
                                    icon: const Icon(Icons.local_shipping),
                                    label: const Text('Entregar'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.grey[700],
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 12,
                                        horizontal: 16,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
