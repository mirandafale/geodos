import 'package:flutter/material.dart';
import 'package:geodos/pages/login_admin_page.dart';
import 'package:geodos/services/auth_service.dart';
import 'package:provider/provider.dart';

class AdminGate extends StatelessWidget {
  const AdminGate({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthService>(
      builder: (context, auth, _) {
        if (auth.isLoggedIn && auth.isAdmin) {
          return child;
        }

        if (auth.isLoggedIn && !auth.isAdmin) {
          return Scaffold(
            appBar: AppBar(title: const Text('Acceso restringido')),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.lock_outline, size: 48),
                    const SizedBox(height: 12),
                    const Text(
                      'Tu cuenta no tiene permisos de administración.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: () => auth.signOut(),
                      child: const Text('Cerrar sesión'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        return const LoginAdminPage(redirectTo: '/admin');
      },
    );
  }
}
