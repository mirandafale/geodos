import 'package:flutter/foundation.dart';
import '../models/project.dart';
import '../data/project_repository.dart';

class AppState extends ChangeNotifier {
  static const String assetPath = 'assets/proyectos_por_municipio_centroides.json';

  final ProjectRepository _repo = const ProjectRepository();

  bool _loading = true;
  String? _error;
  bool _isAdmin = false;

  final List<Project> _assetProjects = [];
  final List<Project> _userProjects = [];

  // Filtros
  String? _selectedCategory; // arranca en MEDIOAMBIENTE
  int? _yearFrom;
  int? _yearTo;
  String _search = ''; // búsqueda por título / municipio

  AppState() { _init(); }

  Future<void> _init() async {
    try {
      _loading = true; _error = null; notifyListeners();

      final base = await _repo.loadFromAsset(assetPath);
      _assetProjects
        ..clear()
        ..addAll(base);

      final user = await _repo.loadUserProjects();
      _userProjects
        ..clear()
        ..addAll(user);

      final years = _allProjects
          .where((p) => !p.enRedaccion && p.year != null)
          .map((p) => p.year!)
          .toList()
        ..sort();
      if (years.isNotEmpty) {
        _yearFrom = years.first;
        _yearTo = years.last;
      }

      // Iniciar directamente en MEDIOAMBIENTE
      _selectedCategory = 'MEDIOAMBIENTE';
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  // ===== Getters de estado global
  bool get isLoaded => !_loading && _error == null;
  bool get isLoading => _loading;
  String? get error => _error;
  bool get isAdmin => _isAdmin;

  List<Project> get projects => filteredProjects;

  List<Project> get _allProjects => [..._assetProjects, ..._userProjects];

  // Normaliza acentos y minúsculas para búsquedas robustas en español
  String _fold(String s) {
    final lower = s.toLowerCase();
    return lower
        .replaceAll(RegExp('[áàäâ]'), 'a')
        .replaceAll(RegExp('[éèëê]'), 'e')
        .replaceAll(RegExp('[íìïî]'), 'i')
        .replaceAll(RegExp('[óòöô]'), 'o')
        .replaceAll(RegExp('[úùüû]'), 'u')
        .replaceAll('ñ', 'n')
        .replaceAll('ç', 'c');
  }

  // ===== Filtros
  String? get selectedCategory => _selectedCategory;
  int? get fromYear => _yearFrom;
  int? get toYear => _yearTo;
  String get searchQuery => _search;

  List<String> get distinctCategories => _allProjects
      .map((p) => p.category)
      .where((s) => s.trim().isNotEmpty)
      .toSet()
      .toList()
    ..sort();

  List<int> get distinctYears => _allProjects
      .where((p) => !p.enRedaccion && p.year != null)
      .map((p) => p.year!)
      .toSet()
      .toList()
    ..sort();

  int get total => _allProjects.length;
  int get conCoords => _allProjects.where((p) => p.hasValidCoords).length;
  int get visibles => filteredProjects.length;

  List<Project> get filteredProjects {
    Iterable<Project> it = _allProjects.where((p) => p.hasValidCoords);

    if (_selectedCategory != null) {
      it = it.where((p) => p.category == _selectedCategory);
    }
    if (_yearFrom != null) {
      it = it.where((p) {
        if (p.enRedaccion) return true; // en redacción SIEMPRE visibles
        final y = p.year;
        return y != null && y >= _yearFrom!;
      });
    }
    if (_yearTo != null) {
      it = it.where((p) {
        if (p.enRedaccion) return true; // en redacción SIEMPRE visibles
        final y = p.year;
        return y != null && y <= _yearTo!;
      });
    }

    // Búsqueda por título / municipio / categoría (todas las palabras)
    final q = _fold(_search.trim());
    if (q.isNotEmpty) {
      final tokens = q.split(RegExp(r'\s+')).where((t) => t.isNotEmpty).toList();
      it = it.where((p) {
        final hay = _fold('${p.title} ${p.municipality} ${p.category}');
        return tokens.every((t) => hay.contains(t));
      });
    }

    return it.toList();
  }

  // ===== Mutadores de filtros
  void setCategory(String? c) { _selectedCategory = c; notifyListeners(); }
  void setYearRange({int? fromYear, int? toYear}) { _yearFrom = fromYear; _yearTo = toYear; notifyListeners(); }
  void setSearchQuery(String v) { _search = v; notifyListeners(); }
  void clearFilters() {
    _selectedCategory = 'MEDIOAMBIENTE'; // reset a MEDIOAMBIENTE
    final years = distinctYears;
    if (years.isNotEmpty) {
      _yearFrom = years.first;
      _yearTo = years.last;
    } else {
      _yearFrom = null;
      _yearTo = null;
    }
    _search = '';
    notifyListeners();
  }

  // ===== Admin & proyectos de usuario
  Future<bool> login({required String user, required String pass}) async {
    if (user.trim() == 'admin' && pass == 'geodos2025') {
      _isAdmin = true;
      notifyListeners();
      return true;
    }
    return false;
  }

  void logout() { _isAdmin = false; notifyListeners(); }

  Future<void> addProject(Project p) async {
    _userProjects.add(p);
    await _repo.saveUserProjects(_userProjects);
    notifyListeners();
  }
}