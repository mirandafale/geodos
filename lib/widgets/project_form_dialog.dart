// lib/widgets/project_form_dialog.dart

import 'package:flutter/material.dart';
import 'package:geodos/models/project.dart';

class ProjectFormDialog extends StatefulWidget {
  final Project? initial;
  final List<String> categories;
  final ValueChanged<Project>? onSubmit;

  const ProjectFormDialog({
    super.key,
    this.initial,
    required this.categories,
    this.onSubmit,
  });

  @override
  State<ProjectFormDialog> createState() => _ProjectFormDialogState();
}

class _ProjectFormDialogState extends State<ProjectFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _municipality = TextEditingController();
  final _island = TextEditingController();
  final _year = TextEditingController();
  final _category = TextEditingController();
  final _lat = TextEditingController();
  final _lng = TextEditingController();
  final _description = TextEditingController();
  ProjectScope _scope = ProjectScope.insular;
  bool _enRedaccion = false;

  @override
  void initState() {
    super.initState();
    final p = widget.initial;
    if (p != null) {
      _title.text = p.title;
      _municipality.text = p.municipality;
      _island.text = p.island;
      _year.text = p.year?.toString() ?? '';
      _category.text = p.category;
      _lat.text = p.lat.toString();
      _lng.text = p.lon.toString();
      _description.text = p.description ?? '';
      _scope = p.scope;
      _enRedaccion = p.enRedaccion;
    }
  }

  @override
  void dispose() {
    _title.dispose();
    _municipality.dispose();
    _island.dispose();
    _year.dispose();
    _category.dispose();
    _lat.dispose();
    _lng.dispose();
    _description.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final project = Project(
      id: widget.initial?.id ?? '',
      title: _title.text.trim(),
      municipality: _municipality.text.trim(),
      year: _enRedaccion ? null : int.tryParse(_year.text.trim()),
      category: _category.text.trim(),
      lat: double.tryParse(_lat.text.trim()) ?? 0.0,
      lon: double.tryParse(_lng.text.trim()) ?? 0.0,
      island: _island.text.trim(),
      scope: _scope,
      enRedaccion: _enRedaccion,
      description:
          _description.text.trim().isEmpty ? null : _description.text.trim(),
    );

    widget.onSubmit?.call(project);
    Navigator.of(context).pop(project);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.initial == null
          ? 'Crear proyecto'
          : 'Editar proyecto'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _title,
                decoration: const InputDecoration(labelText: 'Título'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Obligatorio' : null,
              ),
              TextFormField(
                controller: _municipality,
                decoration: const InputDecoration(labelText: 'Municipio'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Obligatorio' : null,
              ),
              TextFormField(
                controller: _island,
                decoration: const InputDecoration(labelText: 'Isla'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Obligatorio' : null,
              ),
              DropdownButtonFormField<ProjectScope>(
                value: _scope,
                decoration: const InputDecoration(labelText: 'Ámbito'),
                items: ProjectScope.values
                    .where((s) => s != ProjectScope.unknown)
                    .map(
                      (s) => DropdownMenuItem(
                        value: s,
                        child: Text(s.name.toUpperCase()),
                      ),
                    )
                    .toList(),
                onChanged: (v) => setState(() => _scope = v ?? _scope),
              ),
              DropdownButtonFormField<String>(
                value: _category.text.isNotEmpty ? _category.text : null,
                items: widget.categories
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (v) => setState(() => _category.text = v ?? ''),
                decoration: const InputDecoration(labelText: 'Categoría'),
              ),
              TextFormField(
                controller: _year,
                decoration: const InputDecoration(labelText: 'Año'),
                keyboardType: TextInputType.number,
                enabled: !_enRedaccion,
                validator: (v) {
                  if (_enRedaccion) return null;
                  if (v == null || v.trim().isEmpty) return 'Obligatorio';
                  final parsed = int.tryParse(v);
                  if (parsed == null) return 'Año no válido';
                  return null;
                },
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: _enRedaccion,
                onChanged: (v) => setState(() => _enRedaccion = v),
                title: const Text('En redacción (sin año)'),
              ),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _lat,
                      decoration: const InputDecoration(labelText: 'Latitud'),
                      keyboardType: TextInputType.number,
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Obligatorio' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _lng,
                      decoration:
                          const InputDecoration(labelText: 'Longitud'),
                      keyboardType: TextInputType.number,
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Obligatorio' : null,
                    ),
                  ),
                ],
              ),
              TextFormField(
                controller: _description,
                decoration:
                    const InputDecoration(labelText: 'Descripción (opcional)'),
                maxLines: 3,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _save,
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}
