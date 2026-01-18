import 'package:flutter/material.dart';

enum BaseMapStyle {
  standard,
  satellite,
  terrain,
}

extension BaseMapStyleInfo on BaseMapStyle {
  String get label {
    switch (this) {
      case BaseMapStyle.standard:
        return 'Estándar';
      case BaseMapStyle.satellite:
        return 'Satélite';
      case BaseMapStyle.terrain:
        return 'Relieve';
    }
  }

  IconData get icon {
    switch (this) {
      case BaseMapStyle.standard:
        return Icons.map_outlined;
      case BaseMapStyle.satellite:
        return Icons.satellite_alt_outlined;
      case BaseMapStyle.terrain:
        return Icons.terrain_outlined;
    }
  }

  String get urlTemplate {
    switch (this) {
      case BaseMapStyle.standard:
        return 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
      case BaseMapStyle.satellite:
        return 'https://{s}.tile.opentopomap.org/{z}/{x}/{y}.png';
      case BaseMapStyle.terrain:
        return 'https://{s}.tile.openstreetmap.fr/hot/{z}/{x}/{y}.png';
    }
  }
}
