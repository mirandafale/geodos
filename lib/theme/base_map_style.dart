import 'package:flutter/material.dart';

enum BaseMapStyle {
  standard(
    label: 'Estándar',
    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
    icon: Icons.map,
  ),
  satellite(
    label: 'Satélite',
    urlTemplate:
        'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}',
    icon: Icons.satellite_alt,
  ),
  terrain(
    label: 'Relieve',
    urlTemplate: 'https://tile.opentopomap.org/{z}/{x}/{y}.png',
    icon: Icons.terrain,
  );

  final String label;
  final String urlTemplate;
  final IconData icon;

  const BaseMapStyle({
    required this.label,
    required this.urlTemplate,
    required this.icon,
  });
}
