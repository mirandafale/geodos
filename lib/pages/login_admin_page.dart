import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:geodos/brand/brand.dart';
import 'package:geodos/widgets/app_shell.dart';
import '../services/auth_service.dart';

class LoginAdminPage extends StatefulWidget {
  const LoginAdminPage({super.key, this.redirectTo = '/home'});

  final String redirectTo;

  @override
  State<LoginAdminPage> createState() => _LoginAdminPageState();
}

class _LoginAdminPageState extends State<LoginAdminPage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _loading = false;
  bool _loadingGoogle = false;
  bool _primaryPressed = false;
  String? _error;
  late final AnimationController _introController;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _introController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _introController,
      curve: Curves.easeOutCubic,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _introController,
        curve: Curves.easeOutCubic,
      ),
    );
    _introController.forward();
  }

  @override
  void dispose() {
    _introController.dispose();
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
      await context.read<AuthService>().signIn(
            email: _emailCtrl.text,
            password: _passwordCtrl.text,
          );

      if (!mounted) return;

      final isAdmin = context.read<AuthService>().isAdmin;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isAdmin
              ? 'Sesión iniciada como administrador.'
              : 'Sesión iniciada, pero este usuario no es admin.'),
        ),
      );

      Navigator.pushReplacementNamed(context, widget.redirectTo);
    } on FirebaseAuthException catch (e) {
      setState(() {
        _error = _friendlyAuthError(e.code);
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

  Future<void> _signInWithGoogle() async {
    setState(() {
      _loadingGoogle = true;
      _error = null;
    });

    try {
      await context.read<AuthService>().signInWithGoogle();
      if (!mounted) return;
      final isAdmin = context.read<AuthService>().isAdmin;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isAdmin
              ? 'Sesión iniciada con Google.'
              : 'Sesión iniciada con Google, pero este usuario no es admin.'),
        ),
      );
      Navigator.pushReplacementNamed(context, widget.redirectTo);
    } on FirebaseAuthException catch (e) {
      setState(() {
        _error = _friendlyAuthError(e.code);
      });
    } catch (_) {
      setState(() {
        _error = 'Error inesperado al iniciar sesión con Google.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _loadingGoogle = false;
        });
      }
    }
  }

  Future<void> _openPasswordResetDialog() async {
    final controller = TextEditingController(text: _emailCtrl.text.trim());
    final email = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Restablecer contraseña'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Introduce tu correo y te enviaremos un enlace para restablecer la contraseña.',
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Correo electrónico',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, controller.text.trim()),
              child: const Text('Enviar enlace'),
            ),
          ],
        );
      },
    );

    if (email == null || email.isEmpty) {
      return;
    }

    try {
      await context.read<AuthService>().sendPasswordResetEmail(email);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enlace de recuperación enviado.')),
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_friendlyAuthError(e.code))),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo enviar el correo de recuperación.')),
      );
    }
  }

  String _friendlyAuthError(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No existe ningún usuario con ese correo.';
      case 'wrong-password':
        return 'Contraseña incorrecta.';
      case 'invalid-email':
        return 'Correo no válido.';
      case 'popup-closed-by-user':
        return 'Se cerró la ventana de inicio de sesión.';
      case 'account-exists-with-different-credential':
        return 'Ya existe una cuenta con otro método de acceso.';
      case 'too-many-requests':
        return 'Demasiados intentos. Intenta más tarde.';
      default:
        return 'No se ha podido iniciar sesión.';
    }
  }

  Future<void> _logout() async {
    await context.read<AuthService>().signOut();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Sesión cerrada.')),
    );
    setState(() {}); // refresca el estado
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final theme = Theme.of(context);
    final t = theme.textTheme;

    final isLoggedIn = auth.isLoggedIn;
    final isAdmin = auth.isAdmin;
    final userEmail = auth.user?.email ?? '';

    return AppShell(
      title: Text(
        'GEODOS · Acceso administrador',
        style: t.titleLarge?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final horizontalPadding = width < 600 ? 20.0 : 32.0;
          final maxWidth = width < 700
              ? width
              : width < 1100
                  ? 520.0
                  : 640.0;

          return Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Brand.mist.withOpacity(0.85),
                  const Color(0xFFF2F6F5),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: horizontalPadding,
                  vertical: 40,
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: maxWidth),
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: Card(
                        elevation: 8,
                        shadowColor: Brand.primary.withOpacity(0.18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: width < 600 ? 22 : 32,
                            vertical: width < 600 ? 26 : 36,
                          ),
                          child: isLoggedIn
                              ? _buildLoggedIn(context, isAdmin, userEmail)
                              : _buildForm(context),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildForm(BuildContext context) {
    final t = Theme.of(context).textTheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Brand.primary, Brand.secondary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child:
                  const Icon(Icons.admin_panel_settings, color: Colors.white, size: 28),
            ),
            const SizedBox(width: 12),
            Text(
              'Acceso GEODOS',
              style: t.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: Brand.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
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
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.red.shade100),
            ),
            child: Row(
              children: [
                Icon(Icons.error_outline, color: Colors.red.shade700),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _error!,
                    style: TextStyle(color: Colors.red.shade700),
                  ),
                ),
              ],
            ),
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
                autofillHints: const [AutofillHints.email],
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
                autofillHints: const [AutofillHints.password],
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
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _loading ? null : _openPasswordResetDialog,
                  child: const Text('¿Has olvidado tu contraseña?'),
                ),
              ),
              const SizedBox(height: 24),
              GestureDetector(
                onTapDown: (_) => setState(() => _primaryPressed = true),
                onTapUp: (_) => setState(() => _primaryPressed = false),
                onTapCancel: () => setState(() => _primaryPressed = false),
                child: AnimatedScale(
                  scale: _primaryPressed ? 0.98 : 1.0,
                  duration: const Duration(milliseconds: 140),
                  curve: Curves.easeOut,
                  child: SizedBox(
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
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: Divider(color: Colors.grey.shade300)),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Text('o'),
                  ),
                  Expanded(child: Divider(color: Colors.grey.shade300)),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _loadingGoogle ? null : _signInWithGoogle,
                  icon: _loadingGoogle
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.g_mobiledata),
                  label: const Text('Continuar con Google'),
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
              onPressed: () => Navigator.pushReplacementNamed(context, '/'),
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
