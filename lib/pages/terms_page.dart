import 'package:flutter/material.dart';

import '../brand/brand.dart';
import '../widgets/legal_scaffold.dart';

class TermsConditionsPage extends StatelessWidget {
  const TermsConditionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;

    return LegalPageScaffold(
      title: 'Aviso legal y condiciones de uso',
      children: [
        Text(
          'El acceso y uso de este sitio web implica la aceptación de las presentes'
          ' condiciones. La información publicada tiene carácter divulgativo y puede'
          ' actualizarse sin previo aviso para reflejar mejoras en los servicios.',
          style: t.bodyLarge,
        ),
        const SizedBox(height: 20),
        _SectionTitle('Titularidad del sitio'),
        const SizedBox(height: 8),
        Text(
          'GEODOS es titular del dominio y responsable de los contenidos. Puedes'
          ' contactar a través del formulario de la web o escribiendo a'
          ' info@geodos.es para cualquier cuestión relacionada con los derechos de'
          ' propiedad intelectual o la gestión de datos.',
          style: t.bodyMedium,
        ),
        const SizedBox(height: 20),
        _SectionTitle('Uso correcto de los contenidos'),
        const SizedBox(height: 8),
        _BulletList(items: const [
          'No se permite reproducir, distribuir ni modificar la información sin'
              ' autorización expresa.',
          'El usuario se compromete a utilizar la web de forma diligente y a no'
              ' realizar actividades que dañen la seguridad o disponibilidad del'
              ' servicio.',
          'Los enlaces a sitios externos se proporcionan para comodidad del usuario'
              ' y GEODOS no se hace responsable de su contenido.',
        ]),
        const SizedBox(height: 20),
        Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Responsabilidad',
                  style: t.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: Brand.primary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Trabajamos para que la información sea precisa y esté actualizada,'
                  ' pero no podemos garantizar la ausencia de errores. GEODOS no'
                  ' responderá por daños derivados del uso de la web más allá de lo'
                  ' exigido por la normativa vigente.',
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
