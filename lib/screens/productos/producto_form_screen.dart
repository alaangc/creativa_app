import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/producto.dart';
import '../../services/database_service.dart';

class ProductoFormScreen extends StatefulWidget {
  final Producto? producto;

  const ProductoFormScreen({super.key, this.producto});

  @override
  State<ProductoFormScreen> createState() => _ProductoFormScreenState();
}

class _ProductoFormScreenState extends State<ProductoFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final DatabaseService _dbService = DatabaseService();

  late TextEditingController _nombreController;
  late TextEditingController _precioController;
  late TextEditingController _descripcionController;

  String? _areaSeleccionada;
  bool _isLoading = false;
  bool get _isEditing => widget.producto != null;

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
    _nombreController = TextEditingController(text: widget.producto?.nombre ?? '');
    _precioController = TextEditingController(
      text: widget.producto?.precio.toString() ?? '',
    );
    _descripcionController = TextEditingController(
      text: widget.producto?.descripcion ?? '',
    );
    _areaSeleccionada = widget.producto?.area;
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _precioController.dispose();
    _descripcionController.dispose();
    super.dispose();
  }

  String? _validarNombre(String? value) {
    if (value == null || value.isEmpty) {
      return 'El nombre es obligatorio';
    }
    if (value.length < 3) {
      return 'El nombre debe tener al menos 3 caracteres';
    }
    return null;
  }

  String? _validarArea(String? value) {
    if (value == null || value.isEmpty) {
      return 'Debe seleccionar un área';
    }
    return null;
  }

  String? _validarPrecio(String? value) {
    if (value == null || value.isEmpty) {
      return 'El precio es obligatorio';
    }
    final precio = double.tryParse(value);
    if (precio == null) {
      return 'Precio inválido';
    }
    if (precio <= 0) {
      return 'El precio debe ser mayor a 0';
    }
    return null;
  }

  String? _validarDescripcion(String? value) {
    if (value == null || value.isEmpty) {
      return 'La descripción es obligatoria';
    }
    if (value.length < 10) {
      return 'La descripción debe tener al menos 10 caracteres';
    }
    return null;
  }

  Future<void> _guardarProducto() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final producto = Producto(
        id: widget.producto?.id,
        nombre: _nombreController.text.trim(),
        area: _areaSeleccionada!,
        precio: double.parse(_precioController.text.trim()),
        descripcion: _descripcionController.text.trim(),
      );

      if (_isEditing) {
        await _dbService.actualizarProducto(producto);
      } else {
        await _dbService.crearProducto(producto);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isEditing
                  ? 'Producto actualizado correctamente'
                  : 'Producto creado correctamente',
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
          SnackBar(content: Text('Error al guardar producto: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Editar Producto' : 'Nuevo Producto'),
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
                        'Información del Producto',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _nombreController,
                        decoration: const InputDecoration(
                          labelText: 'Nombre del producto',
                          hintText: 'Ej: Tarjetas de presentación',
                          prefixIcon: Icon(Icons.inventory_2),
                          border: OutlineInputBorder(),
                        ),
                        validator: _validarNombre,
                        textCapitalization: TextCapitalization.words,
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
                      TextFormField(
                        controller: _precioController,
                        decoration: const InputDecoration(
                          labelText: 'Precio',
                          hintText: 'Ej: 150.00',
                          prefixIcon: Icon(Icons.attach_money),
                          prefixText: '\$ ',
                          border: OutlineInputBorder(),
                        ),
                        validator: _validarPrecio,
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
                      TextFormField(
                        controller: _descripcionController,
                        decoration: const InputDecoration(
                          labelText: 'Descripción',
                          hintText: 'Describe el producto...',
                          prefixIcon: Icon(Icons.description),
                          border: OutlineInputBorder(),
                        ),
                        validator: _validarDescripcion,
                        maxLines: 4,
                        textCapitalization: TextCapitalization.sentences,
                        enabled: !_isLoading,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _isLoading ? null : _guardarProducto,
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
                          ? 'Actualizar Producto'
                          : 'Guardar Producto',
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
