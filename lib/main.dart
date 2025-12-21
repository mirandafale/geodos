// lib/main.dart

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:geodos/brand/brand.dart';
import 'package:geodos/firebase_options.dart';
import 'package:geodos/pages/about_page.dart';
import 'package:geodos/pages/accessibility_page.dart';
import 'package:geodos/pages/admin_dashboard_page.dart';
import 'package:geodos/pages/contact_page.dart';
import 'package:geodos/pages/cookies_page.dart';
import 'package:geodos/pages/data_privacy_page.dart';
import 'package:geodos/pages/home_page.dart';
import 'package:geodos/pages/login_admin_page.dart';
import 'package:geodos/pages/privacy_page.dart';
import 'package:geodos/pages/visor_page.dart';
import 'package:geodos/services/auth_service.dart';
import 'package:geodos/widgets/admin_gate.dart';
import 'package:provider/provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const GeodosApp());
}

class GeodosApp extends StatelessWidget {
  const GeodosApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<AuthService>(
      create: (_) => AuthService.instance,
      child: MaterialApp(
        title: 'Geodos',
        debugShowCheckedModeBanner: false,
        theme: Brand.theme(),
        initialRoute: '/',
        routes: {
          '/': (context) => const HomePage(),
          '/home': (context) => const HomePage(),
          '/visor': (context) => const VisorPage(),
          '/contact': (context) => const ContactPage(),
          '/login': (context) => const LoginAdminPage(),
          '/about': (context) => const AboutPage(),
          '/accessibility': (context) => const AccessibilityStatementPage(),
          '/cookies': (context) => const CookiesPolicyPage(),
          '/data-privacy': (context) => const DataPrivacySettingsPage(),
          '/privacy': (context) => const PrivacyPolicyPage(),
          '/admin': (context) => AdminGate(
                child: const AdminDashboardPage(),
              ),
        },
      ),
    );
  }
}
