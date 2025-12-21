import 'package:flutter/material.dart';
import 'package:geodos/widgets/app_shell.dart';

class TermsConditionsPage extends StatelessWidget {
  const TermsConditionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppShell(
      title: Text('Términos y Condiciones'),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(24),
        child: _TermsContent(),
      ),
    );
  }
}

class _TermsContent extends StatelessWidget {
  const _TermsContent();

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Términos y Condiciones de uso', style: t.headlineSmall),
        const SizedBox(height: 16),
        Text(
          'El acceso y uso de esta web implica la aceptación de las presentes '
              'condiciones de uso. El contenido del sitio tiene carácter informativo '
              'y puede ser modificado sin previo aviso.',
          style: t.bodyMedium,
        ),
        const SizedBox(height: 16),
        Text(
          'GEODOS no se hace responsable de las decisiones que se tomen a partir '
              'de la información publicada ni de los daños que puedan derivarse del '
              'uso de esta página web.',
          style: t.bodyMedium,
        ),
      ],
    );
  }
}
