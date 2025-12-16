// lib/widgets/projects_list_dialog.dart

import 'package:flutter/material.dart';
import 'package:geodos/models/project.dart';
import 'package:geodos/widgets/project_info_dialog.dart';

class ProjectsListDialog extends StatelessWidget {
  final List<Project> projects;

  const ProjectsListDialog({super.key, required this.projects});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Proyectos en esta categoría'),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: projects.length,
          itemBuilder: (context, index) {
            final project = projects[index];
            return ListTile(
              title: Text(project.title),
              subtitle: Text(project.category),
              onTap: () => showDialog(
                context: context,
                builder: (_) => ProjectInfoDialog(project: project),
              ),
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cerrar'),
        ),
      ],
    );
  }
}