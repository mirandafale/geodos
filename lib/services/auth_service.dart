import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// Servicio global de autenticación.
/// Envuelve FirebaseAuth y expone un estado sencillo (usuario + esAdmin).
class AuthService extends ChangeNotifier {
  AuthService._() {
    _user = _auth.currentUser;
    _authSubscription = _auth.authStateChanges().listen((user) {
      _user = user;
      notifyListeners();
    });
  }

  /// Instancia singleton
  static final AuthService instance = AuthService._();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  late final StreamSubscription<User?> _authSubscription;
  User? _user;

  User? get user => _user;
  Stream<User?> get authStateChanges => _auth.authStateChanges();
  bool get isLoggedIn => _user != null;
  bool get isAdmin => isLoggedIn;

  Future<void> signIn(String email, String password) async {
    await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password.trim(),
    );
    // authStateChanges ya actualizará _user y notificará.
  }

  Future<void> signInWithCredentials({
    required String email,
    required String password,
  }) async {
    await signIn(email, password);
  }

  Future<void> signOut() async {
    await _auth.signOut();
    // authStateChanges deja _user a null y notifica.
  }

  @override
  void dispose() {
    _authSubscription.cancel();
    super.dispose();
  }
}
