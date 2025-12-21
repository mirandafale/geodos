// lib/widgets/project_form_dialog.dart

import 'package:flutter/material.dart';
import 'package:geodos/models/project.dart';

class ProjectFormDialog extends StatefulWidget {
  final Project? initial;
  final List<String> categories;

  const ProjectFormDialog({super.key, this.initial, required this.categories});

  @override
  State<ProjectFormDialog> createState() => _ProjectFormDialogState();
}

class _ProjectFormDialogState extends State<ProjectFormDialog> {
  final _title = TextEditingController();
  final _scope = TextEditingController();
  final _category = TextEditingController();
  final _municipality = TextEditingController();
  final _island = TextEditingController();
  final _year = TextEditingController();
  final _lat = TextEditingController();
  final _lng = TextEditingController();

  @override
  void initState() {
    super.initState();
    final p = widget.initial;
    if (p != null) {
      _title.text = p.title;
      _scope.text = p.scope.name;
      _category.text = p.category;
      _municipality.text = p.municipality;
      _island.text = p.island;
      if (p.year != null) _year.text = p.year.toString();
      _lat.text = p.lat.toString();
      _lng.text = p.lon.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Formulario de proyecto'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _title,
              decoration: const InputDecoration(labelText: 'Título'),
            ),
            TextField(
              controller: _scope,
              decoration: const InputDecoration(labelText: 'Ámbito'),
            ),
            TextField(
              controller: _municipality,
              decoration: const InputDecoration(labelText: 'Municipio'),
            ),
            TextField(
              controller: _island,
              decoration: const InputDecoration(labelText: 'Isla'),
            ),
            TextField(
              controller: _year,
              decoration: const InputDecoration(labelText: 'Año'),
              keyboardType: TextInputType.number,
            ),
            DropdownButtonFormField<String>(
              value: _category.text.isNotEmpty ? _category.text : null,
              items: widget.categories
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (v) => _category.text = v ?? '',
              decoration: const InputDecoration(labelText: 'Categoría'),
            ),
            TextField(
              controller: _lat,
              decoration: const InputDecoration(labelText: 'Latitud'),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: _lng,
              decoration: const InputDecoration(labelText: 'Longitud'),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () {
            final project = Project(
              id: widget.initial?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
              title: _title.text,
              scope: ProjectScope.values.firstWhere(
                (e) => e.name == _scope.text.trim(),
                orElse: () => ProjectScope.insular,
              ),
              municipality: _municipality.text,
              year: int.tryParse(_year.text),
              category: _category.text,
              lat: double.tryParse(_lat.text) ?? 0.0,
              lon: double.tryParse(_lng.text) ?? 0.0,
              island: _island.text,
              enRedaccion: false,
            );
            Navigator.of(context).pop(project);
          },
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}
