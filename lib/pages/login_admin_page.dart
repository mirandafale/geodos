import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../widgets/app_drawer.dart';
import '../services/auth_service.dart';

class LoginAdminPage extends StatefulWidget {
  const LoginAdminPage({super.key});

  @override
  State<LoginAdminPage> createState() => _LoginAdminPageState();
}

class _LoginAdminPageState extends State<LoginAdminPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await AuthService.instance
          .signIn(_emailCtrl.text, _passwordCtrl.text);

      if (!mounted) return;

      final isAdmin = AuthService.instance.isAdmin;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isAdmin
              ? 'Sesión iniciada como administrador.'
              : 'Sesión iniciada, pero este usuario no es admin.'),
        ),
      );

      // Volvemos a la home o a donde prefieras
      Navigator.pushReplacementNamed(context, '/home');
    } on FirebaseAuthException catch (e) {
      String msg = 'No se ha podido iniciar sesión.';
      if (e.code == 'user-not-found') {
        msg = 'No existe ningún usuario con ese correo.';
      } else if (e.code == 'wrong-password') {
        msg = 'Contraseña incorrecta.';
      } else if (e.code == 'invalid-email') {
        msg = 'Correo no válido.';
      }

      setState(() {
        _error = msg;
      });
    } catch (_) {
      setState(() {
        _error = 'Error inesperado al iniciar sesión.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<void> _logout() async {
    await AuthService.instance.signOut();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Sesión cerrada.')),
    );
    setState(() {}); // refresca el estado
  }

  @override
  Widget build(BuildContext context) {
    final auth = AuthService.instance;
    final theme = Theme.of(context);
    final t = theme.textTheme;

    final isLoggedIn = auth.isLoggedIn;
    final isAdmin = auth.isAdmin;
    final userEmail = auth.user?.email ?? '';

    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Colors.white),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFF0C6372),
                Color(0xFF2A7F62),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: Text(
          'GEODOS · Acceso administrador',
          style: t.titleLarge?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Card(
            elevation: 4,
            margin: const EdgeInsets.all(24),
            shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: isLoggedIn
                  ? _buildLoggedIn(context, isAdmin, userEmail)
                  : _buildForm(context),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildForm(BuildContext context) {
    final t = Theme.of(context).textTheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Iniciar sesión',
          style: t.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        const Text(
          'Introduce tus credenciales de administrador para acceder a la gestión de proyectos y noticias.',
        ),
        const SizedBox(height: 24),
        if (_error != null) ...[
          Text(
            _error!,
            style: TextStyle(color: Colors.red.shade700),
          ),
          const SizedBox(height: 16),
        ],
        Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _emailCtrl,
                decoration: const InputDecoration(
                  labelText: 'Correo electrónico',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Introduce tu correo.';
                  }
                  if (!v.contains('@')) {
                    return 'Correo no válido.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordCtrl,
                decoration: const InputDecoration(
                  labelText: 'Contraseña',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
                validator: (v) {
                  if (v == null || v.isEmpty) {
                    return 'Introduce tu contraseña.';
                  }
                  if (v.length < 6) {
                    return 'La contraseña debe tener al menos 6 caracteres.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _loading ? null : _submit,
                  child: _loading
                      ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                      : const Text('Entrar'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLoggedIn(
      BuildContext context, bool isAdmin, String userEmail) {
    final t = Theme.of(context).textTheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Sesión iniciada',
          style: t.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        Text('Usuario: $userEmail'),
        const SizedBox(height: 8),
        Row(
          children: [
            Icon(
              isAdmin ? Icons.verified_user : Icons.lock_outline,
              color: isAdmin ? Colors.green : Colors.orange,
            ),
            const SizedBox(width: 8),
            Text(
              isAdmin
                  ? 'Rol: Administrador'
                  : 'Rol: Usuario sin permisos de administración',
              style: t.bodyMedium,
            ),
          ],
        ),
        const SizedBox(height: 24),
        if (isAdmin)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'A partir de aquí, podrás:',
                style: t.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              const Text('• Añadir nuevos proyectos.'),
              const Text('• Añadir o actualizar descripciones de proyectos.'),
              const Text('• Crear y editar noticias del blog.'),
              const SizedBox(height: 16),
              Text(
                'En los siguientes pasos conectaremos estos permisos con la pantalla del visor y la sección de blog para mostrar los botones de edición sólo a administradores.',
                style: t.bodySmall?.copyWith(color: Colors.grey.shade700),
              ),
              const SizedBox(height: 16),
            ],
          ),
        Row(
          children: [
            FilledButton(
              onPressed: () => Navigator.pushReplacementNamed(context, '/home'),
              child: const Text('Volver a inicio'),
            ),
            const SizedBox(width: 12),
            TextButton(
              onPressed: _logout,
              child: const Text('Cerrar sesión'),
            ),
          ],
        ),
      ],
    );
  }
}
