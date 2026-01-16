import 'package:flutter/material.dart';
import '../widgets/app_shell.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return AppShell(
      appBar: AppBar(title: const Text('GEODOS · Quiénes somos')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 48),
        children: [
          Text('Consultoría ambiental y territorial',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text(
            'Especializada en estudios medioambientales, manejo SIG, ordenación del territorio, patrimonio, '
                'paisaje, urbanismo, divulgación, geolocalización y geomarketing.',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 16),
          Text('Nuestra vocación', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          const Text(
            'Somos una empresa afincada en Canarias pero con vocación nacional e internacional. '
                'Nuestros productos y servicios son utilizados por todo tipo de organizaciones públicas y privadas. '
                'Nuestro valor: la inclusión de la variable espacial en los distintos sectores socioeconómicos a partir '
                'de la reflexión y el análisis.',
            textAlign: TextAlign.justify,
          ),
        ],
      ),
    );
  }
}
