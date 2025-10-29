import 'package:flutter/material.dart';
import 'area_tareas_screen.dart';

class AreasScreen extends StatelessWidget {
  const AreasScreen({super.key});

  static const Map<String, Color> areasColores = {
    'Impresión': Colors.blue,
    'Vinil': Colors.orange,
    'Camisetas': Colors.green,
    'Lonas': Colors.purple,
    'Publicidad': Colors.red,
  };

  static const Map<String, IconData> areasIconos = {
    'Impresión': Icons.print,
    'Vinil': Icons.layers,
    'Camisetas': Icons.checkroom,
    'Lonas': Icons.flag,
    'Publicidad': Icons.campaign,
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Áreas de Trabajo'),
        elevation: 2,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.count(
          crossAxisCount: _getCrossAxisCount(context),
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          children: areasColores.keys.map((area) {
            return _AreaCard(
              title: area,
              icon: areasIconos[area]!,
              color: areasColores[area]!,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AreaTareasScreen(area: area),
                  ),
                );
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  int _getCrossAxisCount(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width > 1200) return 3;
    if (width > 800) return 3;
    if (width > 600) return 2;
    return 2;
  }
}

class _AreaCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _AreaCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                color.withOpacity(0.8),
                color,
              ],
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 64,
                color: Colors.white,
              ),
              const SizedBox(height: 16),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
