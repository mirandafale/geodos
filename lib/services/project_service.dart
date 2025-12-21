// lib/services/project_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geodos/models/project.dart';
import 'auth_service.dart';

/// Servicio de proyectos conectado a Firestore.
/// Lectura pública (stream) y escritura sólo para admins autenticados
/// (validación se realiza antes de invocar estos métodos desde la UI).
class ProjectService {
  static final _col = FirebaseFirestore.instance.collection('projects');

  /// Devuelve un flujo de proyectos filtrados en cliente.
  static Stream<List<Project>> stream({
    int? year,
    String? category,
    ProjectScope? scope,
    String? island,
    String? search,
  }) {
    return _col
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snapshot) {
      final projects = snapshot.docs.map(Project.fromDoc).where((p) => p.hasValidCoords);

      Iterable<Project> filtered = projects;
      if (year != null) {
        filtered = filtered.where((p) => p.year == year || p.enRedaccion);
      }
      if (category != null && category.trim().isNotEmpty) {
        final c = category.trim().toUpperCase();
        filtered = filtered.where((p) => p.category.toUpperCase() == c);
      }
      if (scope != null && scope != ProjectScope.unknown) {
        filtered = filtered.where((p) => p.scope == scope);
      }
      if (island != null && island.trim().isNotEmpty) {
        final isl = island.trim().toUpperCase();
        filtered = filtered.where((p) => p.island.toUpperCase() == isl);
      }
      if (search != null && search.trim().isNotEmpty) {
        final q = search.trim().toLowerCase();
        filtered = filtered.where((p) =>
            '${p.title} ${p.municipality}'.toLowerCase().contains(q));
      }
      return filtered.toList();
    });
  }

  /// Devuelve listas únicas para filtros (se calcula en cliente).
  static Future<List<int>> getYears() async {
    final snap = await _col.get();
    final set = <int>{};
    for (final doc in snap.docs) {
      final p = Project.fromDoc(doc);
      if (p.year != null) set.add(p.year!);
    }
    final list = set.toList()..sort((a, b) => b.compareTo(a));
    return list;
  }

  static Future<List<String>> getCategories() async {
    final snap = await _col.get();
    final set = snap.docs.map((d) => (d.data()['category'] ?? '').toString()).where((v) => v.isNotEmpty).toSet();
    final list = set.toList()..sort();
    return list;
  }

  static Future<List<ProjectScope>> getScopes() async {
    final snap = await _col.get();
    final set = snap.docs
        .map((d) => Project.fromDoc(d).scope)
        .where((s) => s != ProjectScope.unknown)
        .toSet()
        .toList();
    set.sort((a, b) => _scopeLabel(a).compareTo(_scopeLabel(b)));
    return set;
  }

  static Future<List<String>> getIslands() async {
    final snap = await _col.get();
    final set = snap.docs
        .map((d) => (d.data()['island'] ?? d.data()['isla'] ?? '').toString())
        .where((e) => e.trim().isNotEmpty)
        .map((e) => e.trim())
        .toSet()
        .toList();
    set.sort();
    return set;
  }

  static Future<String> createOrUpdate(Project project) async {
    if (!AuthService.instance.isAdmin) {
      throw Exception('Solo un administrador autenticado puede modificar proyectos.');
    }
    final doc = project.id.isEmpty ? _col.doc() : _col.doc(project.id);
    final data = {
      'title': project.title,
      'municipality': project.municipality,
      'year': project.year,
      'category': project.category,
      'lat': project.lat,
      'lon': project.lon,
      'island': project.island,
      'scope': Project.scopeToString(project.scope),
      'enRedaccion': project.enRedaccion,
      'description': project.description,
      'updatedAt': FieldValue.serverTimestamp(),
      'createdAt': FieldValue.serverTimestamp(),
    };
    await doc.set(data, SetOptions(merge: true));
    return doc.id;
  }

  static Future<void> delete(String id) async {
    if (!AuthService.instance.isAdmin) {
      throw Exception('Solo un administrador autenticado puede eliminar proyectos.');
    }
    await _col.doc(id).delete();
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
