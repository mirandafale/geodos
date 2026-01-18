import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:geodos/models/project.dart';
import 'package:uuid/uuid.dart';

/// Servicio de proyectos conectado a Firestore.
/// Lectura pública (stream) y escritura sólo para admins autenticados
/// (validación se realiza antes de invocar estos métodos desde la UI).
class ProjectService {
  static const _assetPath =
      'assets/proyectos_por_municipio_cat_isla_v3_jittered.json';
  static final _firestore = FirebaseFirestore.instance.collection('projects');
  static final _uuid = const Uuid();

  static List<Project> _localProjects = [];
  static List<Project> _remoteProjects = [];
  static bool _remoteLoaded = false;
  static bool _localLoaded = false;
  static int _lastRemoteCount = 0;

  static int get lastRemoteCount => _lastRemoteCount;
  static bool get usingLocalFallback =>
      _remoteProjects.isEmpty && _localProjects.isNotEmpty;
  static int get localFallbackCount => _localProjects.length;

  /// Inicializa cargando los datos remotos y el fallback local si es necesario.
  static Future<void> ensureInitialized() async {
    await _loadRemoteOnce();
    await _loadLocalIfNeeded();
  }

  static Future<void> _loadRemoteOnce() async {
    if (_remoteLoaded) return;
    try {
      final snapshot = await _firestore.get();
      _remoteProjects = snapshot.docs.map(Project.fromDoc).toList();
      _lastRemoteCount = _remoteProjects.length;
      debugPrint(
          'ProjectService: loaded $_lastRemoteCount projects from Firestore');
    } on FirebaseException catch (error, stackTrace) {
      debugPrint('ProjectService: Firestore load failed ${error.code}');
      debugPrintStack(stackTrace: stackTrace);
      _remoteProjects = [];
      _lastRemoteCount = 0;
    } catch (error, stackTrace) {
      debugPrint('ProjectService: Firestore load failed $error');
      debugPrintStack(stackTrace: stackTrace);
      _remoteProjects = [];
      _lastRemoteCount = 0;
    } finally {
      _remoteLoaded = true;
    }
  }

  static Future<void> _loadLocalIfNeeded() async {
    if (_localLoaded || _remoteProjects.isNotEmpty) return;
    try {
      final raw = await rootBundle.loadString(_assetPath);
      _localProjects = Project.listFromJsonString(raw)
          .where((p) => p.hasValidCoords)
          .toList();
      debugPrint(
          'ProjectService: loaded local fallback ${_localProjects.length} projects');
    } catch (error, stackTrace) {
      debugPrint('ProjectService: local fallback failed: $error');
      debugPrintStack(stackTrace: stackTrace);
    } finally {
      _localLoaded = true;
    }
  }

  static List<Project> _availableProjects() {
    if (_remoteProjects.isNotEmpty) return _remoteProjects;
    if (_localProjects.isNotEmpty) return _localProjects;
    return const [];
  }

  /// Devuelve un flujo (stream) de proyectos filtrados en base a los criterios.
  static Stream<List<Project>> stream({
    int? year,
    String? category,
    ProjectScope? scope,
    String? island,
    String? search,
  }) {
    final filtersLog = _filtersDescription(year, category, scope, island, search);
    return Stream.multi((controller) async {
      await ensureInitialized();

      void emit(String reason) {
        final filtered = _filterProjects(year, category, scope, island, search);
        debugPrint(
          'ProjectService.stream[$reason]: filtered=${filtered.length} '
          'remote=$lastRemoteCount local=${_localProjects.length} '
          '${usingLocalFallback ? '(fallback)' : '(firestore)'} '
          'with $filtersLog',
        );
        controller.add(filtered);
      }

      emit('initial');

      StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? sub;
      sub = _firestore.snapshots().listen(
        (snapshot) {
          _remoteProjects = snapshot.docs.map(Project.fromDoc).toList();
          _lastRemoteCount = _remoteProjects.length;
          if (_remoteProjects.isEmpty) {
            _loadLocalIfNeeded();
          }
          emit('snapshot');
        },
        onError: (error, stackTrace) {
          debugPrint('ProjectService: snapshot error $error');
          debugPrintStack(stackTrace: stackTrace);
          emit('snapshot-error');
        },
      );

      controller.onCancel = () => sub?.cancel();
    });
  }

  /// Devuelve listas únicas para filtros (se calcula en cliente).
  static Future<List<int>> getYears() async {
    await ensureInitialized();
    final set = <int>{};
    for (final p in _availableProjects()) {
      if (p.year != null) set.add(p.year!);
    }
    final list = set.toList()..sort((a, b) => b.compareTo(a));
    return list;
  }

  static Future<List<String>> getCategories() async {
    await ensureInitialized();
    final set = <String>{};
    for (final p in _availableProjects()) {
      if (p.category.isNotEmpty) set.add(p.category);
    }
    final list = set.toList()..sort();
    return list;
  }

  static Future<List<ProjectScope>> getScopes() async {
    await ensureInitialized();
    final list = _availableProjects().map((p) => p.scope).toSet().toList();
    list.sort((a, b) => _scopeLabel(a).compareTo(_scopeLabel(b)));
    return list;
  }

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
    int? year,
    String? category,
    ProjectScope? scope,
    String? island,
    String? search,
  ) {
    final parts = <String>[
      'year=${year ?? 'all'}',
      'category=${(category?.trim().isEmpty ?? true) ? 'all' : category?.trim()}',
      'scope=${scope?.name ?? 'all'}',
      'island=${(island?.trim().isEmpty ?? true) ? 'all' : island?.trim()}',
      'search=${(search?.trim().isEmpty ?? true) ? '""' : search?.trim()}',
    ];
    return 'filters(${parts.join(', ')})';
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
}
