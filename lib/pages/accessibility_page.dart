import 'package:flutter/material.dart';
import 'package:geodos/widgets/app_shell.dart';

class AccessibilityStatementPage extends StatelessWidget {
  const AccessibilityStatementPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppShell(
      title: 'Declaración de Accesibilidad',
      body: SingleChildScrollView(
        padding: EdgeInsets.all(24),
        child: _AccessibilityContent(),
      ),
    );
  }
}

class _AccessibilityContent extends StatelessWidget {
  const _AccessibilityContent();

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Declaración de Accesibilidad', style: t.headlineSmall),
        const SizedBox(height: 16),
        Text(
          'GEODOS se compromete a hacer accesible esta página web de conformidad '
              'con los principios de accesibilidad universal y diseño para todas las personas.',
          style: t.bodyMedium,
        ),
        const SizedBox(height: 16),
        Text(
          'Estamos trabajando de forma progresiva para mejorar la accesibilidad del sitio. '
              'Si detecta alguna barrera de accesibilidad, puede comunicárnoslo a través del '
              'formulario de contacto para que podamos corregirla.',
          style: t.bodyMedium,
        ),
      ],
    );
  }
}
