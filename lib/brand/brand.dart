
import 'package:flutter/material.dart';

class Brand {
  static const Color primary = Color(0xFF0F4C81); // azul petróleo
  static const Color secondary = Color(0xFF2A9D8F); // verde académico
  static const Color accent = Color(0xFFE9C46A); // ámbar sobrio
  static const Color ink = Color(0xFF1B1F24); // texto oscuro
  static const Color mist = Color(0xFFF5F6F8); // fondo claro

  static const LinearGradient appBarGradient = LinearGradient(
    colors: <Color>[primary, secondary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static LinearGradient badgeGradient(bool admin) {
    if (admin) {
      return const LinearGradient(
        colors: <Color>[primary, secondary],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    }
    return const LinearGradient(
      colors: <Color>[Color(0xAA000000), Color(0x8A000000)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }

  static ThemeData theme() {
    final colorScheme = ColorScheme.fromSeed(seedColor: primary, brightness: Brightness.light);
    final base = ThemeData(colorScheme: colorScheme, useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: mist,
      textTheme: base.textTheme.copyWith(
        titleLarge: base.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
        titleMedium: base.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
      ),
      appBarTheme: const AppBarTheme(
        foregroundColor: Colors.white,
        backgroundColor: Colors.transparent,
        elevation: 0,
        titleTextStyle: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        focusedBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: secondary, width: 2),
        ),
      ),
      cardTheme: CardTheme(
        color: Colors.white,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        elevation: 4, foregroundColor: Colors.white, backgroundColor: secondary,
      ),
      snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
    );
  }
}
