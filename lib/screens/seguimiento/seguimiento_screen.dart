import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/pedido.dart';
import '../../services/database_service.dart';

class SeguimientoScreen extends StatefulWidget {
  const SeguimientoScreen({super.key});

  @override
  State<SeguimientoScreen> createState() => _SeguimientoScreenState();
}

class _SeguimientoScreenState extends State<SeguimientoScreen> {
  final _busquedaController = TextEditingController();
  final DatabaseService _dbService = DatabaseService();
  final NumberFormat _formatoMoneda = NumberFormat.currency(symbol: '\$', decimalDigits: 2);
  final DateFormat _formatoFecha = DateFormat('dd/MM/yyyy HH:mm');

  Pedido? _pedidoEncontrado;
  bool _buscando = false;
  bool _noBuscado = true;

  @override
  void dispose() {
    _busquedaController.dispose();
    super.dispose();
  }

  Future<void> _buscarPedido() async {
    final texto = _busquedaController.text.trim();

    if (texto.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingrese un código o nombre de cliente')),
      );
      return;
    }

    setState(() {
      _buscando = true;
      _noBuscado = false;
      _pedidoEncontrado = null;
    });

    try {
      // Buscar primero por código
      Pedido? pedido = await _dbService.buscarPedidoPorCodigo(texto);

      // Si no se encuentra, buscar por nombre de cliente
      if (pedido == null) {
        final pedidos = await _dbService.buscarPedidosPorNombreCliente(texto);
        if (pedidos.isNotEmpty) {
          pedido = pedidos.first;
        }
      }

      setState(() {
        _pedidoEncontrado = pedido;
        _buscando = false;
      });
    } catch (e) {
      setState(() {
        _buscando = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al buscar: $e')),
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

  int _getIndiceEstado(String estado) {
    switch (estado) {
      case 'Pendiente':
        return 0;
      case 'En Producción':
        return 1;
      case 'Finalizado':
        return 2;
      case 'Entregado':
        return 3;
      default:
        return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Seguimiento de Pedido'),
        elevation: 2,
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Banner de bienvenida
            Card(
              color: Colors.teal.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Icon(
                      Icons.track_changes,
                      size: 48,
                      color: Colors.teal,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Rastrea tu pedido',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Ingresa tu código de seguimiento o nombre',
                      style: TextStyle(
                        color: Colors.grey[700],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Campo de búsqueda
            TextField(
              controller: _busquedaController,
              decoration: InputDecoration(
                labelText: 'Código de seguimiento o nombre',
                hintText: 'Ej: ABC12345 o Juan Pérez',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                suffixIcon: _busquedaController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _busquedaController.clear();
                          setState(() {
                            _pedidoEncontrado = null;
                            _noBuscado = true;
                          });
                        },
                      )
                    : null,
              ),
              onChanged: (value) {
                setState(() {});
              },
              onSubmitted: (_) => _buscarPedido(),
              textCapitalization: TextCapitalization.characters,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _buscando ? null : _buscarPedido,
              icon: _buscando
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(Icons.search),
              label: Text(_buscando ? 'Buscando...' : 'Buscar Pedido'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                textStyle: const TextStyle(fontSize: 16),
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 32),
            // Resultados
            if (_buscando)
              const Center(
                child: CircularProgressIndicator(),
              )
            else if (_noBuscado)
              Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 64,
                      color: Colors.grey[300],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Ingresa un código para rastrear tu pedido',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              )
            else if (_pedidoEncontrado == null)
              Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.search_off,
                      size: 64,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'No se encontró el pedido',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Verifica el código o nombre ingresado',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              )
            else
              _buildResultadoPedido(_pedidoEncontrado!),
          ],
        ),
      ),
    );
  }

  Widget _buildResultadoPedido(Pedido pedido) {
    final indiceActual = _getIndiceEstado(pedido.estado);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Información del pedido
        Card(
          elevation: 4,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Información del Pedido',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Divider(),
                const SizedBox(height: 8),
                _buildInfoRow(Icons.qr_code, 'Código', pedido.codigoSeguimiento),
                const SizedBox(height: 8),
                _buildInfoRow(Icons.person, 'Cliente', pedido.nombreCliente),
                const SizedBox(height: 8),
                _buildInfoRow(Icons.calendar_today, 'Fecha', _formatoFecha.format(pedido.fecha)),
                const SizedBox(height: 8),
                _buildInfoRow(Icons.attach_money, 'Total', _formatoMoneda.format(pedido.total)),
                const SizedBox(height: 16),
                Center(
                  child: Badge(
                    label: Text(
                      pedido.estado.toUpperCase(),
                      style: const TextStyle(fontSize: 16),
                    ),
                    backgroundColor: _getColorEstado(pedido.estado),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        // Timeline de progreso
        Card(
          elevation: 4,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Progreso del Pedido',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Divider(),
                const SizedBox(height: 16),
                _buildTimelineItem(
                  'Pendiente',
                  'Tu pedido ha sido registrado',
                  Icons.receipt_long,
                  0,
                  indiceActual,
                ),
                _buildTimelineItem(
                  'En Producción',
                  'Estamos trabajando en tu pedido',
                  Icons.construction,
                  1,
                  indiceActual,
                ),
                _buildTimelineItem(
                  'Finalizado',
                  'Tu pedido está listo',
                  Icons.check_circle,
                  2,
                  indiceActual,
                ),
                _buildTimelineItem(
                  'Entregado',
                  'Pedido completado y entregado',
                  Icons.local_shipping,
                  3,
                  indiceActual,
                  isLast: true,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.teal),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 14),
          ),
        ),
      ],
    );
  }

  Widget _buildTimelineItem(
    String titulo,
    String descripcion,
    IconData icono,
    int indice,
    int indiceActual, {
    bool isLast = false,
  }) {
    final completado = indice <= indiceActual;
    final activo = indice == indiceActual;
    final color = completado ? Colors.teal : Colors.grey;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: activo ? color : Colors.transparent,
                border: Border.all(
                  color: color,
                  width: 2,
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icono,
                color: activo ? Colors.white : color,
                size: 20,
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 40,
                color: completado ? color : Colors.grey.shade300,
              ),
          ],
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: completado ? Colors.black : Colors.grey,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  descripcion,
                  style: TextStyle(
                    fontSize: 14,
                    color: completado ? Colors.grey[700] : Colors.grey[400],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
