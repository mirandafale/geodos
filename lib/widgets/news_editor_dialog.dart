// lib/widgets/news_editor_dialog.dart
import 'dart:io' as io;
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../models/news_item.dart';
import '../services/auth_service.dart';
import '../services/firebase_service.dart';
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
  late final TextEditingController _summaryCtrl;
  late final TextEditingController _imageCtrl;
  bool _published = false;
  bool _saving = false;
  bool _uploading = false;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.initial?.title ?? '');
    _summaryCtrl = TextEditingController(text: widget.initial?.summary ?? '');
    _imageCtrl = TextEditingController(text: widget.initial?.imageUrl ?? '');
    _published = widget.initial?.published ?? false;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _summaryCtrl.dispose();
    _imageCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadImage() async {
    setState(() {
      _uploading = true;
    });
    try {
      final result = await FilePicker.platform
          .pickFiles(type: FileType.image, allowMultiple: false, withData: true);
      if (result == null || result.files.isEmpty) return;
      final file = result.files.single;
      Uint8List? bytes = file.bytes;
      if (bytes == null && file.path != null && !kIsWeb) {
        bytes = await io.File(file.path!).readAsBytes();
      }
      if (bytes == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo leer la imagen seleccionada.')),
        );
        return;
      }

      final url = await FirebaseService.uploadImageToStorage(
        bytes,
        folder: 'news_images',
        fileName: file.name,
      );
      if (!mounted) return;
      setState(() {
        _imageCtrl.text = url;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Imagen subida correctamente.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al subir imagen: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _uploading = false;
        });
      }
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    if (!AuthService.instance.isAdmin) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Solo un administrador autenticado puede guardar.')),
      );
      return;
    }

    setState(() {
      _saving = true;
    });

    final now = DateTime.now();
    final base = NewsItem(
      id: widget.initial?.id ?? '',
      title: _titleCtrl.text.trim(),
      summary: _summaryCtrl.text.trim(),
      imageUrl: _imageCtrl.text.trim().isEmpty
          ? 'https://images.pexels.com/photos/3184465/pexels-photo-3184465.jpeg?auto=compress&cs=tinysrgb&w=1200'
          : _imageCtrl.text.trim(),
      createdAt: widget.initial?.createdAt ?? now,
      updatedAt: now,
      published: _published,
    );

    try {
      if (widget.initial == null) {
        await NewsService.create(base);
      } else {
        await NewsService.update(base);
      }
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo guardar la noticia: $e')),
      );
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
                  controller: _summaryCtrl,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Resumen / descripción corta',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Obligatorio' : null,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _imageCtrl,
                        decoration: const InputDecoration(
                          labelText: 'URL de imagen (opcional)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    FilledButton.tonalIcon(
                      onPressed: _uploading ? null : _pickAndUploadImage,
                      icon: _uploading
                          ? const SizedBox(
                              height: 16,
                              width: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.cloud_upload),
                      label: const Text('Subir'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  value: _published,
                  title: const Text('Publicar'),
                  subtitle: const Text('Solo las noticias publicadas se mostrarán en la web'),
                  onChanged: (v) => setState(() => _published = v),
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
