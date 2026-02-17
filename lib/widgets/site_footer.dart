import 'package:flutter/material.dart';

class SiteFooter extends StatelessWidget {
  const SiteFooter({super.key});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Container(
      width: double.infinity,
      color: const Color(0xFF0B1F26),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 820;
              return Flex(
                direction: compact ? Axis.vertical : Axis.horizontal,
                crossAxisAlignment: compact ? CrossAxisAlignment.start : CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'GEODOS',
                        style: t.titleMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Consultoría ambiental, territorial y SIG',
                        style: t.bodySmall?.copyWith(color: Colors.white70),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '© ${DateTime.now().year} GEODOS · Todos los derechos reservados',
                        style: t.bodySmall?.copyWith(color: Colors.white70),
                      ),
                    ],
                  ),
                  SizedBox(height: compact ? 16 : 0, width: compact ? 0 : 24),
                  Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    children: const [
                      _FooterLink(label: 'Accesibilidad', route: '/accessibility'),
                      _FooterLink(label: 'Política de cookies', route: '/cookies'),
                      _FooterLink(label: 'Política de privacidad', route: '/privacy'),
                      _FooterLink(label: 'Configuración de privacidad', route: '/data-privacy'),
                      _FooterLink(label: 'Aviso legal', route: '/terms'),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _FooterLink extends StatelessWidget {
  final String label;
  final String route;

  const _FooterLink({required this.label, required this.route});

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: () => Navigator.pushNamed(context, route),
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        foregroundColor: Colors.white,
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.white,
              decoration: TextDecoration.underline,
            ),
      ),
    );
  }
}
