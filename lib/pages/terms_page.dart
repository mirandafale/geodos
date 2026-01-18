import 'package:flutter/material.dart';
import 'package:geodos/theme/brand.dart';
import 'package:geodos/widgets/app_shell.dart';

class TermsPage extends StatelessWidget {
  const TermsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;

    return AppShell(
      title: const Text('Términos y Condiciones'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Términos y condiciones de uso', style: t.headlineSmall),
            const SizedBox(height: 16),
            Text(
              'El acceso y uso de esta web implica la aceptación de las presentes '
              'condiciones de uso. El contenido del sitio tiene carácter informativo '
              'y puede ser modificado sin previo aviso.',
              style: t.bodyMedium,
            ),
            const SizedBox(height: 24),
            const _SectionTitle('Uso responsable'),
            const SizedBox(height: 8),
            _BulletList(
              items: [
                'No utilizar el contenido con fines ilícitos o que puedan dañar a terceros.',
                'Respetar los derechos de propiedad intelectual de GEODOS y sus colaboradores.',
                'No introducir virus ni realizar acciones que comprometan la seguridad.',
              ],
            ),
            const SizedBox(height: 24),
            const _SectionTitle('Limitación de responsabilidad'),
            const SizedBox(height: 8),
            Text(
              'GEODOS no se hace responsable de las decisiones que se tomen a partir '
              'de la información publicada ni de los daños que puedan derivarse del '
              'uso de esta página web.',
              style: t.bodyMedium,
            ),
            const SizedBox(height: 24),
            const _SectionTitle('Actualizaciones'),
            const SizedBox(height: 8),
            Text(
              'Nos reservamos el derecho a actualizar estos términos para reflejar '
              'mejoras en los servicios y en la normativa aplicable. Recomendamos '
              'revisarlos periódicamente.',
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
