// lib/services/project_service.dart
import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:geodos/models/project.dart';

/// Servicio encargado de cargar y filtrar los proyectos desde assets.
class ProjectService {
  static List<Project> _projects = [];
  static const _assetPath = 'assets/proyectos_por_municipio_cat_isla_v3_jittered.json';

  /// Inicializa cargando el archivo JSON de assets si aún no está cargado.
  static Future<void> ensureInitialized() async {
    if (_projects.isNotEmpty) return;
    final raw = await rootBundle.loadString(_assetPath);
    _projects = Project.listFromJsonString(raw)
        .where((p) => p.hasValidCoords)
        .toList();
  }

  /// Devuelve un flujo (stream) de proyectos filtrados en base a los criterios.
  static Stream<List<Project>> stream({
    int? year,
    String? category,
    ProjectScope? scope,
    String? island,
    String? search,
  }) async* {
    await ensureInitialized();
    yield _projects.where((p) {
      if (year != null && p.year != year) return false;
      if (category != null && category.trim().isNotEmpty && !p.hasCategory(category)) {
        return false;
      }
      if (scope != null && scope != ProjectScope.unknown && p.scope != scope) {
        return false;
      }
      if (island != null && island.trim().isNotEmpty) {
        if (p.island.trim().toUpperCase() != island.trim().toUpperCase()) return false;
      }
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

  /// Devuelve todos los ámbitos disponibles en los proyectos.
  static Future<List<ProjectScope>> getScopes() async {
    await ensureInitialized();
    final list = _projects.map((p) => p.scope).toSet().toList();
    list.sort((a, b) => _scopeLabel(a).compareTo(_scopeLabel(b)));
    return list;
  }

  /// Devuelve la lista de islas disponibles.
  static Future<List<String>> getIslands() async {
    await ensureInitialized();
    final list = _projects.map((p) => p.island.trim()).where((e) => e.isNotEmpty).toSet().toList();
    list.sort((a, b) => a.compareTo(b));
    return list;
  }

  /// Crear un nuevo proyecto en memoria (modo admin sin backend).
  static Future<void> createAdminProject(Project project) async {
    _projects.add(project);
  }

  static String _scopeLabel(ProjectScope scope) {
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
        return 'OTRO';
    }
  }
}
