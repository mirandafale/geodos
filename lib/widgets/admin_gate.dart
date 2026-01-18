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
        if (!auth.isLoggedIn) {
          return const LoginAdminPage();
        }

        if (!auth.isAdmin) {
          return const Scaffold(
            body: Center(
              child: Text('Acceso denegado'),
            ),
          );
        }

        return child;
      },
    );
  }
}
