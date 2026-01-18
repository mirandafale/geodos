import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Servicio global de autenticación.
/// Envuelve FirebaseAuth y expone un estado sencillo (usuario + esAdmin).
class AuthService extends ChangeNotifier {
  AuthService._internal() {
    _bindAuthState();
  }

  static final AuthService instance = AuthService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  StreamSubscription<User?>? _authSubscription;
  User? _user;

  User? get user => _user;
  bool get isLoggedIn => _user != null;

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
  }

  Future<void> signInWithGoogle() async {
    if (kIsWeb) {
      final provider = GoogleAuthProvider();
      await _auth.signInWithPopup(provider);
    } else {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return;
      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      await _auth.signInWithCredential(credential);
    }
    _user = _auth.currentUser;
    notifyListeners();
  }

  Future<void> signOut() async {
    await _auth.signOut();
    await _googleSignIn.signOut();
    _user = null;
    notifyListeners();
  }

  void _bindAuthState() {
    if (kIsWeb) {
      _auth.setPersistence(Persistence.LOCAL);
    }
    _user = _auth.currentUser;
    _authSubscription?.cancel();
    _authSubscription = _auth.authStateChanges().listen(
      (user) {
        _user = user;
        notifyListeners();
      },
      onError: (error) {
        debugPrint('AuthService: authStateChanges error=$error');
      },
    );
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}
