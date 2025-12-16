// lib/main.dart

import 'package:flutter/material.dart';
import 'package:geodos/pages/home_page.dart';
import 'package:geodos/pages/visor_page.dart';
import 'package:geodos/pages/contact_page.dart';
import 'package:geodos/pages/login_admin_page.dart';
import 'package:geodos/pages/about_page.dart';
import 'package:geodos/pages/accessibility_page.dart';
import 'package:geodos/pages/privacy_page.dart';
import 'package:geodos/pages/data_privacy_page.dart';
import 'package:geodos/pages/cookies_page.dart';

void main() {
  runApp(const GeodosApp());
}

class GeodosApp extends StatelessWidget {
  const GeodosApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Geodos',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const HomePage(),
        '/visor': (context) => const VisorPage(),
        '/contact': (context) => const ContactPage(),
        '/login': (context) => const LoginAdminPage(),
        '/about': (context) => const AboutPage(),
        '/accessibility': (context) => const AccessibilityStatementPage(),
        '/cookies': (context) => const CookiesPolicyPage(),
        '/data-privacy': (context) => const DataPrivacySettingsPage(),
        '/privacy': (context) => const PrivacyPolicyPage(),
      },
    );
  }
}
