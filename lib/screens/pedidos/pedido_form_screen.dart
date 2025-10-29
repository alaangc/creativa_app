import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../models/pedido.dart';
import '../../models/cliente.dart';
import '../../models/producto.dart';
import '../../services/database_service.dart';

class PedidoFormScreen extends StatefulWidget {
  const PedidoFormScreen({super.key});

  @override
  State<PedidoFormScreen> createState() => _PedidoFormScreenState();
}

class _PedidoFormScreenState extends State<PedidoFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final DatabaseService _dbService = DatabaseService();
  final NumberFormat _formatoMoneda = NumberFormat.currency(symbol: '\$', decimalDigits: 2);

  List<Cliente> _clientes = [];
  List<Producto> _productos = [];
  Cliente? _clienteSeleccionado;

  final List<_ProductoConCantidad> _productosAgregados = [];

  bool _isLoading = false;
  bool _cargandoDatos = true;
  String _codigoSeguimiento = '';

  @override
  void initState() {
    super.initState();
    _generarCodigoSeguimiento();
    _cargarDatos();
  }

  void _generarCodigoSeguimiento() {
    const uuid = Uuid();
    final codigo = uuid.v4().split('-').first.toUpperCase();
    setState(() {
      _codigoSeguimiento = codigo;
    });
  }

  Future<void> _cargarDatos() async {
    try {
      final clientes = await _dbService.obtenerClientes();
      final productos = await _dbService.obtenerProductos();

      setState(() {
        _clientes = clientes;
        _productos = productos;
        _cargandoDatos = false;
      });
    } catch (e) {
      setState(() {
        _cargandoDatos = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar datos: $e')),
        );
      }
    }
  }

  double _calcularTotal() {
    double total = 0.0;
    for (var item in _productosAgregados) {
      total += item.producto.precio * item.cantidad;
    }
    return total;
  }

  void _agregarProducto(Producto producto, int cantidad) {
    setState(() {
      final index = _productosAgregados.indexWhere(
        (item) => item.producto.id == producto.id,
      );

      if (index >= 0) {
        _productosAgregados[index].cantidad += cantidad;
      } else {
        _productosAgregados.add(_ProductoConCantidad(producto, cantidad));
      }
    });
  }

  void _eliminarProducto(int index) {
    setState(() {
      _productosAgregados.removeAt(index);
    });
  }

  Future<void> _mostrarDialogoAgregarProducto() async {
    if (_productos.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hay productos disponibles')),
      );
      return;
    }

    Producto? productoSeleccionado;
    int cantidad = 1;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Agregar Producto'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<Producto>(
                value: productoSeleccionado,
                decoration: const InputDecoration(
                  labelText: 'Producto',
                  border: OutlineInputBorder(),
                ),
                items: _productos.map((producto) {
                  return DropdownMenuItem(
                    value: producto,
                    child: Text('${producto.nombre} - ${_formatoMoneda.format(producto.precio)}'),
                  );
                }).toList(),
                onChanged: (value) {
                  setDialogState(() {
                    productoSeleccionado = value;
                  });
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Cantidad',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                initialValue: '1',
                onChanged: (value) {
                  cantidad = int.tryParse(value) ?? 1;
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                if (productoSeleccionado != null && cantidad > 0) {
                  _agregarProducto(productoSeleccionado!, cantidad);
                  Navigator.pop(context);
                }
              },
              child: const Text('Agregar'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _guardarPedido() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_clienteSeleccionado == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Debe seleccionar un cliente')),
      );
      return;
    }

    if (_productosAgregados.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Debe agregar al menos un producto')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final pedido = Pedido(
        codigoSeguimiento: _codigoSeguimiento,
        clienteId: _clienteSeleccionado!.id!,
        nombreCliente: _clienteSeleccionado!.nombre,
        fecha: DateTime.now(),
        estado: Pedido.estadoPendiente,
        total: _calcularTotal(),
      );

      await _dbService.crearPedido(pedido);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pedido creado correctamente')),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al guardar pedido: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_cargandoDatos) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nuevo Pedido'),
        elevation: 2,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Código de seguimiento
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      const Icon(Icons.qr_code, size: 32),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Código de Seguimiento',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                          Text(
                            _codigoSeguimiento,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.refresh),
                        onPressed: _generarCodigoSeguimiento,
                        tooltip: 'Generar nuevo código',
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Cliente
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Cliente',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<Cliente>(
                        value: _clienteSeleccionado,
                        decoration: const InputDecoration(
                          labelText: 'Seleccionar cliente',
                          prefixIcon: Icon(Icons.person),
                          border: OutlineInputBorder(),
                        ),
                        items: _clientes.map((cliente) {
                          return DropdownMenuItem(
                            value: cliente,
                            child: Text(cliente.nombre),
                          );
                        }).toList(),
                        onChanged: _isLoading
                            ? null
                            : (value) {
                                setState(() {
                                  _clienteSeleccionado = value;
                                });
                              },
                        validator: (value) {
                          if (value == null) {
                            return 'Debe seleccionar un cliente';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Productos
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Productos',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          ElevatedButton.icon(
                            onPressed: _isLoading ? null : _mostrarDialogoAgregarProducto,
                            icon: const Icon(Icons.add),
                            label: const Text('Agregar'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (_productosAgregados.isEmpty)
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: Text(
                              'No hay productos agregados',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          ),
                        )
                      else
                        ..._productosAgregados.asMap().entries.map((entry) {
                          final index = entry.key;
                          final item = entry.value;
                          final subtotal = item.producto.precio * item.cantidad;

                          return ListTile(
                            leading: CircleAvatar(
                              child: Text('${item.cantidad}x'),
                            ),
                            title: Text(item.producto.nombre),
                            subtitle: Text(
                              '${_formatoMoneda.format(item.producto.precio)} c/u',
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _formatoMoneda.format(subtotal),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () => _eliminarProducto(index),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      if (_productosAgregados.isNotEmpty) ...[
                        const Divider(),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'TOTAL:',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                _formatoMoneda.format(_calcularTotal()),
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _isLoading ? null : _guardarPedido,
                icon: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Icon(Icons.save),
                label: Text(_isLoading ? 'Guardando...' : 'Crear Pedido'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(fontSize: 16),
                ),
              ),
              const SizedBox(height: 16),
              if (!_isLoading)
                OutlinedButton.icon(
                  onPressed: () => Navigator.of(context).pop(false),
                  icon: const Icon(Icons.cancel),
                  label: const Text('Cancelar'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF6C757D), // Gris para cancelar
                    side: const BorderSide(color: Color(0xFF6C757D)),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    textStyle: const TextStyle(fontSize: 16),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProductoConCantidad {
  final Producto producto;
  int cantidad;

  _ProductoConCantidad(this.producto, this.cantidad);
}
