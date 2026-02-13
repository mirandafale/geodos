import 'package:flutter/material.dart';
import 'package:geodos/brand/brand.dart';
import 'package:geodos/services/firebase_service.dart';

/// Formulario de contacto reutilizable para GEODOS.
///
/// Este widget se utiliza para capturar la información de contacto
/// (nombre, correo electrónico, empresa y mensaje) y enviarla a
/// Firebase mediante `FirebaseService`. Se puede incluir en cualquier
/// pantalla de la aplicación y permite indicar la sección de origen
/// del envío.
class ContactForm extends StatefulWidget {
  final String originSection;

  const ContactForm({super.key, this.originSection = 'home'});

  @override
  State<ContactForm> createState() => _ContactFormState();
}

class _ContactFormState extends State<ContactForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _companyController = TextEditingController();
  final _messageController = TextEditingController();
  final _nameFocus = FocusNode();
  final _emailFocus = FocusNode();
  final _companyFocus = FocusNode();
  final _messageFocus = FocusNode();
  bool _submitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _companyController.dispose();
    _messageController.dispose();
    _nameFocus.dispose();
    _emailFocus.dispose();
    _companyFocus.dispose();
    _messageFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 900;
        final horizontalGap = isDesktop ? 16.0 : 0.0;

        return Card(
          elevation: 0,
          color: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            padding: const EdgeInsets.all(22),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Envíanos tu consulta',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: Brand.primary,
                        ),
                  ),
                  const SizedBox(height: 12),
                  if (isDesktop)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            children: [
                              _nameField(),
                              const SizedBox(height: 12),
                              _emailField(),
                              const SizedBox(height: 12),
                              _companyField(),
                            ],
                          ),
                        ),
                        SizedBox(width: horizontalGap),
                        Expanded(
                          child: _messageField(maxLines: 9),
                        ),
                      ],
                    )
                  else ...[
                    _nameField(),
                    const SizedBox(height: 12),
                    _emailField(),
                    const SizedBox(height: 12),
                    _companyField(),
                    const SizedBox(height: 12),
                    _messageField(maxLines: 4),
                  ],
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 48,
                    width: double.infinity,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF0F4C81), Color(0xFF2A9D8F)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 10,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ElevatedButton.icon(
                        onPressed: _submitting ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          elevation: 0,
                          backgroundColor: Colors.transparent,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: Colors.transparent,
                          disabledForegroundColor: Colors.white70,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: _submitting
                            ? const SizedBox(
                                height: 16,
                                width: 16,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.send),
                        label: Text(_submitting ? 'Enviando...' : 'Enviar mensaje'),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Tus datos se almacenan de forma segura en Firebase al enviar el formulario.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _nameField() {
    return _buildField(
      focusNode: _nameFocus,
      child: TextFormField(
        controller: _nameController,
        focusNode: _nameFocus,
        decoration: _inputDecoration('Nombre'),
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return 'Por favor, introduzca su nombre';
          }
          return null;
        },
      ),
    );
  }

  Widget _emailField() {
    return _buildField(
      focusNode: _emailFocus,
      child: TextFormField(
        controller: _emailController,
        focusNode: _emailFocus,
        decoration: _inputDecoration('Correo electrónico'),
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return 'Por favor, introduzca su correo electrónico';
          }
          final emailRegex = RegExp('^[\\w\\-.]+@([\\w-]+\\.)+[\\w-]{2,}\$');
          if (!emailRegex.hasMatch(value)) {
            return 'Introduzca un correo válido';
          }
          return null;
        },
      ),
    );
  }

  Widget _companyField() {
    return _buildField(
      focusNode: _companyFocus,
      child: TextFormField(
        controller: _companyController,
        focusNode: _companyFocus,
        decoration: _inputDecoration('Tipo de proyecto'),
      ),
    );
  }

  Widget _messageField({required int maxLines}) {
    return _buildField(
      focusNode: _messageFocus,
      child: TextFormField(
        controller: _messageController,
        focusNode: _messageFocus,
        decoration: _inputDecoration('Mensaje'),
        maxLines: maxLines,
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return 'Por favor, escriba su mensaje';
          }
          return null;
        },
      ),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Brand.primary, width: 1.6),
      ),
    );
  }

  Widget _buildField({
    required FocusNode focusNode,
    required Widget child,
  }) {
    return ListenableBuilder(
      listenable: focusNode,
      builder: (context, _) {
        final hasFocus = focusNode.hasFocus;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: hasFocus ? Brand.secondary.withOpacity(0.2) : Colors.black12,
                blurRadius: hasFocus ? 10 : 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: child,
        );
      },
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
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Solicitud enviada correctamente')),
      );
      _formKey.currentState!.reset();
      _nameController.clear();
      _emailController.clear();
      _companyController.clear();
      _messageController.clear();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al enviar: $e')),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }
}
