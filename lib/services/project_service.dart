// lib/services/project_service.dart
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:geodos/models/project.dart';

/// Servicio encargado de cargar y filtrar los proyectos desde assets.
class ProjectService {
  static List<Project> _projects = [];

  /// Inicializa cargando el archivo JSON de assets si aún no está cargado.
  static Future<void> ensureInitialized() async {
    if (_projects.isNotEmpty) return;
    final raw = await rootBundle.loadString('assets/data/projects.json');
    _projects = Project.listFromJsonString(raw)
        .where((p) => p.hasValidCoords)
        .toList();
  }

  /// Devuelve un flujo (stream) de proyectos filtrados en base a los criterios.
  static Stream<List<Project>> stream({
    String? type,
    int? year,
    String? scope,
    String? search,
  }) async* {
    await ensureInitialized();
    yield _projects.where((p) {
      if (year != null && p.year != year) return false;
      if (scope != null && scope != 'Todos' && !p.hasCategory(scope)) return false;
      if (search != null && search.isNotEmpty) {
        final q = search.trim().toLowerCase();
        final txt = '${p.title} ${p.municipality}'.toLowerCase();
        if (!txt.contains(q)) return false;
      }
      return true;
    }).toList();
  }

  /// Extrae todos los años únicos presentes en los proyectos.
  static Future<List<int>> getYears() async {
    await ensureInitialized();
    final set = <int>{};
    for (final p in _projects) {
      if (p.year != null) set.add(p.year!);
    }
    final list = set.toList();
    list.sort((a, b) => b.compareTo(a)); // descendente
    return list;
  }

  /// Extrae todas las categorías únicas presentes en los proyectos.
  static Future<List<String>> getCategories() async {
    await ensureInitialized();
    final set = <String>{};
    for (final p in _projects) {
      if (p.category.isNotEmpty) set.add(p.category);
    }
    final list = set.toList();
    list.sort();
    return list;
  }

  /// Devuelve todos los ámbitos encontrados (categorías normalizadas).
  static List<String> get scopes {
    return _projects.map((p) => p.category).toSet().toList()..sort();
  }

  /// Crear un nuevo proyecto en memoria (modo admin sin backend).
  static Future<void> createAdminProject(Project project) async {
    _projects.add(project);
  }
}
