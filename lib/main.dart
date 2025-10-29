import 'package:flutter/material.dart';
import 'services/database_service.dart';
import 'screens/home_screen.dart';
import 'screens/clientes/clientes_screen.dart';
import 'screens/clientes/cliente_form_screen.dart';
import 'screens/productos/productos_screen.dart';
import 'screens/productos/producto_form_screen.dart';
import 'screens/pedidos/pedidos_screen.dart';
import 'screens/pedidos/pedido_form_screen.dart';
import 'screens/areas/areas_screen.dart';
import 'screens/gastos/gastos_screen.dart';
import 'screens/gastos/gasto_form_screen.dart';
import 'screens/seguimiento/seguimiento_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Inicializar base de datos
    final dbService = DatabaseService();
    await dbService.database;

    // Insertar datos de prueba si la base de datos está vacía
    await dbService.insertarDatosDePrueba();
  } catch (e) {
    // Si hay error en la base de datos, mostrar en consola pero continuar
    print('Error al inicializar la base de datos: $e');
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CREATIVA',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFFF6B35), // Naranja corporativo
          secondary: const Color(0xFF2D2D2D), // Negro corporativo
          brightness: Brightness.light,
          primary: const Color(0xFFFF6B35),
          onPrimary: Colors.white,
          surface: Colors.white,
          onSurface: const Color(0xFF2D2D2D),
        ),
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 2,
          backgroundColor: Colors.white, // Fondo blanco
          foregroundColor: Color(0xFF2D2D2D), // Negro para iconos
          shadowColor: Colors.black12,
          titleTextStyle: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2D2D2D), // Negro para el título
            letterSpacing: 1.2,
          ),
        ),
        cardTheme: CardThemeData(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          clipBehavior: Clip.antiAlias,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            elevation: 3,
            backgroundColor: const Color(0xFFFF6B35), // Naranja corporativo
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          elevation: 6,
          backgroundColor: Color(0xFFFF6B35), // Naranja corporativo
          foregroundColor: Colors.white,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.grey[50],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFFF6B35), width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
        textTheme: const TextTheme(
          headlineLarge: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5,
          ),
          headlineMedium: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5,
          ),
          titleLarge: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.15,
          ),
          titleMedium: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.15,
          ),
          bodyLarge: TextStyle(
            fontSize: 16,
            letterSpacing: 0.5,
          ),
          bodyMedium: TextStyle(
            fontSize: 14,
            letterSpacing: 0.25,
          ),
        ),
      ),
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      routes: {
        '/': (context) => const HomeScreen(),
        '/clientes': (context) => const ClientesScreen(),
        '/clientes/nuevo': (context) => const ClienteFormScreen(),
        '/productos': (context) => const ProductosScreen(),
        '/productos/nuevo': (context) => const ProductoFormScreen(),
        '/pedidos': (context) => const PedidosScreen(),
        '/pedidos/nuevo': (context) => const PedidoFormScreen(),
        '/areas': (context) => const AreasScreen(),
        '/gastos': (context) => const GastosScreen(),
        '/gastos/nuevo': (context) => const GastoFormScreen(),
        '/seguimiento': (context) => const SeguimientoScreen(),
      },
    );
  }
}
