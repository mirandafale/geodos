import 'package:flutter/material.dart';
import 'package:geodos/services/auth_service.dart';
import 'package:provider/provider.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();

    return Drawer(
      child: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF0C6372), Color(0xFF2A7F62)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Align(
                alignment: Alignment.bottomLeft,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'GEODOS',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    if (auth.isLoggedIn) ...[
                      const SizedBox(height: 4),
                      Text(
                        auth.user?.email ?? '',
                        style: Theme.of(context)
                            .textTheme
                            .labelMedium
                            ?.copyWith(color: Colors.white70),
                      ),
                    ]
                  ],
                ),
              ),
            ),
            _item(context, Icons.home_rounded, 'Inicio', '/'),
            _item(context, Icons.map_rounded, 'Visor', '/visor'),
            _item(context, Icons.article_outlined, 'Blog / Actualidad', '/home'),
            _item(context, Icons.mail_rounded, 'Contacto', '/contact'),
            _item(context, Icons.login_rounded, 'Acceso admin', '/login-admin'),
            if (auth.isLoggedIn && auth.isAdmin) ...[
              _item(
                context,
                Icons.admin_panel_settings_rounded,
                'Panel admin',
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
            ],
            const Divider(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
              child: Text('Legal', style: Theme.of(context).textTheme.labelLarge),
            ),
            _item(context, Icons.privacy_tip_outlined, 'Privacidad', '/privacy'),
            _item(context, Icons.cookie_outlined, 'Cookies', '/cookies'),
            _item(context, Icons.security_outlined, 'Ajustes de datos', '/data-privacy'),
            _item(context, Icons.gavel_outlined, 'Términos de uso', '/terms'),
            _item(context, Icons.accessibility_new_outlined, 'Accesibilidad', '/accessibility'),
            const SizedBox(height: 16),
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
      leading: Icon(icon),
      title: Text(title),
      onTap: () {
        Navigator.of(ctx).pop();
        if (ModalRoute.of(ctx)?.settings.name != route) {
          Navigator.of(ctx).pushNamed(route);
        }
      },
    );
  }
}
