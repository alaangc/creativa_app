import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/gasto.dart';
import '../../services/database_service.dart';
import 'gasto_form_screen.dart';

class GastosScreen extends StatefulWidget {
  const GastosScreen({super.key});

  @override
  State<GastosScreen> createState() => _GastosScreenState();
}

class _GastosScreenState extends State<GastosScreen> {
  final DatabaseService _dbService = DatabaseService();
  final NumberFormat _formatoMoneda = NumberFormat.currency(symbol: '\$', decimalDigits: 2);
  final DateFormat _formatoFecha = DateFormat('dd/MM/yyyy');

  List<Gasto> _gastos = [];
  List<Gasto> _gastosFiltrados = [];
  bool _isLoading = true;
  String? _areaSeleccionada;

  final List<String> _areas = [
    'Impresión',
    'Vinil',
    'Camisetas',
    'Lonas',
    'Publicidad',
  ];

  @override
  void initState() {
    super.initState();
    _cargarGastos();
  }

  Future<void> _cargarGastos() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final gastos = await _dbService.obtenerGastos();
      setState(() {
        _gastos = gastos;
        _aplicarFiltro();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar gastos: $e')),
        );
      }
    }
  }

  void _aplicarFiltro() {
    setState(() {
      if (_areaSeleccionada == null) {
        _gastosFiltrados = _gastos;
      } else {
        _gastosFiltrados = _gastos
            .where((gasto) => gasto.area == _areaSeleccionada)
            .toList();
      }
    });
  }

  void _cambiarFiltroArea(String? area) {
    setState(() {
      _areaSeleccionada = area;
      _aplicarFiltro();
    });
  }

  double _calcularTotal() {
    return _gastosFiltrados.fold(0.0, (sum, gasto) => sum + gasto.monto);
  }

  Color _getColorArea(String area) {
    switch (area) {
      case 'Impresión':
        return Colors.blue;
      case 'Vinil':
        return Colors.orange;
      case 'Camisetas':
        return Colors.green;
      case 'Lonas':
        return Colors.purple;
      case 'Publicidad':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Future<void> _eliminarGasto(Gasto gasto) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar eliminación'),
        content: Text('¿Está seguro de eliminar el gasto "${gasto.concepto}"?'),
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

    if (confirmar == true && gasto.id != null) {
      try {
        await _dbService.eliminarGasto(gasto.id!);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Gasto eliminado correctamente')),
          );
        }
        await _cargarGastos();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al eliminar gasto: $e')),
          );
        }
      }
    }
  }

  Future<void> _navegarAFormulario([Gasto? gasto]) async {
    final resultado = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GastoFormScreen(gasto: gasto),
      ),
    );

    if (resultado == true) {
      await _cargarGastos();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gastos'),
        elevation: 2,
      ),
      body: Column(
        children: [
          // Tarjeta de total
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(16),
            child: Card(
              elevation: 4,
              color: Colors.red.shade50,
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.account_balance_wallet,
                          size: 32,
                          color: Colors.red.shade700,
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Total de Gastos',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                            Text(
                              _formatoMoneda.format(_calcularTotal()),
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Colors.red.shade700,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    if (_areaSeleccionada != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Área: $_areaSeleccionada',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          // Chips de filtro por área
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  FilterChip(
                    label: const Text('Todos'),
                    selected: _areaSeleccionada == null,
                    onSelected: (_) => _cambiarFiltroArea(null),
                    selectedColor: Theme.of(context).colorScheme.primary,
                    labelStyle: TextStyle(
                      color: _areaSeleccionada == null ? Colors.white : null,
                    ),
                  ),
                  const SizedBox(width: 8),
                  ..._areas.map((area) {
                    final isSelected = _areaSeleccionada == area;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(area),
                        selected: isSelected,
                        onSelected: (_) => _cambiarFiltroArea(area),
                        selectedColor: _getColorArea(area),
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
                : _gastosFiltrados.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.receipt_long_outlined,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _areaSeleccionada == null
                                  ? 'No hay gastos registrados'
                                  : 'No hay gastos en $_areaSeleccionada',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: _gastosFiltrados.length,
                        itemBuilder: (context, index) {
                          final gasto = _gastosFiltrados[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: _getColorArea(gasto.area),
                                child: const Icon(
                                  Icons.receipt,
                                  color: Colors.white,
                                ),
                              ),
                              title: Text(
                                gasto.concepto,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 4),
                                  Chip(
                                    label: Text(
                                      gasto.area,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.white,
                                      ),
                                    ),
                                    backgroundColor: _getColorArea(gasto.area),
                                    padding: EdgeInsets.zero,
                                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                                      const SizedBox(width: 4),
                                      Text(_formatoFecha.format(gasto.fecha)),
                                    ],
                                  ),
                                ],
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    _formatoMoneda.format(gasto.monto),
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.red.shade700,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.red),
                                    onPressed: () => _eliminarGasto(gasto),
                                  ),
                                ],
                              ),
                              onTap: () => _navegarAFormulario(gasto),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navegarAFormulario(),
        child: const Icon(Icons.add),
      ),
    );
  }
}
