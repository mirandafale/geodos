import 'package:flutter/material.dart';

import '../widgets/contact_form.dart';

/// Página de contacto.
///
/// Presenta un formulario reutilizable para que los usuarios puedan
/// ponerse en contacto con GEODOS. El formulario envía los datos a
/// Firebase y muestra una notificación al usuario.
class ContactPage extends StatelessWidget {
  const ContactPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Contacto'),
      ),
      body: const Padding(
        padding: EdgeInsets.all(24),
        child: ContactForm(),
      ),
    );
  }
}