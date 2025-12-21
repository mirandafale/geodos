// lib/pages/map_page.dart

import 'package:flutter/material.dart';
import 'package:geodos/state/app_state.dart';
import 'package:geodos/widgets/project_form_dialog.dart';
import 'package:geodos/widgets/projects_list_dialog.dart';
import 'package:geodos/widgets/session_action.dart';

class MapPage extends StatelessWidget {
  const MapPage({super.key});

  @override
  Widget build(BuildContext context) {
    final app = AppState.instance;
    final groups = app.visibleProjectsGroupedByCategory;
    final isAdmin = app.isAdmin;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mapa de Proyectos'),
        actions: const [SessionActionWidget()],
      ),
      floatingActionButton: isAdmin
          ? FloatingActionButton(
              onPressed: () => showDialog(
                context: context,
                builder: (_) => ProjectFormDialog(
                  categories: app.distinctCategories,
                  onSubmit: (project) => app.addProject(project),
                ),
              ),
              child: const Icon(Icons.add),
            )
          : null,
      body: ListView(
        children: groups.entries.map((entry) {
          final category = entry.key;
          final group = entry.value;
          return ListTile(
            title: Text(category),
            subtitle: Text('${group.length} proyectos'),
            onTap: () => showDialog(
              context: context,
              builder: (_) => ProjectsListDialog(projects: group),
            ),
          );
        }).toList(),
      ),
    );
  }
}
