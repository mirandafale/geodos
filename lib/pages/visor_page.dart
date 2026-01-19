// visor_page.dart con visor de proyectos y formulario de contacto

import 'package:flutter/material.dart';
import 'package:geodos/brand/brand.dart';
import 'package:geodos/widgets/contact_form.dart';
import 'package:geodos/widgets/visor_embed.dart';
import 'package:geodos/widgets/app_shell.dart';

class VisorPage extends StatelessWidget {
  const VisorPage({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return AppShell(
      title: const Text('Visor de proyectos'),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          final navigator = Navigator.of(context);
          if (navigator.canPop()) {
            navigator.maybePop();
          } else {
            navigator.pushNamed('/');
          }
        },
        icon: const Icon(Icons.arrow_back),
        label: const Text('Volver'),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      body: Container(
        color: Brand.mist,
        padding: const EdgeInsets.all(16),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1400),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _VisorHeader(textTheme: textTheme),
                const SizedBox(height: 16),
                const Expanded(
                  child: Padding(
                    padding: EdgeInsets.all(12.0),
                    child: VisorEmbed(startExpanded: true),
                  ),
                ),
                const SizedBox(height: 16),
                ContactForm(
                  originSection: 'visor',
                  showCompanyField: false,
                  showProjectTypeField: true,
                  projectTypeLabel: 'Tipo de proyecto (opcional)',
                  title: '¿Quieres que te contactemos?',
                  helperText:
                      'Tus datos se almacenan de forma segura en Firebase al enviar el formulario.',
                  successMessage: 'Mensaje enviado correctamente',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _VisorHeader extends StatelessWidget {
  final TextTheme textTheme;

  const _VisorHeader({
    required this.textTheme,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 14,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: Brand.primary.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Padding(
                padding: EdgeInsets.all(10),
                child: Icon(
                  Icons.public,
                  color: Brand.primary,
                  size: 22,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'GEODOS – Consultoría ambiental y SIG',
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: Brand.primary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Visor de proyectos',
                    style: textTheme.bodySmall?.copyWith(
                      color: Brand.secondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
