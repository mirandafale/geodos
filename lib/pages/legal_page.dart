import 'package:flutter/material.dart';
import 'package:geodos/brand/brand.dart';
import 'package:geodos/widgets/app_shell.dart';

class LegalPage extends StatelessWidget {
  const LegalPage({super.key});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;

    return AppShell(
      title: const Text('Aviso Legal'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Aviso Legal', style: t.headlineSmall),
                const SizedBox(height: 16),
                Text(
                  'En cumplimiento de la Ley 34/2002, de Servicios de la Sociedad '
                  'de la Información y del Comercio Electrónico (LSSI-CE), se '
                  'facilita la siguiente información legal:',
                  style: t.bodyMedium,
                ),
                const SizedBox(height: 24),
                const _SectionTitle('Titularidad'),
                const SizedBox(height: 8),
                _BulletList(
                  items: [
                    'Titular: GEODOS Consultoría Ambiental y SIG.',
                    'CIF: B-00000000.',
                    'Domicilio social: Canarias, España.',
                    'Contacto: info@geodos.es.',
                  ],
                ),
                const SizedBox(height: 24),
                const _SectionTitle('Propiedad intelectual'),
                const SizedBox(height: 8),
                Text(
                  'Los contenidos, diseños, textos, imágenes, logotipos, software y '
                  'cualquier otro elemento de esta web son propiedad de GEODOS o '
                  'de terceros licenciantes. Queda prohibida su reproducción total '
                  'o parcial sin autorización expresa.',
                  style: t.bodyMedium,
                ),
                const SizedBox(height: 24),
                const _SectionTitle('Condiciones de uso'),
                const SizedBox(height: 8),
                Text(
                  'El acceso y uso de este sitio implica la aceptación de las '
                  'condiciones aquí descritas. GEODOS se reserva el derecho de '
                  'modificar los contenidos y las condiciones legales cuando lo '
                  'considere oportuno.',
                  style: t.bodyMedium,
                ),
                const SizedBox(height: 24),
                const _SectionTitle('Responsabilidad'),
                const SizedBox(height: 8),
                Text(
                  'GEODOS no se hace responsable de posibles daños derivados de '
                  'interrupciones del servicio, errores técnicos o enlaces externos '
                  'a terceros. El usuario se compromete a utilizar la web de forma '
                  'diligente y respetuosa.',
                  style: t.bodyMedium,
                ),
              ],
            ),
          ),
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
