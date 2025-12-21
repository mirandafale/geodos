// lib/widgets/admin_project_dialog.dart

import 'package:flutter/material.dart';
import 'package:geodos/models/project.dart';

class AdminProjectDialog extends StatelessWidget {
  final void Function(Project) onCreate;

  const AdminProjectDialog({super.key, required this.onCreate});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Crear Proyecto'),
      content: const Text('¿Deseas crear un nuevo proyecto con valores por defecto?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () {
            final project = Project(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              title: 'Nuevo Proyecto',
              municipality: 'Desconocido',
              category: 'General',
              scope: ProjectScope.insular,
              year: DateTime.now().year,
              lat: 0.0,
              lon: 0.0,
              island: 'Isla X',
              description: 'Sin descripción',
              enRedaccion: false,
            );
            onCreate(project);
            Navigator.of(context).pop();
          },
          child: const Text('Crear'),
        ),
      ],
    );
  }
}
