import 'package:flutter/material.dart';
import 'package:geodos/widgets/app_shell.dart';

class CookiesPolicyPage extends StatelessWidget {
  const CookiesPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;

    return AppShell(
      title: const Text('Política de cookies'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Política de cookies', style: t.headlineSmall),
            const SizedBox(height: 16),
            Text(
              'Este sitio puede utilizar cookies técnicas y analíticas para '
              'mejorar la experiencia de usuario y obtener estadísticas de uso.',
              style: t.bodyMedium,
            ),
            const SizedBox(height: 16),
            Text(
              'El usuario puede configurar su navegador para bloquear o eliminar '
              'las cookies. Algunas funcionalidades del sitio podrían verse afectadas '
              'si las cookies están deshabilitadas.',
              style: t.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
