import 'package:flutter/material.dart';

import '../brand/brand.dart';
import '../widgets/legal_scaffold.dart';

class DataPrivacySettingsPage extends StatelessWidget {
  const DataPrivacySettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;

    return LegalPageScaffold(
      title: 'Configuración de privacidad',
      children: [
        Text(
          'En este apartado puedes revisar de forma clara cómo tratamos tus datos y'
          ' qué opciones tienes para controlar el uso de tu información personal.',
          style: t.bodyLarge,
        ),
        const SizedBox(height: 20),
        _SectionTitle('Tus preferencias'),
        const SizedBox(height: 8),
        _BulletList(items: const [
          'Revocar el consentimiento otorgado para comunicaciones comerciales.',
          'Solicitar la actualización o rectificación de datos inexactos.',
          'Pedir la eliminación de tu cuenta o de la información almacenada cuando'
              ' ya no sea necesaria.',
          'Limitar el tratamiento para determinados fines (por ejemplo, marketing).',
          'Solicitar la portabilidad de los datos que nos hayas proporcionado.',
        ]),
        const SizedBox(height: 20),
        _SectionTitle('Cómo ejercer tus derechos'),
        const SizedBox(height: 8),
        Text(
          'Envíanos tu solicitud a privacidad@geodos.es indicando el derecho que'
          ' quieres ejercer y una forma de contacto. Responderemos en un plazo'
          ' máximo de un mes, priorizando siempre la seguridad de tu información.',
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
                  'Medidas de protección',
                  style: t.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: Brand.primary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Aplicamos controles de acceso, cifrado en tránsito y revisiones de'
                  ' permisos internos para mantener tus datos seguros. Solo el'
                  ' personal autorizado puede acceder a la información estrictamente'
                  ' necesaria para prestar el servicio.',
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
