import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../models/gasto.dart';
import '../../services/database_service.dart';

class GastoFormScreen extends StatefulWidget {
  final Gasto? gasto;

  const GastoFormScreen({super.key, this.gasto});

  @override
  State<GastoFormScreen> createState() => _GastoFormScreenState();
}

class _GastoFormScreenState extends State<GastoFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final DatabaseService _dbService = DatabaseService();
  final DateFormat _formatoFecha = DateFormat('dd/MM/yyyy');

  late TextEditingController _conceptoController;
  late TextEditingController _montoController;

  String? _areaSeleccionada;
  DateTime _fechaSeleccionada = DateTime.now();
  bool _isLoading = false;
  bool get _isEditing => widget.gasto != null;

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
    _conceptoController = TextEditingController(text: widget.gasto?.concepto ?? '');
    _montoController = TextEditingController(
      text: widget.gasto?.monto.toString() ?? '',
    );
    _areaSeleccionada = widget.gasto?.area;
    _fechaSeleccionada = widget.gasto?.fecha ?? DateTime.now();
  }

  @override
  void dispose() {
    _conceptoController.dispose();
    _montoController.dispose();
    super.dispose();
  }

  String? _validarConcepto(String? value) {
    if (value == null || value.isEmpty) {
      return 'El concepto es obligatorio';
    }
    if (value.length < 3) {
      return 'El concepto debe tener al menos 3 caracteres';
    }
    return null;
  }

  String? _validarArea(String? value) {
    if (value == null || value.isEmpty) {
      return 'Debe seleccionar un área';
    }
    return null;
  }

  String? _validarMonto(String? value) {
    if (value == null || value.isEmpty) {
      return 'El monto es obligatorio';
    }
    final monto = double.tryParse(value);
    if (monto == null) {
      return 'Monto inválido';
    }
    if (monto <= 0) {
      return 'El monto debe ser mayor a 0';
    }
    return null;
  }

  Future<void> _seleccionarFecha() async {
    final fecha = await showDatePicker(
      context: context,
      initialDate: _fechaSeleccionada,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      locale: const Locale('es', 'ES'),
    );

    if (fecha != null) {
      setState(() {
        _fechaSeleccionada = fecha;
      });
    }
  }

  Future<void> _guardarGasto() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final gasto = Gasto(
        id: widget.gasto?.id,
        concepto: _conceptoController.text.trim(),
        monto: double.parse(_montoController.text.trim()),
        area: _areaSeleccionada!,
        fecha: _fechaSeleccionada,
      );

      if (_isEditing) {
        await _dbService.actualizarGasto(gasto);
      } else {
        await _dbService.crearGasto(gasto);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isEditing
                  ? 'Gasto actualizado correctamente'
                  : 'Gasto creado correctamente',
            ),
          ),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al guardar gasto: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Editar Gasto' : 'Nuevo Gasto'),
        elevation: 2,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Información del Gasto',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _conceptoController,
                        decoration: const InputDecoration(
                          labelText: 'Concepto del gasto',
                          hintText: 'Ej: Compra de papel',
                          prefixIcon: Icon(Icons.description),
                          border: OutlineInputBorder(),
                        ),
                        validator: _validarConcepto,
                        textCapitalization: TextCapitalization.sentences,
                        enabled: !_isLoading,
                        maxLines: 2,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _montoController,
                        decoration: const InputDecoration(
                          labelText: 'Monto',
                          hintText: 'Ej: 150.00',
                          prefixIcon: Icon(Icons.attach_money),
                          prefixText: '\$ ',
                          border: OutlineInputBorder(),
                        ),
                        validator: _validarMonto,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                            RegExp(r'^\d+\.?\d{0,2}'),
                          ),
                        ],
                        enabled: !_isLoading,
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: _areaSeleccionada,
                        decoration: const InputDecoration(
                          labelText: 'Área',
                          prefixIcon: Icon(Icons.category),
                          border: OutlineInputBorder(),
                        ),
                        hint: const Text('Seleccione un área'),
                        items: _areas.map((area) {
                          return DropdownMenuItem(
                            value: area,
                            child: Text(area),
                          );
                        }).toList(),
                        onChanged: _isLoading
                            ? null
                            : (value) {
                                setState(() {
                                  _areaSeleccionada = value;
                                });
                              },
                        validator: _validarArea,
                      ),
                      const SizedBox(height: 16),
                      InkWell(
                        onTap: _isLoading ? null : _seleccionarFecha,
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Fecha del gasto',
                            prefixIcon: Icon(Icons.calendar_today),
                            border: OutlineInputBorder(),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _formatoFecha.format(_fechaSeleccionada),
                                style: const TextStyle(fontSize: 16),
                              ),
                              const Icon(Icons.arrow_drop_down),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _isLoading ? null : _guardarGasto,
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
                label: Text(
                  _isLoading
                      ? 'Guardando...'
                      : _isEditing
                          ? 'Actualizar Gasto'
                          : 'Guardar Gasto',
                ),
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
