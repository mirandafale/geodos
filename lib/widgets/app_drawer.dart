import 'package:flutter/material.dart';
import '../theme.dart';

// Nota: se eliminan los filtros y el formulario de contacto del drawer.

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key, required this.onAdminAccess});

  final VoidCallback onAdminAccess;

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: AppTheme.gradientHeader(),
              child: Align(
                alignment: Alignment.bottomLeft,
                child: Text(
                  'GEODOS',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
            ),
            // Navegación principal reducida
            _item(context, Icons.home_rounded, 'Inicio', '/home'),
            _item(context, Icons.badge_rounded, 'Quiénes somos', '/quienes'),
            _item(context, Icons.map_rounded, 'Visor', '/visor'),
            _item(context, Icons.mail_rounded, 'Contacto', '/contact'),
            const Divider(height: 24),
            // Enlace al panel de administración
            _item(
              context,
              Icons.admin_panel_settings_rounded,
              'Login admin',
              onTap: onAdminAccess,
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  ListTile _item(
    BuildContext context,
    IconData icon,
    String title, [
    String? route,
    VoidCallback? onTap,
  ]) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      onTap: () {
        Scaffold.of(context).closeDrawer();
        if (onTap != null) {
          onTap();
          return;
        }
        if (route != null && ModalRoute.of(context)?.settings.name != route) {
          Navigator.of(context).pushReplacementNamed(route);
        }
      },
    );
  }
}

// Clase _Labeled eliminada porque los filtros ya no se muestran en el drawer.
