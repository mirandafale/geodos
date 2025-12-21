import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// Servicio global de autenticación.
/// Envuelve FirebaseAuth y expone un estado sencillo (usuario + esAdmin).
class AuthService extends ChangeNotifier {
  AuthService._() {
    _user = _auth.currentUser;
    _auth.authStateChanges().listen((user) {
      _user = user;
      notifyListeners();
    });
  }

  /// Instancia singleton
  static final AuthService instance = AuthService._();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  User? _user;

  User? get user => _user;
  Stream<User?> get authStateChanges => _auth.authStateChanges();
  bool get isLoggedIn => _user != null;

  /// Lista de correos que consideramos "admins".
  /// ⚠️ Cambia estos por los vuestros reales.
  static const Set<String> _adminEmails = {
    'admin@geodos.es',
    'geodos.admin@gmail.com',
  };

  bool get isAdmin {
    final email = _user?.email?.toLowerCase();
    if (email == null) return false;
    return _adminEmails.contains(email);
  }

  Future<void> signIn(String email, String password) async {
    await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password.trim(),
    );
    // authStateChanges ya actualizará _user y notificará.
  }

  Future<void> signOut() async {
    await _auth.signOut();
    // authStateChanges deja _user a null y notifica.
  }
}
