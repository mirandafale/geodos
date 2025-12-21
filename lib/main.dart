// lib/main.dart

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:geodos/brand/brand.dart';
import 'package:geodos/firebase_options.dart';
import 'package:geodos/pages/about_page.dart';
import 'package:geodos/pages/accessibility_page.dart';
import 'package:geodos/pages/contact_page.dart';
import 'package:geodos/pages/cookies_page.dart';
import 'package:geodos/pages/data_privacy_page.dart';
import 'package:geodos/pages/home_page.dart';
import 'package:geodos/pages/login_admin_page.dart';
import 'package:geodos/pages/privacy_page.dart';
import 'package:geodos/pages/visor_page.dart';
import 'package:geodos/pages/terms_page.dart';
import 'package:geodos/services/auth_service.dart';
import 'package:geodos/widgets/admin_gate.dart';
import 'package:provider/provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(
    ChangeNotifierProvider<AuthService>(
      create: (_) => AuthService.instance,
      child: const GeodosApp(),
    ),
  );
}

class GeodosApp extends StatelessWidget {
  const GeodosApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Geodos',
      debugShowCheckedModeBanner: false,
      theme: Brand.theme(),
      initialRoute: '/',
      routes: {
        '/': (context) => const HomePage(),
        '/home': (context) => const HomePage(),
        '/quienes': (context) => const AboutPage(),
        '/visor': (context) => const VisorPage(),
        '/contact': (context) => const ContactPage(),
        '/contacto': (context) => const ContactPage(),
        '/login': (context) => const LoginAdminPage(),
        '/admin': (context) => const AdminGate(child: LoginAdminPage()),
        '/about': (context) => const AboutPage(),
        '/accessibility': (context) => const AccessibilityStatementPage(),
        '/cookies': (context) => const CookiesPolicyPage(),
        '/data-privacy': (context) => const DataPrivacySettingsPage(),
        '/privacy': (context) => const PrivacyPolicyPage(),
        '/terms': (context) => const TermsConditionsPage(),
      },
    );
  }
}
