import 'package:flutter/material.dart';

import '../brand/brand.dart';
import '../widgets/legal_scaffold.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;

    return LegalPageScaffold(
      title: 'Política de privacidad',
      children: [
        Text(
          'Esta política explica qué datos personales tratamos, para qué los'
          ' utilizamos y qué derechos puedes ejercer. Aplicamos medidas técnicas y'
          ' organizativas acordes a las mejores prácticas del sector.',
          style: t.bodyLarge,
        ),
        const SizedBox(height: 20),
        _SectionTitle('Datos que podemos tratar'),
        const SizedBox(height: 8),
        _BulletList(items: const [
          'Datos identificativos y de contacto facilitados en formularios (nombre,'
              ' correo, teléfono).',
          'Información sobre proyectos o solicitudes que nos remitas.',
          'Datos de navegación anonimizados para mejorar la calidad del servicio.',
        ]),
        const SizedBox(height: 20),
        _SectionTitle('Finalidades y legitimación'),
        const SizedBox(height: 8),
        _BulletList(items: const [
          'Responder consultas y enviar presupuestos a petición del usuario.',
          'Prestar los servicios contratados y mantener la relación profesional.',
          'Cumplir obligaciones legales y de seguridad de la información.',
          'Enviar comunicaciones informativas cuando tengamos tu consentimiento.',
        ]),
        const SizedBox(height: 20),
        _SectionTitle('Plazos de conservación'),
        const SizedBox(height: 8),
        Text(
          'Conservamos los datos solo durante el tiempo necesario para gestionar la'
          ' solicitud o prestar el servicio y para cumplir obligaciones legales.'
          ' Una vez finalizados esos plazos, los datos se bloquean y eliminan de'
          ' forma segura.',
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
                  'Ejercicio de derechos',
                  style: t.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: Brand.primary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Puedes solicitar el acceso, rectificación, supresión, oposición,'
                  ' limitación o portabilidad de tus datos escribiendo a'
                  ' privacidad@geodos.es. Indicaremos el estado de la petición y el'
                  ' plazo estimado de respuesta.',
                  style: t.bodyMedium,
                ),
                const SizedBox(height: 12),
                Text(
                  'Si consideras que no hemos atendido correctamente tu solicitud,'
                  ' puedes presentar una reclamación ante la autoridad de control'
                  ' competente.',
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
