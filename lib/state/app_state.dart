// lib/pages/login_page.dart

import 'package:flutter/material.dart';
import 'package:geodos/state/app_state.dart';
import 'package:provider/provider.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _user = TextEditingController();
  final _pass = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _user.dispose();
    _pass.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    final ok = await context.read<AppState>().signIn(
      email: _user.text,
      password: _pass.text,
    );
    setState(() => _isLoading = false);

    if (!mounted) return;

    if (ok) {
      Navigator.of(context).pop();
    } else {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Error de autenticación'),
          content: const Text('Usuario o contraseña incorrectos.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Aceptar'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Iniciar sesión')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _user,
                  decoration: const InputDecoration(labelText: 'Correo electrónico'),
                  validator: (v) => v != null && v.contains('@') ? null : 'Correo no válido',
                ),
                TextFormField(
                  controller: _pass,
                  decoration: const InputDecoration(labelText: 'Contraseña'),
                  obscureText: true,
                  validator: (v) => v != null && v.length >= 4 ? null : 'Contraseña demasiado corta',
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  child: _isLoading ? const CircularProgressIndicator() : const Text('Entrar'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
