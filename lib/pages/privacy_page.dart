import 'package:flutter/material.dart';
import '../widgets/app_drawer.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: const Text('Política de Privacidad'),
      ),
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(24),
        child: _PrivacyContent(),
      ),
    );
  }
}

class _PrivacyContent extends StatelessWidget {
  const _PrivacyContent();

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Política de Privacidad', style: t.headlineSmall),
        const SizedBox(height: 16),
        Text(
          'Esta página describe cómo GEODOS trata los datos personales que se '
              'recogen a través de los formularios de contacto y del uso de la web.',
          style: t.bodyMedium,
        ),
        const SizedBox(height: 16),
        Text(
          'La información que facilitan los usuarios se utiliza exclusivamente '
              'para gestionar las consultas, solicitudes de información y la '
              'relación profesional con nuestros clientes.',
          style: t.bodyMedium,
        ),
        const SizedBox(height: 16),
        Text(
          'GEODOS cumple con la normativa vigente en materia de protección de '
              'datos personales. Los usuarios pueden ejercer sus derechos de acceso, '
              'rectificación, supresión y otros derechos reconocidos por la ley '
              'dirigiéndose a la dirección de contacto indicada en esta web.',
          style: t.bodyMedium,
        ),
      ],
    );
  }
}
