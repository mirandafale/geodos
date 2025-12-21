import 'package:flutter/material.dart';
import 'package:geodos/models/project.dart';


class ProjectInfoDialog extends StatelessWidget {
  final Project project;


  const ProjectInfoDialog({super.key, required this.project});


  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(project.title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Categoría: ${project.category}'),
          Text('Ámbito: ${project.scope.name}'),
          Text('Año: ${project.year ?? 'Sin especificar'}'),
          Text('Isla: ${project.island}'),
          Text('Municipio: ${project.municipality}'),
          Text('Lat/Lon: ${project.lat}, ${project.lon}'),
          const SizedBox(height: 8),
          Text('Descripción: ${project.description ?? 'Sin descripción'}'),
        ],
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