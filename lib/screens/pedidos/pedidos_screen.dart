import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/pedido.dart';
import '../../services/database_service.dart';
import 'pedido_form_screen.dart';
import 'pedido_detalle_screen.dart';

class PedidosScreen extends StatefulWidget {
  const PedidosScreen({super.key});

  @override
  State<PedidosScreen> createState() => _PedidosScreenState();
}

class _PedidosScreenState extends State<PedidosScreen> {
  final DatabaseService _dbService = DatabaseService();
  final NumberFormat _formatoMoneda = NumberFormat.currency(symbol: '\$', decimalDigits: 2);
  final DateFormat _formatoFecha = DateFormat('dd/MM/yyyy');

  List<Pedido> _pedidos = [];
  List<Pedido> _pedidosFiltrados = [];
  bool _isLoading = true;
  String? _estadoSeleccionado;

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
      final pedidos = await _dbService.obtenerPedidos();
      setState(() {
        _pedidos = pedidos;
        _aplicarFiltro();
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

  void _aplicarFiltro() {
    setState(() {
      if (_estadoSeleccionado == null) {
        _pedidosFiltrados = _pedidos;
      } else {
        _pedidosFiltrados = _pedidos
            .where((pedido) => pedido.estado == _estadoSeleccionado)
            .toList();
      }
    });
  }

  void _cambiarFiltroEstado(String? estado) {
    setState(() {
      _estadoSeleccionado = estado;
      _aplicarFiltro();
    });
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

  Future<void> _eliminarPedido(Pedido pedido) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar eliminación'),
        content: Text('¿Está seguro de eliminar el pedido ${pedido.codigoSeguimiento}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmar == true && pedido.id != null) {
      try {
        await _dbService.eliminarPedido(pedido.id!);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Pedido eliminado correctamente')),
          );
        }
        await _cargarPedidos();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al eliminar pedido: $e')),
          );
        }
      }
    }
  }

  Future<void> _navegarAFormulario() async {
    final resultado = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const PedidoFormScreen(),
      ),
    );

    if (resultado == true) {
      await _cargarPedidos();
    }
  }

  Future<void> _navegarADetalle(Pedido pedido) async {
    final resultado = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PedidoDetalleScreen(pedido: pedido),
      ),
    );

    if (resultado == true) {
      await _cargarPedidos();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pedidos'),
        elevation: 2,
      ),
      body: Column(
        children: [
          // Chips de filtro por estado
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  FilterChip(
                    label: const Text('Todos'),
                    selected: _estadoSeleccionado == null,
                    onSelected: (_) => _cambiarFiltroEstado(null),
                    selectedColor: Theme.of(context).colorScheme.primary,
                    labelStyle: TextStyle(
                      color: _estadoSeleccionado == null ? Colors.white : null,
                    ),
                  ),
                  const SizedBox(width: 8),
                  ...Pedido.estadosDisponibles.map((estado) {
                    final isSelected = _estadoSeleccionado == estado;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(estado),
                        selected: isSelected,
                        onSelected: (_) => _cambiarFiltroEstado(estado),
                        selectedColor: _getColorEstado(estado),
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : null,
                        ),
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _pedidosFiltrados.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.shopping_cart_outlined,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _estadoSeleccionado == null
                                  ? 'No hay pedidos registrados'
                                  : 'No hay pedidos en estado $_estadoSeleccionado',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _pedidosFiltrados.length,
                        itemBuilder: (context, index) {
                          final pedido = _pedidosFiltrados[index];
                          final colorEstado = _getColorEstado(pedido.estado);
                          return TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0.0, end: 1.0),
                            duration: Duration(milliseconds: 300 + (index * 50)),
                            curve: Curves.easeOutCubic,
                            builder: (context, value, child) {
                              return Opacity(
                                opacity: value,
                                child: Transform.translate(
                                  offset: Offset(0, 20 * (1 - value)),
                                  child: child,
                                ),
                              );
                            },
                            child: Card(
                              margin: const EdgeInsets.only(bottom: 16),
                              elevation: 3,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: InkWell(
                                onTap: () => _navegarADetalle(pedido),
                                borderRadius: BorderRadius.circular(20),
                                child: Container(
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(20),
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        Colors.white,
                                        colorEstado.withOpacity(0.05),
                                      ],
                                    ),
                                  ),
                                  child: Column(
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            width: 56,
                                            height: 56,
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                colors: [
                                                  colorEstado.withOpacity(0.8),
                                                  colorEstado,
                                                ],
                                              ),
                                              borderRadius: BorderRadius.circular(16),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: colorEstado.withOpacity(0.3),
                                                  blurRadius: 12,
                                                  offset: const Offset(0, 4),
                                                ),
                                              ],
                                            ),
                                            child: const Icon(
                                              Icons.receipt_long_rounded,
                                              color: Colors.white,
                                              size: 28,
                                            ),
                                          ),
                                          const SizedBox(width: 16),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  pedido.nombreCliente,
                                                  style: const TextStyle(
                                                    fontSize: 18,
                                                    fontWeight: FontWeight.bold,
                                                    letterSpacing: 0.2,
                                                  ),
                                                ),
                                                const SizedBox(height: 6),
                                                Row(
                                                  children: [
                                                    Icon(
                                                      Icons.qr_code_2_rounded,
                                                      size: 16,
                                                      color: Colors.grey[600],
                                                    ),
                                                    const SizedBox(width: 6),
                                                    Text(
                                                      pedido.codigoSeguimiento,
                                                      style: TextStyle(
                                                        fontFamily: 'monospace',
                                                        fontSize: 13,
                                                        fontWeight: FontWeight.w600,
                                                        color: Colors.grey[700],
                                                        letterSpacing: 1,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 14,
                                              vertical: 8,
                                            ),
                                            decoration: BoxDecoration(
                                              color: colorEstado,
                                              borderRadius: BorderRadius.circular(12),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: colorEstado.withOpacity(0.3),
                                                  blurRadius: 8,
                                                  offset: const Offset(0, 2),
                                                ),
                                              ],
                                            ),
                                            child: Text(
                                              pedido.estado,
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                                letterSpacing: 0.5,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 16),
                                      Container(
                                        height: 1,
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [
                                              Colors.grey[300]!,
                                              Colors.grey[100]!,
                                              Colors.grey[300]!,
                                            ],
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Row(
                                              children: [
                                                Container(
                                                  padding: const EdgeInsets.all(8),
                                                  decoration: BoxDecoration(
                                                    color: Colors.grey[100],
                                                    borderRadius: BorderRadius.circular(10),
                                                  ),
                                                  child: Icon(
                                                    Icons.calendar_today_rounded,
                                                    size: 18,
                                                    color: Colors.grey[700],
                                                  ),
                                                ),
                                                const SizedBox(width: 10),
                                                Text(
                                                  _formatoFecha.format(pedido.fecha),
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    color: Colors.grey[700],
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 20,
                                              vertical: 10,
                                            ),
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                colors: [
                                                  const Color(0xFF10B981),
                                                  const Color(0xFF059669),
                                                ],
                                              ),
                                              borderRadius: BorderRadius.circular(12),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: const Color(0xFF10B981).withOpacity(0.3),
                                                  blurRadius: 8,
                                                  offset: const Offset(0, 2),
                                                ),
                                              ],
                                            ),
                                            child: Row(
                                              children: [
                                                const Icon(
                                                  Icons.attach_money_rounded,
                                                  color: Colors.white,
                                                  size: 20,
                                                ),
                                                Text(
                                                  _formatoMoneda.format(pedido.total),
                                                  style: const TextStyle(
                                                    fontSize: 18,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Container(
                                            decoration: BoxDecoration(
                                              color: Colors.red[50],
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: IconButton(
                                              icon: Icon(
                                                Icons.delete_rounded,
                                                color: Colors.red[600],
                                                size: 22,
                                              ),
                                              onPressed: () => _eliminarPedido(pedido),
                                              tooltip: 'Eliminar pedido',
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navegarAFormulario,
        child: const Icon(Icons.add),
      ),
    );
  }
}
