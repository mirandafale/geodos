import 'package:flutter/material.dart';
import 'package:geodos/widgets/app_shell.dart';

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
    return const AppShell(
      title: Text('Contacto'),
      body: Padding(
        padding: EdgeInsets.all(24),
        child: ContactForm(),
      ),
    );
  }
}