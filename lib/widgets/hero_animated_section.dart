import 'package:flutter/material.dart';
import 'dart:math' as math;

class HeroAnimatedSection extends StatefulWidget {
  const HeroAnimatedSection({super.key});

  @override
  State<HeroAnimatedSection> createState() => _HeroAnimatedSectionState();
}

class _HeroAnimatedSectionState extends State<HeroAnimatedSection>
    with TickerProviderStateMixin {
  late AnimationController _earthController;
  late AnimationController _gradientController;

  @override
  void initState() {
    super.initState();

    // 🌍 Controlador para rotación de la Tierra
    _earthController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 60),
    )..repeat();

    // 🌫️ Controlador para animación del gradiente
    _gradientController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 50),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _earthController.dispose();
    _gradientController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;

    return AnimatedBuilder(
      animation: _gradientController,
      builder: (context, child) {
        final value = _gradientController.value;

        // Gradiente dinámico inspirado en movimiento oceánico/atmosférico
        final colors = [
          Color.lerp(const Color(0xFF0F4C81), const Color(0xFF2A9D8F), value)!,
          Color.lerp(const Color(0xFF2A9D8F), const Color(0xFF1E88E5), value)!,
          Color.lerp(const Color(0xFF1E88E5), const Color(0xFF26C6DA), value)!,
        ];

        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: colors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Stack(
            children: [
              // 🌍 Tierra giratoria con transparencia
              Center(
                child: AnimatedBuilder(
                  animation: _earthController,
                  builder: (_, __) {
                    return Transform.rotate(
                      angle: _earthController.value * 2 * math.pi,
                      child: Opacity(
                        opacity: 0.08,
                        child: Image.asset(
                          'assets/logos/geodos_tierra.png',
                          height: 500,
                          width: 500,
                          fit: BoxFit.contain,
                        ),
                      ),
                    );
                  },
                ),
              ),

              // 🧭 Contenido principal
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Consultoría ambiental, territorial y SIG',
                      textAlign: TextAlign.center,
                      style: t.headlineLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'En Geodos ayudamos a organizaciones públicas y privadas a tomar decisiones sobre el territorio,\n'
                      'integrando análisis ambiental, planificación y datos geoespaciales.',
                      textAlign: TextAlign.center,
                      style: t.titleMedium?.copyWith(
                        color: Colors.white.withOpacity(0.9),
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 32),
                    Wrap(
                      spacing: 16,
                      children: [
                        FilledButton(
                          onPressed: () =>
                              Navigator.pushNamed(context, '/visor'),
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: const Color(0xFF0F4C81),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 26, vertical: 14),
                          ),
                          child: const Text('Visualizar proyectos'),
                        ),
                        OutlinedButton(
                          onPressed: () =>
                              Navigator.pushNamed(context, '/contact'),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.white),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 26, vertical: 14),
                          ),
                          child: const Text('Consulta a un experto'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
