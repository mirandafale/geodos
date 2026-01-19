import 'package:flutter/material.dart';
import 'package:geodos/theme/brand.dart';
import 'package:geodos/widgets/app_shell.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;

    return AppShell(
      title: const Text('Política de Privacidad'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Política de Privacidad', style: t.headlineSmall),
            const SizedBox(height: 16),
            Text(
              'Esta política describe cómo GEODOS trata los datos personales de '
              'acuerdo con el Reglamento (UE) 2016/679 (RGPD) y la normativa '
              'española vigente en materia de protección de datos.',
              style: t.bodyMedium,
            ),
            const SizedBox(height: 24),
            const _SectionTitle('Responsable del tratamiento'),
            const SizedBox(height: 8),
            Text(
              'GEODOS Consultoría Ambiental y SIG es el responsable del tratamiento '
              'de los datos personales recogidos en esta web. Para cualquier '
              'consulta, puedes contactar en info@geodos.es.',
              style: t.bodyMedium,
            ),
            const SizedBox(height: 24),
            const _SectionTitle('Datos recogidos'),
            const SizedBox(height: 8),
            _BulletList(
              items: [
                'Información de contacto (nombre, correo electrónico y empresa).',
                'Mensaje o consulta enviada por el usuario.',
                'Datos técnicos de navegación necesarios para el funcionamiento del sitio.',
              ],
            ),
            const SizedBox(height: 24),
            const _SectionTitle('Finalidad del tratamiento'),
            const SizedBox(height: 8),
            Text(
              'La información facilitada se utiliza para gestionar consultas, '
              'solicitudes de información, presupuestos y la relación profesional '
              'con clientes y colaboradores.',
              style: t.bodyMedium,
            ),
            const SizedBox(height: 24),
            const _SectionTitle('Base jurídica'),
            const SizedBox(height: 8),
            Text(
              'La base legal del tratamiento es el consentimiento de la persona '
              'interesada y, en su caso, la ejecución de medidas precontractuales '
              'o contractuales solicitadas.',
              style: t.bodyMedium,
            ),
            const SizedBox(height: 24),
            const _SectionTitle('Conservación de los datos'),
            const SizedBox(height: 8),
            Text(
              'Los datos se conservarán durante el tiempo necesario para atender '
              'la solicitud o mientras exista una relación profesional, y se '
              'bloquearán posteriormente durante los plazos legales aplicables.',
              style: t.bodyMedium,
            ),
            const SizedBox(height: 24),
            const _SectionTitle('Destinatarios'),
            const SizedBox(height: 8),
            Text(
              'No se cederán datos a terceros salvo obligación legal. Los proveedores '
              'tecnológicos que prestan servicios a GEODOS actúan como encargados '
              'del tratamiento bajo contratos de confidencialidad.',
              style: t.bodyMedium,
            ),
            const SizedBox(height: 24),
            const _SectionTitle('Derechos de las personas usuarias'),
            const SizedBox(height: 8),
            Text(
              'Puedes ejercer los derechos de acceso, rectificación, supresión, '
              'oposición, limitación, portabilidad y retirada del consentimiento '
              'escribiendo a info@geodos.es. También tienes derecho a presentar una '
              'reclamación ante la Agencia Española de Protección de Datos (AEPD).',
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
