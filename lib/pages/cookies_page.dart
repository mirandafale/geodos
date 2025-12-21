import 'package:flutter/material.dart';

import '../brand/brand.dart';
import '../widgets/legal_scaffold.dart';

class CookiesPolicyPage extends StatelessWidget {
  const CookiesPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;

    return LegalPageScaffold(
      title: 'Política de cookies',
      children: [
        Text(
          'Utilizamos cookies propias y de terceros para recordar tus preferencias,'
          ' mejorar la experiencia de navegación y obtener métricas anónimas sobre'
          ' el uso del sitio.',
          style: t.bodyLarge,
        ),
        const SizedBox(height: 20),
        _SectionTitle('¿Qué cookies usamos?'),
        const SizedBox(height: 8),
        _BulletList(items: const [
          'Cookies técnicas: permiten el funcionamiento básico de la web y la'
              ' seguridad de la sesión.',
          'Cookies de personalización: guardan idioma u otras preferencias para'
              ' ofrecer una navegación coherente.',
          'Cookies analíticas: recogen datos agregados y anónimos sobre el uso'
              ' del sitio para mejorar contenidos y servicios.',
        ]),
        const SizedBox(height: 20),
        _SectionTitle('Cómo gestionar las cookies'),
        const SizedBox(height: 8),
        Text(
          'Puedes aceptar, rechazar o configurar las cookies desde las opciones de'
          ' tu navegador. Las guías oficiales de Chrome, Firefox, Edge y Safari'
          ' explican cómo hacerlo paso a paso. Desactivar ciertas cookies puede'
          ' limitar la funcionalidad de algunas secciones, pero el acceso a la'
          ' información principal seguirá disponible.',
          style: t.bodyMedium,
        ),
        const SizedBox(height: 20),
        Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Actualizaciones',
                  style: t.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: Brand.primary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Revisamos periódicamente esta política para reflejar cambios en las'
                  ' tecnologías utilizadas o en la normativa aplicable. Indicaremos la'
                  ' fecha de la última actualización en este mismo apartado.',
                  style: t.bodyMedium,
                ),
              ],
            ),
          ),
        ),
      ],
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
