import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/project.dart';

class ProjectRepository {
  const ProjectRepository();

  Future<List<Project>> loadFromAsset(String assetPath) async {
    final raw = await rootBundle.loadString(assetPath);
    return Project.listFromJsonString(raw);
  }

  static const String _userKey = 'user_projects_v1';

  Future<List<Project>> loadUserProjects() async {
    final sp = await SharedPreferences.getInstance();
    final raw = sp.getString(_userKey);
    if (raw == null || raw.trim().isEmpty) return [];
    try {
      final list = (jsonDecode(raw) as List)
          .map((e) => e is Map<String, dynamic> ? Project.fromJson(e) : null)
          .whereType<Project>()
          .toList();
      return list;
    } catch (_) {
      return [];
    }
  }

  Future<void> saveUserProjects(List<Project> list) async {
    final sp = await SharedPreferences.getInstance();
    final raw = jsonEncode(list.map((e) => e.toJson()).toList());
    await sp.setString(_userKey, raw);
  }
}
