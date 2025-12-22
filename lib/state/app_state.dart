import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:geodos/models/project.dart';
import 'package:geodos/services/auth_service.dart';
import 'package:geodos/services/project_service.dart';

class AppState extends ChangeNotifier {
  AppState._();

  static final AppState instance = AppState._();

  bool _isAdmin = false;
  List<Project> _projects = [];

  bool get isAdmin => _isAdmin;
  List<Project> get projects => List.unmodifiable(_projects);

  Map<String, List<Project>> get visibleProjectsGroupedByCategory {
    final map = <String, List<Project>>{};
    for (final p in _projects) {
      map.putIfAbsent(p.category, () => []).add(p);
    }
    return map;
  }

  List<String> get distinctCategories => _projects.map((p) => p.category).toSet().toList();

  Future<void> loadProjects() async {
    _projects = await ProjectService.stream().first;
    notifyListeners();
  }

  Future<void> addProject(Project project) async {
    await ProjectService.createAdminProject(project);
  }

  Future<bool> signIn({String? user, String? pass, String? email, String? password}) async {
    try {
      await AuthService.instance.signIn(
        email: email ?? user ?? '',
        password: password ?? pass ?? '',
      );
      _isAdmin = AuthService.instance.isAdmin;
      notifyListeners();
      return true;
    } on FirebaseAuthException {
      return false;
    }
  }

  void logout() {
    AuthService.instance.signOut();
    _isAdmin = false;
    notifyListeners();
  }
}
