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
              'Esta página describe cómo GEODOS trata los datos personales que se '
              'recogen a través de los formularios de contacto y del uso de la web.',
              style: t.bodyMedium,
            ),
            const SizedBox(height: 24),
            const _SectionTitle('Datos recogidos'),
            const SizedBox(height: 8),
            _BulletList(
              items: [
                'Información de contacto (nombre, correo electrónico y empresa).',
                'Mensaje o consulta enviada por el usuario.',
                'Datos necesarios para dar seguimiento a solicitudes o proyectos.',
              ],
            ),
            const SizedBox(height: 24),
            const _SectionTitle('Finalidad del tratamiento'),
            const SizedBox(height: 8),
            Text(
              'La información facilitada se utiliza exclusivamente para gestionar '
              'consultas, solicitudes de información y la relación profesional con '
              'nuestros clientes.',
              style: t.bodyMedium,
            ),
            const SizedBox(height: 24),
            const _SectionTitle('Derechos de las personas usuarias'),
            const SizedBox(height: 8),
            Text(
              'GEODOS cumple con la normativa vigente en materia de protección de '
              'datos personales. Los usuarios pueden ejercer sus derechos de acceso, '
              'rectificación, supresión y otros derechos reconocidos por la ley '
              'dirigiéndose a la dirección de contacto indicada en esta web.',
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
