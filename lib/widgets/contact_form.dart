import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:geodos/services/firebase_service.dart';
import 'package:geodos/theme/brand.dart';

/// Formulario de contacto reutilizable para GEODOS.
///
/// Este widget se utiliza para capturar la información de contacto
/// (nombre, correo electrónico, empresa y mensaje) y enviarla a
/// Firebase mediante `FirebaseService`. Se puede incluir en cualquier
/// pantalla de la aplicación y permite indicar la sección de origen
/// del envío.
class ContactForm extends StatefulWidget {
  const ContactForm({
    super.key,
    this.originSection = 'contact_page',
    this.source,
    this.showCompanyField = true,
    this.showProjectTypeField = false,
    this.title = 'Envíanos tu consulta',
    this.helperText =
        'Tus datos se almacenan de forma segura en Firebase al enviar el formulario.',
    this.successMessage = 'Solicitud enviada correctamente',
    this.projectTypeLabel = 'Tipo de proyecto (opcional)',
  });

  final String originSection;
  final String? source;
  final bool showCompanyField;
  final bool showProjectTypeField;
  final String title;
  final String helperText;
  final String successMessage;
  final String projectTypeLabel;

  @override
  State<ContactForm> createState() => _ContactFormState();
}

class _ContactFormState extends State<ContactForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _companyController = TextEditingController();
  final _projectTypeController = TextEditingController();
  final _messageController = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _companyController.dispose();
    _projectTypeController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                widget.title,
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700, color: Brand.primary),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nombre',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Por favor, introduzca su nombre';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Correo electrónico',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Por favor, introduzca su correo electrónico';
                  }
                  final emailRegex = RegExp(
                      '^[\\w\\-.]+@([\\w-]+\\.)+[\\w-]{2,}\$');
                  if (!emailRegex.hasMatch(value)) {
                    return 'Introduzca un correo válido';
                  }
                  return null;
                },
              ),
              if (widget.showCompanyField) ...[
                const SizedBox(height: 12),
                TextFormField(
                  controller: _companyController,
                  decoration: const InputDecoration(
                    labelText: 'Empresa (opcional)',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
              if (widget.showProjectTypeField) ...[
                const SizedBox(height: 12),
                TextFormField(
                  controller: _projectTypeController,
                  decoration: InputDecoration(
                    labelText: widget.projectTypeLabel,
                    border: const OutlineInputBorder(),
                  ),
                ),
              ],
              const SizedBox(height: 12),
              TextFormField(
                controller: _messageController,
                decoration: const InputDecoration(
                  labelText: 'Mensaje',
                  border: OutlineInputBorder(),
                ),
                maxLines: 4,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Por favor, escriba su mensaje';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _submitting ? null : _submit,
                style: FilledButton.styleFrom(
                  backgroundColor: Brand.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                icon: _submitting
                    ? const SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.send),
                label: Text(_submitting ? 'Enviando...' : 'Enviar'),
              ),
              const SizedBox(height: 6),
              Text(
                widget.helperText,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    try {
      await FirebaseService.submitContactMessage(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        company: _companyController.text.trim(),
        message: _messageController.text.trim(),
        originSection: widget.originSection,
        projectType: _projectTypeController.text.trim(),
        source: widget.source ?? widget.originSection,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(widget.successMessage)),
      );
      _formKey.currentState!.reset();
      _nameController.clear();
      _emailController.clear();
      _companyController.clear();
      _projectTypeController.clear();
      _messageController.clear();
    } on FirebaseException catch (e, stackTrace) {
      debugPrint(
        'ContactForm Firebase error (${e.code}): ${e.message}',
      );
      debugPrintStack(stackTrace: stackTrace);
      if (!mounted) return;
      final message = e.message?.isNotEmpty == true
          ? e.message!
          : 'No hemos podido enviar tu mensaje. Inténtalo de nuevo.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } catch (e, stackTrace) {
      debugPrint('ContactForm submit failed: $e');
      debugPrintStack(stackTrace: stackTrace);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Se produjo un error inesperado. Inténtalo de nuevo.')),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }
}
