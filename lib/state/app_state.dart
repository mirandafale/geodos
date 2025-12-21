// lib/state/app_state.dart

import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../models/project.dart';
import '../services/auth_service.dart';
import '../services/project_service.dart';

/// Estado global mínimo para exponer usuario autenticado y lista de proyectos
/// de Firestore a los widgets heredados del panel.
class AppState extends ChangeNotifier {
  AppState._internal() {
    _authListener = () => notifyListeners();
    AuthService.instance.addListener(_authListener);

    _projectsSub = ProjectService.stream().listen((list) {
      _projects
        ..clear()
        ..addAll(list);
      notifyListeners();
    });
  }

  /// Instancia singleton (no usamos Provider en el árbol principal todavía).
  static final AppState instance = AppState._internal();

  late final VoidCallback _authListener;
  StreamSubscription<List<Project>>? _projectsSub;
  final List<Project> _projects = [];

  User? get user => AuthService.instance.user;
  bool get isAdmin => AuthService.instance.isAdmin;
  List<Project> get projects => List.unmodifiable(_projects);

  Map<String, List<Project>> get visibleProjectsGroupedByCategory {
    final map = <String, List<Project>>{};
    for (final p in _projects) {
      final key = p.category.isNotEmpty ? p.category : 'OTROS';
      map.putIfAbsent(key, () => []).add(p);
    }
    return map;
  }

  List<String> get distinctCategories => _projects
      .map((p) => p.category.trim())
      .where((c) => c.isNotEmpty)
      .toSet()
      .toList()
    ..sort();

  /// Compatibilidad con diálogos antiguos que enviaban `user/pass` o
  /// `email/password` indistintamente.
  Future<bool> signIn({
    String? email,
    String? password,
    String? user,
    String? pass,
  }) async {
    final mail = email ?? user;
    final pwd = password ?? pass;
    if (mail == null || pwd == null) return false;
    try {
      await AuthService.instance.signIn(mail, pwd);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> signOut() => AuthService.instance.signOut();

  Future<void> addProject(Project project) =>
      ProjectService.createOrUpdate(project);

  @override
  void dispose() {
    _projectsSub?.cancel();
    AuthService.instance.removeListener(_authListener);
    super.dispose();
  }
}
