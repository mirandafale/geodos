import 'package:flutter/material.dart';
import 'package:geodos/theme/brand.dart';
import 'package:geodos/widgets/app_shell.dart';

class AccessibilityStatementPage extends StatelessWidget {
  const AccessibilityStatementPage({super.key});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;

    return AppShell(
      title: const Text('Declaración de Accesibilidad'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Declaración de Accesibilidad', style: t.headlineSmall),
            const SizedBox(height: 16),
            Text(
              'GEODOS se compromete a hacer accesible esta página web de conformidad '
              'con los principios de accesibilidad universal y diseño para todas las personas.',
              style: t.bodyMedium,
            ),
            const SizedBox(height: 24),
            const _SectionTitle('Medidas adoptadas'),
            const SizedBox(height: 8),
            _BulletList(
              items: [
                'Contraste adecuado en textos y elementos interactivos.',
                'Navegación clara y consistente en todas las páginas.',
                'Contenido estructurado para facilitar la lectura.',
              ],
            ),
            const SizedBox(height: 24),
            const _SectionTitle('Contacto y sugerencias'),
            const SizedBox(height: 8),
            Text(
              'Estamos trabajando de forma progresiva para mejorar la accesibilidad del sitio. '
              'Si detecta alguna barrera de accesibilidad, puede comunicárnoslo a través del '
              'formulario de contacto para que podamos corregirla.',
              style: t.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;

  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: Brand.primary,
          ),
    );
  }
}

class _BulletList extends StatelessWidget {
  final List<String> items;

  const _BulletList({required this.items});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: items
          .map(
            (text) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('• '),
                  Expanded(child: Text(text, style: t.bodyMedium)),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}
