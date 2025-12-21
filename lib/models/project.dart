// lib/models/project.dart
import 'dart:convert';

/// Ámbito del proyecto según el campo `cat` del JSON.
enum ProjectScope { municipal, comarcal, insular, regional, unknown }

class Project {
  final String id;
  final String title;
  final String municipality;
  final int? year; // null si está "EN REDACCION"
  final String category; // ej. MEDIOAMBIENTE, ORDENACION DEL TERRITORIO...
  final double lat;
  final double lon;
  final String island; // campo `isla` en el JSON
  final ProjectScope scope; // campo `cat` en el JSON
  final bool enRedaccion;
  final String? description; // opcional, para proyectos añadidos vía admin

  Project({
    required this.id,
    required this.title,
    required this.municipality,
    required this.year,
    required this.category,
    required this.lat,
    required this.lon,
    required this.island,
    required this.scope,
    required this.enRedaccion,
    this.description,
  });

  /// Atajo para compatibilidad con código antiguo que usaba `categories`.
  List<String> get categories => [category];

  bool get hasValidCoords => lat != 0 && lon != 0;

  bool hasCategory(String cat) {
    final c = cat.trim().toUpperCase();
    return category.trim().toUpperCase() == c;
  }

  Project copyWith({
    String? description,
  }) {
    return Project(
      id: id,
      title: title,
      municipality: municipality,
      year: year,
      category: category,
      lat: lat,
      lon: lon,
      island: island,
      scope: scope,
      enRedaccion: enRedaccion,
      description: description ?? this.description,
    );
  }

  // ---------- PARSEO DESDE / HACIA JSON ----------

  static List<Project> listFromJsonString(String raw) {
    final data = jsonDecode(raw);
    if (data is List) {
      return data
          .whereType<Map<String, dynamic>>()
          .map(Project.fromJson)
          .toList();
    }
    return const [];
  }

  factory Project.fromJson(Map<String, dynamic> json) {
    // date puede ser número o cadena "EN REDACCION"
    final rawDate = json['date'];
    int? year;
    bool enRedaccion = false;
    if (rawDate is int) {
      year = rawDate;
    } else if (rawDate is String) {
      final norm = rawDate.toUpperCase();
      if (norm.contains('REDACCION')) {
        enRedaccion = true;
        year = null;
      } else {
        year = int.tryParse(rawDate);
      }
    }

    final scopeStr =
    (json['cat'] ?? json['scope'] ?? '').toString().toUpperCase().trim();
    final scope = _scopeFromString(scopeStr);

    final latVal = json['lat'];
    final lonVal = json['lon'];

    final lat = latVal is num
        ? latVal.toDouble()
        : double.tryParse(latVal?.toString() ?? '') ?? 0;
    final lon = lonVal is num
        ? lonVal.toDouble()
        : double.tryParse(lonVal?.toString() ?? '') ?? 0;

    final title = (json['title'] ?? '').toString();
    final municipality = (json['municipality'] ?? '').toString();

    return Project(
        id: (json['id'] ?? '$title||$municipality').toString(),
      title: title,
      municipality: municipality,
      year: year,
      category: (json['category'] ?? '').toString(),
      lat: lat,
      lon: lon,
      island: (json['isla'] ?? json['island'] ?? '').toString(),
      scope: scope,
      enRedaccion: json['enRedaccion'] == true || enRedaccion,
      description: json['description']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'municipality': municipality,
      'date': year ?? (enRedaccion ? 'EN REDACCION' : null),
      'category': category,
      'lat': lat,
      'lon': lon,
      'isla': island,
      'cat': _scopeToString(scope),
      'enRedaccion': enRedaccion,
      if (description != null && description!.trim().isNotEmpty)
        'description': description,
    };
  }

  // ---------- Helpers de ámbito ----------

  static ProjectScope _scopeFromString(String s) {
    switch (s) {
      case 'MUNICIPAL':
        return ProjectScope.municipal;
      case 'COMARCAL':
        return ProjectScope.comarcal;
      case 'INSULAR':
        return ProjectScope.insular;
      case 'REGIONAL':
        return ProjectScope.regional;
      default:
        return ProjectScope.unknown;
    }
  }

  static String _scopeToString(ProjectScope scope) {
    switch (scope) {
      case ProjectScope.municipal:
        return 'MUNICIPAL';
      case ProjectScope.comarcal:
        return 'COMARCAL';
      case ProjectScope.insular:
        return 'INSULAR';
      case ProjectScope.regional:
        return 'REGIONAL';
      case ProjectScope.unknown:
        return 'UNKNOWN';
    }
  }
}
