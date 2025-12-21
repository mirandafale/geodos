import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../pages/login_admin_page.dart';
import '../services/auth_service.dart';

class AdminGate extends StatelessWidget {
  const AdminGate({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();

    if (!auth.isLoggedIn) {
      return const LoginAdminPage();
    }

    if (!auth.isAdmin) {
      return Scaffold(
        appBar: AppBar(title: const Text('Panel de administración')),
        body: const Center(
          child: Text('Acceso denegado'),
        ),
      );
    }

    return child;
  }
}
