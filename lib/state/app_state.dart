import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:geodos/models/project.dart';
import 'package:geodos/services/auth_service.dart';
import 'package:geodos/services/project_service.dart';

class AppState extends ChangeNotifier {
  AppState._({AuthService? authService})
      : _authService = authService ?? AuthService.instance {
    _authListener = () {
      debugPrint(
        'AppState: auth change loggedIn=${_authService.isLoggedIn} admin=${_authService.isAdmin}',
      );
      notifyListeners();
    };
    _authService.addListener(_authListener);
  }

  static final AppState instance = AppState._();

  final AuthService _authService;
  List<Project> _projects = [];
  bool _loadingProjects = false;
  late final VoidCallback _authListener;
  StreamSubscription<List<Project>>? _projectsSubscription;

  bool get isAdmin => _authService.isAdmin;
  bool get isLoggedIn => _authService.isLoggedIn;
  List<Project> get projects => List.unmodifiable(_projects);
  bool get isLoadingProjects => _loadingProjects;

  Map<String, List<Project>> get visibleProjectsGroupedByCategory {
    final map = <String, List<Project>>{};
    for (final p in _projects) {
      map.putIfAbsent(p.category, () => []).add(p);
    }
    return map;
  }

  List<String> get distinctCategories =>
      _projects.map((p) => p.category).toSet().toList();

  Future<void> loadProjects() async {
    if (_loadingProjects) return;
    _loadingProjects = true;
    notifyListeners();
    try {
      _projects = await ProjectService.stream().first;
      debugPrint('AppState: loadProjects -> ${_projects.length} proyectos');
    } finally {
      _loadingProjects = false;
      notifyListeners();
    }
  }

  Future<void> refreshProjects() async {
    debugPrint('AppState: refreshProjects solicitado');
    await loadProjects();
  }

  Future<void> watchProjects() async {
    await _projectsSubscription?.cancel();
    _projectsSubscription = ProjectService.stream().listen((items) {
      _projects = items;
      notifyListeners();
    });
  }

  Future<void> addProject(Project project) async {
    await ProjectService.createAdminProject(project);
  }

  Future<bool> signIn({
    String? user,
    String? pass,
    String? email,
    String? password,
  }) async {
    try {
      await _authService.signIn(
        email: email ?? user ?? '',
        password: password ?? pass ?? '',
      );
      debugPrint('AppState: signIn ok admin=${_authService.isAdmin}');
      notifyListeners();
      return true;
    } catch (error) {
      debugPrint('AppState: signIn error=$error');
      return false;
    }
  }

  Future<void> logout() async {
    await _authService.signOut();
    notifyListeners();
  }

  @override
  void dispose() {
    _authService.removeListener(_authListener);
    _projectsSubscription?.cancel();
    super.dispose();
  }
}
