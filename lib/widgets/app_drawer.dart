import 'package:flutter/material.dart';
import 'package:geodos/brand/brand.dart';
import 'package:geodos/pages/login_page.dart';
import 'package:geodos/services/auth_service.dart';
import 'package:provider/provider.dart';

class AppDrawer extends StatelessWidget {
  final VoidCallback onAdminAccess;

  const AppDrawer({
    super.key,
    required this.onAdminAccess,
  });

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final theme = Theme.of(context);
    final isAdmin = auth.isLoggedIn && auth.isAdmin;

    return Drawer(
      child: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(gradient: Brand.appBarGradient),
              child: Align(
                alignment: Alignment.bottomLeft,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.public, color: Colors.white, size: 30),
                        const SizedBox(width: 8),
                        Text(
                          'GEODOS',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Consultoría ambiental y territorial',
                      style: theme.textTheme.labelMedium?.copyWith(color: Colors.white70),
                    ),
                    if (auth.isLoggedIn) ...[
                      const SizedBox(height: 8),
                      _AdminStatusChip(
                        email: auth.user?.email ?? '',
                        isAdmin: isAdmin,
                      ),
                    ],
                  ],
                ),
              ),
            ),
            _SectionLabel(title: 'Navegación pública'),
            _item(context, Icons.home_rounded, 'Inicio', '/'),
            _item(context, Icons.map_rounded, 'Visor', '/visor'),
            _item(context, Icons.article_outlined, 'Blog / Actualidad', '/blog'),
            _item(context, Icons.mail_rounded, 'Contacto', '/contact'),
            if (!auth.isLoggedIn)
              ListTile(
                leading: const Icon(Icons.login_rounded, color: Brand.primary),
                title: Text(
                  'Acceso admin',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Brand.ink),
                ),
                onTap: () {
                  Navigator.of(context).pop();
                  onAdminAccess();
                },
              ),
            const Divider(height: 28),
            _SectionLabel(title: 'Sesión administrativa'),
            if (isAdmin) ...[
              _item(
                context,
                Icons.admin_panel_settings_rounded,
                'Panel de administración',
                '/admin',
              ),
              ListTile(
                leading: const Icon(Icons.logout),
                title: const Text('Cerrar sesión'),
                onTap: () async {
                  Navigator.of(context).pop();
                  await auth.signOut();
                },
              ),
            ] else
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Text(
                  'Accede con tus credenciales para administrar contenidos.',
                  style: theme.textTheme.bodySmall?.copyWith(color: Colors.black54),
                ),
              ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  ListTile _item(
    BuildContext ctx,
    IconData icon,
    String title,
    String route,
  ) {
    return ListTile(
      leading: Icon(icon, color: Brand.primary),
      title: Text(
        title,
        style: Theme.of(ctx).textTheme.bodyLarge?.copyWith(color: Brand.ink),
      ),
      onTap: () {
        Navigator.of(ctx).pop();
        if (ModalRoute.of(ctx)?.settings.name != route) {
          Navigator.of(ctx).pushNamed(route);
        }
      },
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Text(
        title.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Brand.primary,
              letterSpacing: 1.2,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}

class _AdminStatusChip extends StatelessWidget {
  const _AdminStatusChip({required this.email, required this.isAdmin});

  final String email;
  final bool isAdmin;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isAdmin ? Icons.admin_panel_settings_rounded : Icons.verified_user_outlined,
            color: Colors.white,
            size: 16,
          ),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isAdmin ? 'Modo admin' : 'Sesión activa',
                style: Theme.of(context)
                    .textTheme
                    .labelSmall
                    ?.copyWith(color: Colors.white, fontWeight: FontWeight.w600),
              ),
              Text(
                email,
                style:
                    Theme.of(context).textTheme.labelSmall?.copyWith(color: Colors.white70),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
