import 'package:flutter/material.dart';

class SiteFooter extends StatelessWidget {
  const SiteFooter({super.key});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final isMobile = MediaQuery.of(context).size.width < 900;

    return Container(
      color: const Color(0xFF0B1F26),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: isMobile
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '© ${DateTime.now().year} GEODOS · Consultoría ambiental y territorial',
                      style: t.bodySmall?.copyWith(color: Colors.white70),
                    ),
                    const SizedBox(height: 12),
                    const Wrap(
                      spacing: 12,
                      runSpacing: 8,
                      children: [
                        _FooterLink(label: 'Accesibilidad', route: '/accessibility'),
                        _FooterLink(label: 'Política de cookies', route: '/cookies'),
                        _FooterLink(label: 'Política de privacidad', route: '/privacy'),
                        _FooterLink(label: 'Configuración de privacidad', route: '/data-privacy'),
                        _FooterLink(label: 'Aviso legal', route: '/terms'),
                      ],
                    ),
                  ],
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        '© ${DateTime.now().year} GEODOS · Consultoría ambiental y territorial',
                        style: t.bodySmall?.copyWith(color: Colors.white70),
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Wrap(
                      spacing: 12,
                      runSpacing: 8,
                      children: [
                        _FooterLink(label: 'Accesibilidad', route: '/accessibility'),
                        _FooterLink(label: 'Política de cookies', route: '/cookies'),
                        _FooterLink(label: 'Política de privacidad', route: '/privacy'),
                        _FooterLink(label: 'Configuración de privacidad', route: '/data-privacy'),
                        _FooterLink(label: 'Aviso legal', route: '/terms'),
                      ],
                    ),
                  ],
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
