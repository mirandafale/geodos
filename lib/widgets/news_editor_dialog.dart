// lib/widgets/news_editor_dialog.dart
import 'package:flutter/material.dart';

import '../models/news_item.dart';
import '../services/news_service.dart';

class NewsEditorDialog extends StatefulWidget {
  final NewsItem? initial;

  const NewsEditorDialog({super.key, this.initial});

  @override
  State<NewsEditorDialog> createState() => _NewsEditorDialogState();
}

class _NewsEditorDialogState extends State<NewsEditorDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleCtrl;
  late final TextEditingController _bodyCtrl;
  late final TextEditingController _imageCtrl;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.initial?.title ?? '');
    _bodyCtrl = TextEditingController(text: widget.initial?.body ?? '');
    _imageCtrl = TextEditingController(text: widget.initial?.imageUrl ?? '');
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _bodyCtrl.dispose();
    _imageCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _saving = true;
    });

    final now = DateTime.now();
    final base = NewsItem(
      id: widget.initial?.id ?? '',
      title: _titleCtrl.text.trim(),
      body: _bodyCtrl.text.trim(),
      imageUrl: _imageCtrl.text.trim().isEmpty
          ? 'https://images.pexels.com/photos/3184465/pexels-photo-3184465.jpeg?auto=compress&cs=tinysrgb&w=1200'
          : _imageCtrl.text.trim(),
      createdAt: widget.initial?.createdAt ?? now,
      updatedAt: now,
      published: widget.initial?.published ?? true,
    );

    try {
      if (widget.initial == null) {
        await NewsService.create(base);
      } else {
        await NewsService.update(base);
      }
      if (mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.initial != null;

    return AlertDialog(
      title: Text(isEdit ? 'Editar noticia' : 'Nueva noticia'),
      content: SizedBox(
        width: 450,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _titleCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Título',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Obligatorio' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _bodyCtrl,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Resumen / descripción corta',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Obligatorio' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _imageCtrl,
                  decoration: const InputDecoration(
                    labelText: 'URL de imagen (opcional)',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
              : const Text('Guardar'),
        ),
      ],
    );
  }
}
