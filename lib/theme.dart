import 'package:flutter/material.dart';

/// Colores coherentes con el gradiente de la app (teal -> verde azulado).
class AppTheme {
  static const Color primaryStart = Color(0xFF0EA5A5); // teal-500 aprox
  static const Color primaryEnd   = Color(0xFF16A34A); // green-600 aprox
  static const Color primary      = Color(0xFF0EA5A5);
  static const Color surface      = Color(0xFFF7F7F8);

  static ThemeData theme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(seedColor: primary),
    scaffoldBackgroundColor: surface,
    appBarTheme: const AppBarTheme(
      elevation: 0,
      centerTitle: false,
      backgroundColor: Colors.white,
      foregroundColor: Colors.black87,
    ),
  );

  static BoxDecoration gradientHeader() => const BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [primaryStart, primaryEnd],
    ),
  );
}
