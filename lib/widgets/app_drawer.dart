import 'package:flutter/material.dart';
import '../theme.dart';

// Nota: se eliminan los filtros y el formulario de contacto del drawer.

class AppDrawer extends StatefulWidget {
  const AppDrawer({super.key});

  @override
  State<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends State<AppDrawer> {

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
            _item(context, Icons.home_rounded, 'Inicio', '/'),
            _item(context, Icons.badge_rounded, 'Quiénes somos', '/about'),
            _item(context, Icons.map_rounded, 'Visor', '/visor'),
            _item(context, Icons.mail_rounded, 'Contacto', '/contact'),
            const Divider(height: 24),
            // Enlace al panel de administración
            _item(
              context,
              Icons.admin_panel_settings_rounded,
              'Login admin',
              '/admin',
            ),
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
          Navigator.of(ctx).pushReplacementNamed(route);
        }
      },
    );
  }
}

// Clase _Labeled eliminada porque los filtros ya no se muestran en el drawer.
