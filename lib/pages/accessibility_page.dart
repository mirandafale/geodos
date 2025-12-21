import 'package:flutter/material.dart';

import '../brand/brand.dart';
import '../widgets/legal_scaffold.dart';

class AccessibilityStatementPage extends StatelessWidget {
  const AccessibilityStatementPage({super.key});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;

    return LegalPageScaffold(
      title: 'Declaración de Accesibilidad',
      children: [
        Text(
          'Nos comprometemos a que cualquier persona pueda navegar, entender y usar'
          ' la web de GEODOS con independencia de sus capacidades, dispositivo o'
          ' contexto de uso. Trabajamos de manera continua para cumplir con las'
          ' pautas WCAG 2.1 en nivel AA.',
          style: t.bodyLarge,
        ),
        const SizedBox(height: 20),
        _SectionTitle('Principios aplicados'),
        const SizedBox(height: 8),
        _BulletList(items: const [
          'Uso de contrastes adecuados y jerarquías tipográficas claras.',
          'Textos alternativos en imágenes y descripciones en elementos clave.',
          'Compatibilidad con navegación mediante teclado y lectores de pantalla.',
          'Formularios accesibles con etiquetas visibles y mensajes de error claros.',
          'Estructuras responsivas que se adaptan a distintos anchos de pantalla.',
        ]),
        const SizedBox(height: 20),
        _SectionTitle('Situaciones excepcionales'),
        const SizedBox(height: 8),
        Text(
          'Si detectas alguna barrera de accesibilidad, como contenidos que no se'
          ' puedan operar con teclado, contrastes insuficientes o errores en la'
          ' descripción de elementos, te agradecemos que nos lo comuniques para'
          ' resolverlo lo antes posible.',
          style: t.bodyMedium,
        ),
        const SizedBox(height: 20),
        _SectionTitle('Canales de contacto accesible'),
        const SizedBox(height: 8),
        Text(
          'Puedes escribirnos a info@geodos.es, usar el formulario de contacto o'
          ' llamarnos al número habitual de la oficina. Responderemos en un máximo'
          ' de 2 días laborables y te mantendremos informado del seguimiento.',
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
                  'Mejora continua',
                  style: t.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: Brand.primary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Revisamos la web de forma periódica para detectar incidencias y'
                  ' garantizar que nuevas funcionalidades mantengan el mismo nivel'
                  ' de accesibilidad. Priorizamos las correcciones que afecten al'
                  ' acceso a la información esencial.',
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
