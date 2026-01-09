import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// Servicio global de autenticación.
/// Envuelve FirebaseAuth y expone un estado sencillo (usuario + esAdmin).
class AuthService extends ChangeNotifier {
  AuthService._internal() {
    _initialize();
  }

  /// Instancia singleton
  static final AuthService instance = AuthService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  User? _user;

  User? get user => _user;
  bool get isLoggedIn => _user != null;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Lista de correos que consideramos "admins".
  /// ⚠️ Cambia estos por los vuestros reales.
  static const Set<String> adminEmails = {
    'admin@geodos.es',
    'geodos.admin@gmail.com',
  };

  bool get isAdmin {
    final email = _user?.email?.toLowerCase();
    if (email == null) return false;
    return adminEmails.contains(email);
  }

  Future<void> signIn({required String email, required String password}) async {
    await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password.trim(),
    );
    _user = _auth.currentUser;
    notifyListeners();
    // authStateChanges ya actualizará _user y notificará.
  }

  Future<void> signInWithGoogle() async {
    final provider = GoogleAuthProvider();
    if (kIsWeb) {
      await _auth.signInWithPopup(provider);
    } else {
      await _auth.signInWithProvider(provider);
    }
    _user = _auth.currentUser;
    notifyListeners();
  }

  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email.trim());
  }

  Future<void> signOut() async {
    await _auth.signOut();
    _user = null;
    notifyListeners();
    // authStateChanges deja _user a null y notifica.
  }

  void _initialize() {
    if (kIsWeb) {
      _auth.setPersistence(Persistence.LOCAL);
    }
    _user = _auth.currentUser;
    // Escuchamos cambios de sesión (login / logout / expiración de token...)
    _auth.authStateChanges().listen((user) {
      _user = user;
      notifyListeners();
    });
  }
}
