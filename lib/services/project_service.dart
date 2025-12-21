// lib/services/project_service.dart
import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:geodos/models/project.dart';
import 'package:uuid/uuid.dart';

/// Servicio encargado de cargar y filtrar los proyectos desde assets.
class ProjectService {
  static List<Project> _projects = [];
  static List<Project> _remoteProjects = [];
  static final _firestore = FirebaseFirestore.instance.collection('projects');
  static final _uuid = const Uuid();
  static bool _remoteLoaded = false;
  static const _assetPath = 'assets/proyectos_por_municipio_cat_isla_v3_jittered.json';

  /// Inicializa cargando el archivo JSON de assets si aún no está cargado.
  static Future<void> ensureInitialized() async {
    if (_projects.isNotEmpty) return;
    final raw = await rootBundle.loadString(_assetPath);
    _projects = Project.listFromJsonString(raw)
        .where((p) => p.hasValidCoords)
        .toList();
    await _loadRemoteOnce();
  }

  static Future<void> _loadRemoteOnce() async {
    if (_remoteLoaded) return;
    final snapshot = await _firestore.get();
    _remoteProjects = snapshot.docs.map(_projectFromDoc).toList();
    _remoteLoaded = true;
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
    yield _filterProjects(year, category, scope, island, search);
    await for (final snapshot in _firestore.snapshots()) {
      _remoteProjects = snapshot.docs.map(_projectFromDoc).toList();
      yield _filterProjects(year, category, scope, island, search);
    }
  }

  /// Extrae todos los años únicos presentes en los proyectos.
  static Future<List<int>> getYears() async {
    await ensureInitialized();
    final set = <int>{};
    for (final p in [..._projects, ..._remoteProjects]) {
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
    for (final p in [..._projects, ..._remoteProjects]) {
      if (p.category.isNotEmpty) set.add(p.category);
    }
    final list = set.toList();
    list.sort();
    return list;
  }

  /// Devuelve todos los ámbitos disponibles en los proyectos.
  static Future<List<ProjectScope>> getScopes() async {
    await ensureInitialized();
    final list = [..._projects, ..._remoteProjects]
        .map((p) => p.scope)
        .toSet()
        .toList();
    list.sort((a, b) => _scopeLabel(a).compareTo(_scopeLabel(b)));
    return list;
  }

  /// Devuelve la lista de islas disponibles.
  static Future<List<String>> getIslands() async {
    await ensureInitialized();
    final list = [..._projects, ..._remoteProjects]
        .map((p) => p.island.trim())
        .where((e) => e.isNotEmpty)
        .toSet()
        .toList();
    list.sort((a, b) => a.compareTo(b));
    return list;
  }

  /// Crear un nuevo proyecto en memoria (modo admin sin backend).
  static Future<void> createAdminProject(Project project) async {
    await _firestore.doc(project.id).set({
      ...project.toJson(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> updateProject(Project project) async {
    await _firestore.doc(project.id).update({
      ...project.toJson(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> deleteProject(String id) async {
    await _firestore.doc(id).delete();
  }

  static Project emptyProject() {
    return Project(
      id: _uuid.v4(),
      title: '',
      municipality: '',
      year: null,
      category: '',
      lat: 0,
      lon: 0,
      island: '',
      scope: ProjectScope.unknown,
      enRedaccion: false,
      description: '',
      updatedAt: DateTime.now(),
    );
  }

  static List<Project> _filterProjects(
      int? year,
      String? category,
      ProjectScope? scope,
      String? island,
      String? search,) {
    final combined = [..._projects, ..._remoteProjects];
    return combined.where((p) {
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

  static Project _projectFromDoc(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    final scopeStr = (data['scope'] ?? data['cat'] ?? '').toString().toUpperCase();
    final scope = _scopeFromString(scopeStr);
    final lat = (data['lat'] is num)
        ? (data['lat'] as num).toDouble()
        : double.tryParse('${data['lat']}') ?? 0;
    final lon = (data['lon'] is num)
        ? (data['lon'] as num).toDouble()
        : double.tryParse('${data['lon']}') ?? 0;

    int? year;
    if (data['year'] != null) {
      year = data['year'] is int
          ? data['year'] as int
          : int.tryParse('${data['year']}');
    } else if (data['date'] != null) {
      year = data['date'] is int ? data['date'] as int : int.tryParse('${data['date']}');
    }

    return Project(
      id: doc.id,
      title: (data['title'] ?? '') as String,
      municipality: (data['municipality'] ?? '') as String,
      year: year,
      category: (data['category'] ?? '') as String,
      lat: lat,
      lon: lon,
      island: (data['island'] ?? data['isla'] ?? '') as String,
      scope: scope,
      enRedaccion: data['enRedaccion'] == true,
      description: (data['description'] ?? '') as String?,
      updatedAt: (data['updatedAt'] is Timestamp)
          ? (data['updatedAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
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
}
