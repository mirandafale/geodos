// lib/services/project_service.dart
import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:geodos/models/project.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter/foundation.dart';


/// Servicio encargado de cargar y filtrar los proyectos desde assets.
class ProjectService {
  static List<Project> _localProjects = [];
  static List<Project> _remoteProjects = [];
  static final _firestore = FirebaseFirestore.instance.collection('projects');
  static final _uuid = const Uuid();
  static bool _remoteLoaded = false;
  static bool _localLoaded = false;
  static int _lastRemoteCount = 0;
  static const _assetPath = 'assets/proyectos_por_municipio_cat_isla_v3_jittered.json';

  /// Inicializa cargando los datos remotos y el fallback local si es necesario.
  static Future<void> ensureInitialized() async {
    await _loadRemoteOnce();
    await _loadLocalIfNeeded();
  }

  static Future<void> _loadRemoteOnce() async {
    if (_remoteLoaded) return;
    try {
      final snapshot = await _firestore.get();
      _remoteProjects = snapshot.docs.map(_projectFromDoc).toList();
      _lastRemoteCount = _remoteProjects.length;
      _remoteLoaded = true;
      debugPrint('ProjectService: initial remote load $_lastRemoteCount docs');
    } catch (error) {
      _remoteProjects = [];
      _lastRemoteCount = 0;
      _remoteLoaded = true;
      debugPrint('ProjectService: remote load failed, using local fallback: $error');
    }
  }

  static Future<void> _loadLocalIfNeeded() async {
    if (_localLoaded) return;
    if (_remoteProjects.isNotEmpty) return;
    try {
      final raw = await rootBundle.loadString(_assetPath);
      _localProjects = Project.listFromJsonString(raw)
          .where((p) => p.hasValidCoords)
          .toList();
      _localLoaded = true;
      debugPrint('ProjectService: loaded local fallback ${_localProjects.length} projects');
    } catch (error) {
      debugPrint('ProjectService: local fallback failed to load: $error');
    }
  }

  static List<Project> _availableProjects() {
    if (_remoteProjects.isNotEmpty) return _remoteProjects;
    if (_localProjects.isNotEmpty) return _localProjects;
    return const [];
  }

  static int get lastRemoteCount => _lastRemoteCount;

  static bool get usingLocalFallback => _remoteProjects.isEmpty && _localProjects.isNotEmpty;

  static int get localFallbackCount => _localProjects.length;

  /// Devuelve un flujo (stream) de proyectos filtrados en base a los criterios.
  static Stream<List<Project>> stream({
    int? year,
    String? category,
    ProjectScope? scope,
    String? island,
    String? search,
  }) async* {
    final filtersLog = _filtersDescription(year, category, scope, island, search);
    debugPrint('ProjectService.stream: building stream with $filtersLog');

    await ensureInitialized();

    var filtered = _filterProjects(year, category, scope, island, search);
    debugPrint(
        'ProjectService.stream: initial filtered=${filtered.length} remote=$lastRemoteCount local=${_localProjects.length} (${usingLocalFallback ? 'using local fallback' : 'firestore'}) with $filtersLog');
    yield filtered;

    await for (final snapshot in _firestore.snapshots()) {
      _remoteProjects = snapshot.docs.map(_projectFromDoc).toList();
      _lastRemoteCount = _remoteProjects.length;
      debugPrint('ProjectService.stream: received ${_remoteProjects.length} projects from Firestore');

      if (_remoteProjects.isEmpty) {
        await _loadLocalIfNeeded();
      }

      filtered = _filterProjects(year, category, scope, island, search);
      debugPrint(
          'ProjectService.stream: snapshot docs=${snapshot.docs.length} filtered=${filtered.length} (${usingLocalFallback ? 'local fallback' : 'firestore'}) with $filtersLog');
      yield filtered;
    }
  }

