import 'package:flutter/material.dart';

import '../pages/login_admin_page.dart';
import 'app_drawer.dart';

class AppShell extends StatelessWidget {
  const AppShell({
    super.key,
    this.appBar,
    required this.body,
  });

  final PreferredSizeWidget? appBar;
  final Widget body;

  void _openAdminLogin(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const LoginAdminPage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: AppDrawer(onAdminAccess: () => _openAdminLogin(context)),
      appBar: appBar,
      body: body,
    );
  }
}
