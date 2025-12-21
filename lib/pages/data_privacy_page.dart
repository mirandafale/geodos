import 'package:flutter/material.dart';
import 'package:geodos/widgets/app_shell.dart';

class DataPrivacySettingsPage extends StatelessWidget {
  const DataPrivacySettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppShell(
      title: 'Configuración de Privacidad de Datos',
      body: SingleChildScrollView(
        padding: EdgeInsets.all(24),
        child: _DataPrivacyContent(),
      ),
    );
  }
}

class _DataPrivacyContent extends StatelessWidget {
  const _DataPrivacyContent();

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Configuración de Privacidad de Datos', style: t.headlineSmall),
        const SizedBox(height: 16),
        Text(
          'En esta sección se informará al usuario sobre las opciones de '
              'configuración relativas al tratamiento de sus datos personales, '
              'incluyendo la posibilidad de revocar consentimientos o actualizar '
              'preferencias de comunicación.',
          style: t.bodyMedium,
        ),
        const SizedBox(height: 16),
        Text(
          'Para solicitar cualquier cambio en la configuración de privacidad, '
              'el usuario puede ponerse en contacto con GEODOS a través del formulario '
              'de contacto o de la dirección de correo indicada en la web.',
          style: t.bodyMedium,
        ),
      ],
    );
  }
}
