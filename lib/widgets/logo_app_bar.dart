import 'package:flutter/material.dart';
import 'dart:io';

class LogoAppBar extends StatelessWidget {
  final double height;

  const LogoAppBar({
    super.key,
    this.height = 40,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _checkImageExists(),
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data == true) {
          // Si existe el logo, mostrarlo
          return Image.asset(
            'assets/images/logo.png',
            height: height,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) => _buildFallback(),
          );
        } else {
          // Si no existe, mostrar el fallback
          return _buildFallback();
        }
      },
    );
  }

  Future<bool> _checkImageExists() async {
    try {
      // Intentar verificar si existe el asset
      return true; // En web siempre intentamos cargar
    } catch (e) {
      return false;
    }
  }

  Widget _buildFallback() {
    return Container(
      height: height,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFFFF6B35), // Naranja corporativo
            const Color(0xFFFF8C42), // Naranja claro
          ],
        ),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF6B35).withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.create_rounded,
            color: Colors.white,
            size: 24,
          ),
          SizedBox(width: 8),
          Text(
            'CREATIVA',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
