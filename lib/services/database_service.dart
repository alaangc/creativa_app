import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import 'package:path/path.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../models/cliente.dart';
import '../models/producto.dart';
import '../models/pedido.dart';
import '../models/gasto.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  static Database? _database;

  factory DatabaseService() {
    return _instance;
  }

  DatabaseService._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    // Inicializar factory para web
    if (kIsWeb) {
      databaseFactory = databaseFactoryFfiWeb;
      // En web, usar un path simple sin getDatabasesPath()
      return await databaseFactory.openDatabase(
        'creativa_app.db',
        options: OpenDatabaseOptions(
          version: 1,
          onCreate: _onCreate,
        ),
      );
    }

    // Para plataformas nativas (Android, iOS, Windows)
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, 'creativa_app.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Crear tabla de clientes
    await db.execute('''
      CREATE TABLE clientes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nombre TEXT NOT NULL,
        telefono TEXT NOT NULL,
        email TEXT NOT NULL,
        fechaRegistro TEXT NOT NULL
      )
    ''');

    // Crear tabla de productos
    await db.execute('''
      CREATE TABLE productos (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nombre TEXT NOT NULL,
        area TEXT NOT NULL,
        precio REAL NOT NULL,
        descripcion TEXT NOT NULL
      )
    ''');

    // Crear tabla de pedidos
    await db.execute('''
      CREATE TABLE pedidos (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        codigoSeguimiento TEXT NOT NULL UNIQUE,
        clienteId INTEGER NOT NULL,
        nombreCliente TEXT NOT NULL,
        fecha TEXT NOT NULL,
        estado TEXT NOT NULL,
        total REAL NOT NULL,
        FOREIGN KEY (clienteId) REFERENCES clientes (id)
      )
    ''');

    // Crear tabla de gastos
    await db.execute('''
      CREATE TABLE gastos (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        concepto TEXT NOT NULL,
        monto REAL NOT NULL,
        area TEXT NOT NULL,
        fecha TEXT NOT NULL
      )
    ''');
  }

  // ==================== CRUD CLIENTES ====================

  Future<int> crearCliente(Cliente cliente) async {
    final db = await database;
    return await db.insert('clientes', cliente.toMap());
  }

  Future<List<Cliente>> obtenerClientes() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('clientes');
    return List.generate(maps.length, (i) => Cliente.fromMap(maps[i]));
  }

  Future<Cliente?> obtenerClientePorId(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'clientes',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return Cliente.fromMap(maps.first);
  }

  Future<List<Cliente>> buscarClientesPorNombre(String nombre) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'clientes',
      where: 'nombre LIKE ?',
      whereArgs: ['%$nombre%'],
    );
    return List.generate(maps.length, (i) => Cliente.fromMap(maps[i]));
  }

  Future<int> actualizarCliente(Cliente cliente) async {
    final db = await database;
    return await db.update(
      'clientes',
      cliente.toMap(),
      where: 'id = ?',
      whereArgs: [cliente.id],
    );
  }

  Future<int> eliminarCliente(int id) async {
    final db = await database;
    return await db.delete(
      'clientes',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ==================== CRUD PRODUCTOS ====================

  Future<int> crearProducto(Producto producto) async {
    final db = await database;
    return await db.insert('productos', producto.toMap());
  }

  Future<List<Producto>> obtenerProductos() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('productos');
    return List.generate(maps.length, (i) => Producto.fromMap(maps[i]));
  }

  Future<Producto?> obtenerProductoPorId(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'productos',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return Producto.fromMap(maps.first);
  }

  Future<List<Producto>> filtrarProductosPorArea(String area) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'productos',
      where: 'area = ?',
      whereArgs: [area],
    );
    return List.generate(maps.length, (i) => Producto.fromMap(maps[i]));
  }

  Future<int> actualizarProducto(Producto producto) async {
    final db = await database;
    return await db.update(
      'productos',
      producto.toMap(),
      where: 'id = ?',
      whereArgs: [producto.id],
    );
  }

  Future<int> eliminarProducto(int id) async {
    final db = await database;
    return await db.delete(
      'productos',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ==================== CRUD PEDIDOS ====================

  Future<int> crearPedido(Pedido pedido) async {
    final db = await database;
    return await db.insert('pedidos', pedido.toMap());
  }

  Future<List<Pedido>> obtenerPedidos() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('pedidos');
    return List.generate(maps.length, (i) => Pedido.fromMap(maps[i]));
  }

  Future<Pedido?> obtenerPedidoPorId(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'pedidos',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return Pedido.fromMap(maps.first);
  }

  Future<Pedido?> buscarPedidoPorCodigo(String codigoSeguimiento) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'pedidos',
      where: 'codigoSeguimiento = ?',
      whereArgs: [codigoSeguimiento],
    );
    if (maps.isEmpty) return null;
    return Pedido.fromMap(maps.first);
  }

  Future<List<Pedido>> buscarPedidosPorNombreCliente(String nombreCliente) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'pedidos',
      where: 'nombreCliente LIKE ?',
      whereArgs: ['%$nombreCliente%'],
    );
    return List.generate(maps.length, (i) => Pedido.fromMap(maps[i]));
  }

  Future<int> actualizarEstadoPedido(int id, String nuevoEstado) async {
    final db = await database;
    return await db.update(
      'pedidos',
      {'estado': nuevoEstado},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> actualizarPedido(Pedido pedido) async {
    final db = await database;
    return await db.update(
      'pedidos',
      pedido.toMap(),
      where: 'id = ?',
      whereArgs: [pedido.id],
    );
  }

  Future<int> eliminarPedido(int id) async {
    final db = await database;
    return await db.delete(
      'pedidos',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ==================== CRUD GASTOS ====================

  Future<int> crearGasto(Gasto gasto) async {
    final db = await database;
    return await db.insert('gastos', gasto.toMap());
  }

  Future<List<Gasto>> obtenerGastos() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('gastos');
    return List.generate(maps.length, (i) => Gasto.fromMap(maps[i]));
  }

  Future<Gasto?> obtenerGastoPorId(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'gastos',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return Gasto.fromMap(maps.first);
  }

  Future<List<Gasto>> filtrarGastosPorArea(String area) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'gastos',
      where: 'area = ?',
      whereArgs: [area],
    );
    return List.generate(maps.length, (i) => Gasto.fromMap(maps[i]));
  }

  Future<int> actualizarGasto(Gasto gasto) async {
    final db = await database;
    return await db.update(
      'gastos',
      gasto.toMap(),
      where: 'id = ?',
      whereArgs: [gasto.id],
    );
  }

  Future<int> eliminarGasto(int id) async {
    final db = await database;
    return await db.delete(
      'gastos',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ==================== MÉTODOS ADICIONALES ====================

  Future<void> insertarDatosDePrueba() async {
    // Verificar si la base de datos ya tiene datos
    final clientes = await obtenerClientes();
    if (clientes.isNotEmpty) {
      return; // Ya hay datos, no insertar nada
    }

    const uuid = Uuid();

    // Insertar 3 clientes de ejemplo
    final cliente1 = Cliente(
      nombre: 'Juan Pérez',
      telefono: '555-0101',
      email: 'juan.perez@email.com',
      fechaRegistro: DateTime.now().subtract(const Duration(days: 30)),
    );
    final cliente2 = Cliente(
      nombre: 'María García',
      telefono: '555-0102',
      email: 'maria.garcia@email.com',
      fechaRegistro: DateTime.now().subtract(const Duration(days: 20)),
    );
    final cliente3 = Cliente(
      nombre: 'Carlos López',
      telefono: '555-0103',
      email: 'carlos.lopez@email.com',
      fechaRegistro: DateTime.now().subtract(const Duration(days: 10)),
    );

    final clienteId1 = await crearCliente(cliente1);
    final clienteId2 = await crearCliente(cliente2);
    final clienteId3 = await crearCliente(cliente3);

    // Insertar 5 productos (uno por cada área)
    await crearProducto(Producto(
      nombre: 'Impresión Digital A4',
      area: 'Impresión',
      precio: 50.00,
      descripcion: 'Impresión digital en papel A4 de alta calidad',
    ));

    await crearProducto(Producto(
      nombre: 'Vinil Autoadhesivo',
      area: 'Vinil',
      precio: 150.00,
      descripcion: 'Vinil autoadhesivo para exterior, resistente al agua',
    ));

    await crearProducto(Producto(
      nombre: 'Camiseta Estampada',
      area: 'Camisetas',
      precio: 120.00,
      descripcion: 'Camiseta de algodón con estampado personalizado',
    ));

    await crearProducto(Producto(
      nombre: 'Lona Publicitaria',
      area: 'Lonas',
      precio: 300.00,
      descripcion: 'Lona publicitaria de gran formato para exteriores',
    ));

    await crearProducto(Producto(
      nombre: 'Diseño de Logo',
      area: 'Publicidad',
      precio: 500.00,
      descripcion: 'Diseño profesional de logotipo empresarial',
    ));

    // Insertar 2 pedidos de ejemplo
    final pedido1 = Pedido(
      codigoSeguimiento: uuid.v4().split('-').first.toUpperCase(),
      clienteId: clienteId1,
      nombreCliente: 'Juan Pérez',
      fecha: DateTime.now().subtract(const Duration(days: 5)),
      estado: Pedido.estadoEnProduccion,
      total: 350.00,
    );

    final pedido2 = Pedido(
      codigoSeguimiento: uuid.v4().split('-').first.toUpperCase(),
      clienteId: clienteId2,
      nombreCliente: 'María García',
      fecha: DateTime.now().subtract(const Duration(days: 2)),
      estado: Pedido.estadoPendiente,
      total: 620.00,
    );

    await crearPedido(pedido1);
    await crearPedido(pedido2);
  }

  Future<void> cerrarBaseDatos() async {
    final db = await database;
    await db.close();
  }
}
