// lib/widgets/project_form_dialog.dart

import 'package:flutter/material.dart';
import 'package:geodos/models/project.dart';
import 'package:geodos/services/project_service.dart';
import 'package:geodos/widgets/coordinate_picker.dart';
import 'package:latlong2/latlong.dart';

class ProjectFormDialog extends StatefulWidget {
  final Project? initial;
  final List<String> categories;
  final void Function(Project)? onSubmit;

  const ProjectFormDialog({super.key, this.initial, required this.categories, this.onSubmit});

  @override
  State<ProjectFormDialog> createState() => _ProjectFormDialogState();
}

class _ProjectFormDialogState extends State<ProjectFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final Project _baseProject;

  final _title = TextEditingController();
  final _category = TextEditingController();
  final _lat = TextEditingController();
  final _lng = TextEditingController();
  late ProjectScope _scope;
  LatLng? _initialPoint;

  @override
  void initState() {
    super.initState();
    _baseProject = widget.initial ?? ProjectService.emptyProject();
    _title.text = _baseProject.title;
    _category.text = _baseProject.category;
    _scope = _baseProject.scope;
    if (_baseProject.lat != 0 && _baseProject.lon != 0) {
      _initialPoint = LatLng(_baseProject.lat, _baseProject.lon);
      _lat.text = _baseProject.lat.toStringAsFixed(6);
      _lng.text = _baseProject.lon.toStringAsFixed(6);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Formulario de proyecto'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _title,
                decoration: const InputDecoration(labelText: 'Título'),
                validator: (v) => v == null || v.trim().isEmpty ? 'Campo obligatorio' : null,
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<ProjectScope>(
                value: _scope,
                items: ProjectScope.values
                    .map((s) => DropdownMenuItem(value: s, child: Text(s.name.toUpperCase())))
                    .toList(),
                onChanged: (v) => setState(() => _scope = v ?? ProjectScope.insular),
                decoration: const InputDecoration(labelText: 'Ámbito'),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _category.text.isNotEmpty ? _category.text : null,
                items: widget.categories
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (v) => _category.text = v ?? '',
                decoration: const InputDecoration(labelText: 'Categoría'),
              ),
              const SizedBox(height: 12),
              CoordinatePicker(
                latCtrl: _lat,
                lonCtrl: _lng,
                initialPoint: _initialPoint,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _lat,
                decoration: const InputDecoration(
                  labelText: 'Latitud',
                  helperText: 'Selecciona el punto en el mapa',
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (v) => double.tryParse((v ?? '').replaceAll(',', '.')) == null
                    ? 'Introduce una coordenada válida'
                    : null,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _lng,
                decoration: const InputDecoration(
                  labelText: 'Longitud',
                  helperText: 'Selecciona el punto en el mapa',
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (v) => double.tryParse((v ?? '').replaceAll(',', '.')) == null
                    ? 'Introduce una coordenada válida'
                    : null,
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
        ElevatedButton(
          onPressed: _save,
          child: const Text('Guardar'),
        ),
      ],
    );
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final project = _baseProject.copyWith(
      title: _title.text.trim(),
      scope: _scope,
      category: _category.text.trim(),
      lat: double.parse(_lat.text.replaceAll(',', '.')),
      lon: double.parse(_lng.text.replaceAll(',', '.')),
      municipality: _baseProject.municipality.isNotEmpty
          ? _baseProject.municipality
          : 'Municipio desconocido',
      island: _baseProject.island.isNotEmpty ? _baseProject.island : 'Isla',
      year: _baseProject.year ?? DateTime.now().year,
      enRedaccion: _baseProject.enRedaccion,
      updatedAt: DateTime.now(),
      createdAt: _baseProject.createdAt ?? DateTime.now(),
    );
    widget.onSubmit?.call(project);
    Navigator.of(context).pop(project);
  }
}
