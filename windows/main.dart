
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:geodos/brand/brand.dart';
import 'package:geodos/state/app_state.dart';
import 'package:geodos/pages/map_page.dart';
import 'package:geodos/pages/contact_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const GeodosApp());
}

class GeodosApp extends StatelessWidget {
  const GeodosApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AppState(),
      child: MaterialApp(
        title: 'GEODOS',
        theme: Brand.theme(),
        routes: {
          '/': (_) => const MapPage(),
          '/contact': (_) => const ContactPage(),
        },
        initialRoute: '/',
      ),
    );
  }
}