  /// Extrae todos los años únicos presentes en los proyectos.
  static Future<List<int>> getYears() async {
    await ensureInitialized();
    final set = <int>{};
    for (final p in _availableProjects()) {
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
    for (final p in _availableProjects()) {
      if (p.category.isNotEmpty) set.add(p.category);
    }
    final list = set.toList();
    list.sort();
    return list;
  }

  /// Devuelve todos los ámbitos disponibles en los proyectos.
  static Future<List<ProjectScope>> getScopes() async {
    await ensureInitialized();
    final list = _availableProjects().map((p) => p.scope).toSet().toList();
    list.sort((a, b) => _scopeLabel(a).compareTo(_scopeLabel(b)));
    return list;
  }

  /// Devuelve la lista de islas disponibles.
  static Future<List<String>> getIslands() async {
    await ensureInitialized();
    final list = _availableProjects()
        .map((p) => p.island.trim())
        .where((e) => e.isNotEmpty)
        .toSet()
        .toList();
    list.sort((a, b) => a.compareTo(b));
    return list;
  }

  /// Crear un nuevo proyecto en memoria (modo admin sin backend).
  static Future<void> createAdminProject(Project project) async {
    await _firestore.doc(project.id).set(_projectToFirestoreMap(
      project,
      includeCreatedAt: true,
    ));
  }

  static Future<void> updateProject(Project project) async {
    await _firestore.doc(project.id).update(_projectToFirestoreMap(
      project,
      includeCreatedAt: true,
    ));
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
      createdAt: null,
      updatedAt: null,
    );
  }

  static List<Project> _filterProjects(
    int? year,
    String? category,
    ProjectScope? scope,
    String? island,
    String? search,
  ) {
    final combined = _availableProjects();
    final normalizedCategory = category?.trim().toLowerCase();
    final normalizedIsland = island?.trim().toLowerCase();
    final normalizedSearch = search?.trim().toLowerCase();

    return combined.where((p) {
      if (year != null && p.year != year) return false;

      if (normalizedCategory != null && normalizedCategory.isNotEmpty) {
        if (p.category.trim().toLowerCase() != normalizedCategory) return false;
      }

      if (scope != null && scope != ProjectScope.unknown && p.scope != scope) {
        return false;
      }

      if (normalizedIsland != null && normalizedIsland.isNotEmpty) {
        if (p.island.trim().toLowerCase() != normalizedIsland) return false;
      }

      if (normalizedSearch != null && normalizedSearch.isNotEmpty) {
        final txt = '${p.title} ${p.municipality}'.toLowerCase();
        if (!txt.contains(normalizedSearch)) return false;
      }
      return true;
    }).toList();
  }

  static String describeFilters({
    int? year,
    String? category,
    ProjectScope? scope,
    String? island,
    String? search,
  }) {
    return _filtersDescription(year, category, scope, island, search);
  }

  static String _filtersDescription(
      int? year, String? category, ProjectScope? scope, String? island, String? search) {
    final parts = <String>[
      'year=${year ?? 'all'}',
      'category=${(category?.trim().isEmpty ?? true) ? 'all' : category?.trim()}',
      'scope=${scope?.name ?? 'all'}',
      'island=${(island?.trim().isEmpty ?? true) ? 'all' : island?.trim()}',
      'search=${(search?.trim().isEmpty ?? true) ? '""' : search?.trim()}',
    ];
    return 'filters(${parts.join(', ')})';
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
      createdAt: (data['createdAt'] is Timestamp)
          ? (data['createdAt'] as Timestamp).toDate()
          : null,
      updatedAt: (data['updatedAt'] is Timestamp)
          ? (data['updatedAt'] as Timestamp).toDate()
          : null,
    );
  }

  static Map<String, dynamic> _projectToFirestoreMap(
    Project project, {
    required bool includeCreatedAt,
  }) {
    return {
      'title': project.title,
      'category': project.category,
      'scope': Project.scopeToString(project.scope),
      'island': project.island,
      'municipality': project.municipality,
      'year': project.year,
      'lat': project.lat,
      'lon': project.lon,
      'description': project.description,
      'enRedaccion': project.enRedaccion,
      if (includeCreatedAt)
        'createdAt': project.createdAt != null
            ? Timestamp.fromDate(project.createdAt!)
            : FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
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
