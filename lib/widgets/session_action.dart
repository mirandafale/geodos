// lib/widgets/session_action.dart

import 'package:flutter/material.dart';

class SessionAction {
  static Future<void> signIn({
    required String email,
    required String password,
  }) async {
    // Aquí deberías conectar con tu servicio de autenticación real
    await Future.delayed(const Duration(milliseconds: 500));
    debugPrint('Sign in as: \$email');
  }

  static Future<void> signOut() async {
    // Aquí deberías limpiar el estado de autenticación o tokens
    await Future.delayed(const Duration(milliseconds: 500));
    debugPrint('Signed out');
  }
}

class SessionActionWidget extends StatelessWidget {
  const SessionActionWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.logout),
      onPressed: () async {
        await SessionAction.signOut();
        if (context.mounted) Navigator.of(context).pop();
      },
    );
  }
}
