import 'package:flutter/material.dart';
import '../../services/lead_service.dart';

/// Formulario de contacto reutilizable para GEODOS.
///
/// Este widget se utiliza para capturar la información de contacto
/// (nombre, correo electrónico, empresa y mensaje) y enviarla a
/// Firebase mediante `LeadService`. Se puede incluir en cualquier
/// pantalla de la aplicación.
class ContactForm extends StatefulWidget {
  const ContactForm({super.key});

  @override
  State<ContactForm> createState() => _ContactFormState();
}

class _ContactFormState extends State<ContactForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _companyController = TextEditingController();
  final _messageController = TextEditingController();
  bool _submitting = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
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
              final emailRegex = RegExp(r'^[\w\-.]+@([\w-]+\.)+[\w-]{2,4}\$');
              if (!emailRegex.hasMatch(value)) {
                return 'Introduzca un correo válido';
              }
              return null;
            },
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _companyController,
            decoration: const InputDecoration(
              labelText: 'Empresa (opcional)',
              border: OutlineInputBorder(),
            ),
          ),
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
          ElevatedButton(
            onPressed: _submitting ? null : _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
            ),
            child: _submitting
                ? const SizedBox(
              height: 16,
              width: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
                : const Text('Enviar'),
          ),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    try {
      await LeadService.submit(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        company: _companyController.text.trim(),
        message: _messageController.text.trim(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Solicitud enviada correctamente')),);
      _formKey.currentState!.reset();
      _nameController.clear();
      _emailController.clear();
      _companyController.clear();
      _messageController.clear();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al enviar: \$e')),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }
}