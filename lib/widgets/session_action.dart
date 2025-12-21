// lib/widgets/session_action.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../services/auth_service.dart';

class SessionAction {
  static Future<void> signIn({
    required String email,
    required String password,
  }) async {
    await AuthService.instance.signIn(email, password);
  }

  static Future<void> signOut() async {
    await AuthService.instance.signOut();
  }
}

class SessionActionWidget extends StatelessWidget {
  const SessionActionWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return IconButton(
      icon: const Icon(Icons.logout),
      onPressed: user == null
          ? null
          : () async {
              await SessionAction.signOut();
              if (context.mounted) Navigator.of(context).pop();
            },
    );
  }
}
