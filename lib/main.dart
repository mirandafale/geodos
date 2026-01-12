// lib/main.dart

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:geodos/brand/brand.dart';
import 'package:geodos/firebase_options.dart';
import 'package:geodos/pages/about_page.dart';
import 'package:geodos/pages/accessibility_page.dart';
import 'package:geodos/pages/admin_dashboard_page.dart';
import 'package:geodos/pages/blog_page.dart';
import 'package:geodos/pages/contact_page.dart';
import 'package:geodos/pages/cookies_page.dart';
import 'package:geodos/pages/data_privacy_page.dart';
import 'package:geodos/pages/home_page.dart';
import 'package:geodos/pages/login_admin_page.dart';
import 'package:geodos/pages/privacy_page.dart';
import 'package:geodos/pages/terms_page.dart';
import 'package:geodos/pages/visor_page.dart';
import 'package:geodos/services/auth_service.dart';
import 'package:geodos/widgets/admin_gate.dart';
import 'package:geodos/widgets/consent_gate.dart';
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
    return ChangeNotifierProvider<AuthService>.value(
      value: AuthService.instance,
      child: MaterialApp(
        title: 'Geodos',
        debugShowCheckedModeBanner: false,
        theme: Brand.theme(),
        initialRoute: '/',
        builder: (context, child) {
          return LayoutBuilder(
            builder: (context, constraints) {
              final mediaQuery = MediaQuery.of(context);
              final width = constraints.maxWidth;
              final textScale = ResponsiveBreakpoints.textScaleForWidth(
                width,
                mediaQuery.textScaler.scale(1.0),
              );

              return MediaQuery(
                data: mediaQuery.copyWith(
                  textScaler: TextScaler.linear(textScale),
                ),
                child: ConsentGate(
                  child: child ?? const SizedBox.shrink(),
                ),
              );
            },
          );
        },
        routes: {
          '/': (context) => const HomePage(),
          '/home': (context) => const HomePage(),
          '/visor': (context) => const VisorPage(),
          '/contact': (context) => const ContactPage(),
          '/login': (context) => const LoginAdminPage(),
          '/login-admin': (context) => const LoginAdminPage(),
          '/about': (context) => const AboutPage(),
          '/blog': (context) => const BlogPage(),
          '/accessibility': (context) => const AccessibilityStatementPage(),
          '/cookies': (context) => const CookiesPolicyPage(),
          '/data-privacy': (context) => const DataPrivacySettingsPage(),
          '/privacy': (context) => const PrivacyPolicyPage(),
          '/terms': (context) => const TermsPage(),
          '/admin': (context) => const AdminGate(child: AdminDashboardPage()),
        },
      ),
    );
  }
}

class ResponsiveBreakpoints {
  static const double mobile = 768;
  static const double tablet = 1200;

  static bool isMobile(double width) => width < mobile;
  static bool isTablet(double width) => width >= mobile && width < tablet;
  static bool isDesktop(double width) => width >= tablet;

  static double textScaleForWidth(double width, double systemScale) {
    if (isMobile(width)) {
      return systemScale.clamp(0.9, 1.0);
    }
    if (isTablet(width)) {
      return systemScale.clamp(0.95, 1.05);
    }
    return systemScale;
  }
}
