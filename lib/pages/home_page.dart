import 'dart:async';

import 'package:flutter/material.dart';

// Menú lateral con las diferentes opciones de navegación.
import '../widgets/app_drawer.dart';
// Visor incrustado para mostrar los proyectos georreferenciados.
import '../widgets/visor_embed.dart';
// Controlador de filtros para mantener el estado de ámbito (categoría), año, etc.
import '../services/filters_controller.dart';
// Servicio que carga los proyectos desde el JSON de assets y expone categorías disponibles.
import '../services/project_service.dart';

/// Página de inicio de GEODOS basada en el diseño original proporcionado.
///
/// Incluye un encabezado (hero), una sección de servicios, una sección de
/// proyectos por categoría con un visor reducido, un apartado de flujo de
/// trabajo, una sección "Quiénes somos", un carrusel de blog/noticias,
/// un bloque de llamada a la acción y un pie de página con enlaces
/// legales. Todas las secciones se pueden alcanzar mediante el menú superior
/// que realiza scroll a la posición correspondiente.
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _scrollCtrl = ScrollController();

  // Claves para hacer scroll a secciones concretas.
  final _servicesKey = GlobalKey();
  final _projectsKey = GlobalKey();
  final _aboutKey = GlobalKey();
  final _blogKey = GlobalKey();
  final _ctaKey = GlobalKey();
  final _footerKey = GlobalKey();

  /// Desplaza la vista hasta la sección asociada a [key].
  void _scrollTo(GlobalKey key) {
    final ctx = key.currentContext;
    if (ctx == null) return;

    Scrollable.ensureVisible(
      ctx,
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeInOut,
      alignment: 0.1,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Colors.white),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFF0C6372),
                Color(0xFF2A7F62),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: Text(
          'GEODOS',
          style: theme.textTheme.titleLarge?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => _scrollTo(_servicesKey),
            child: const Text('Servicios', style: TextStyle(color: Colors.white)),
          ),
          TextButton(
            onPressed: () => Navigator.pushNamed(context, '/visor'),
            child: const Text('Proyectos', style: TextStyle(color: Colors.white)),
          ),
          TextButton(
            onPressed: () => _scrollTo(_aboutKey),
            child: const Text('Quiénes somos', style: TextStyle(color: Colors.white)),
          ),
          TextButton(
            onPressed: () => _scrollTo(_ctaKey),
            child: const Text('Contacto', style: TextStyle(color: Colors.white)),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: ListView(
        controller: _scrollCtrl,
        padding: EdgeInsets.zero,
        children: [
          _HeroSection(),
          const SizedBox(height: 40),
          _ServicesSection(key: _servicesKey),
          const SizedBox(height: 40),
          _ProjectsByCategorySection(key: _projectsKey),
          const SizedBox(height: 40),
          _WorkflowSection(),
          const SizedBox(height: 40),
          _AboutSection(key: _aboutKey),
          const SizedBox(height: 40),
          _BlogSection(key: _blogKey),
          const SizedBox(height: 40),
          _FinalCtaSection(key: _ctaKey),
          const SizedBox(height: 24),
          _FooterSection(key: _footerKey),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// HEADER DE SECCIÓN
// ---------------------------------------------------------------------------

/// Widget reutilizable para encabezados de sección.
class _SectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData? icon;

  const _SectionHeader({
    required this.title,
    this.subtitle,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final primary = Theme.of(context).colorScheme.primary;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      color: Colors.white,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border(
            left: BorderSide(
              color: primary,
              width: 4,
            ),
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (icon != null)
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: primary.withOpacity(0.10),
                ),
                child: Icon(
                  icon,
                  color: primary,
                  size: 22,
                ),
              ),
            if (icon != null) const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: t.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: primary,
                    ),
                  ),
                  if (subtitle != null) const SizedBox(height: 4),
                  if (subtitle != null)
                    Text(
                      subtitle!,
                      style: t.bodyMedium?.copyWith(
                        color: Colors.grey.shade800,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// HERO
// ---------------------------------------------------------------------------

class _HeroSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(32, 40, 32, 60),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF0C6372),
            Color(0xFF2A7F62),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Consultoría ambiental, territorial y SIG',
                      style: t.headlineMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'En Geodos ayudamos a organizaciones públicas y privadas a tomar decisiones sobre el territorio, integrando análisis ambiental, planificación y datos geoespaciales.',
                      style: t.bodyLarge?.copyWith(
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: () => Navigator.pushNamed(context, '/visor'),
                      child: const Text('Explorar proyectos'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// SERVICIOS
// ---------------------------------------------------------------------------

class _ServicesSection extends StatelessWidget {
  const _ServicesSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1100),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const _SectionHeader(
                title: 'Servicios principales',
                subtitle: 'Consultoría ambiental y territorial especializada en evaluación, planificación y sistemas de información geográfica.',
                icon: Icons.miscellaneous_services,
              ),
              const SizedBox(height: 24),
              Wrap(
                spacing: 16,
                runSpacing: 16,
                alignment: WrapAlignment.center,
                children: const [
                  _ServiceCard(
                    icon: Icons.fact_check,
                    title: 'Evaluación de Impacto Ambiental',
                    subtitle: 'Estudios detallados para valorar los efectos de planes y proyectos sobre el medio.',
                  ),
                  _ServiceCard(
                    icon: Icons.map,
                    title: 'Ordenación del Territorio y Urbanismo',
                    subtitle: 'Planes, informes y apoyo técnico a la planificación territorial y urbanística.',
                  ),
                  _ServiceCard(
                    icon: Icons.terrain,
                    title: 'Estudios de Paisaje',
                    subtitle: 'Análisis visual y paisajístico para integración y mejora del entorno.',
                  ),
                  _ServiceCard(
                    icon: Icons.account_balance,
                    title: 'Patrimonio y Geodiversidad',
                    subtitle: 'Identificación, valoración y divulgación de patrimonio natural y cultural.',
                  ),
                  _ServiceCard(
                    icon: Icons.spatial_tracking,
                    title: 'Sistemas de Información Geográfica (SIG)',
                    subtitle: 'Modelización espacial, cartografía avanzada y cuadros de mando geográficos.',
                  ),
                  _ServiceCard(
                    icon: Icons.analytics,
                    title: 'Geomarketing y análisis socioterritorial',
                    subtitle: 'Apoyo a la toma de decisiones en localización, movilidad y demografía.',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ServiceCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _ServiceCard({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return SizedBox(
      width: 260,
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            Container(
              height: 90,
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).colorScheme.primary.withOpacity(0.18),
                    Theme.of(context).colorScheme.primary.withOpacity(0.04),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Center(
                child: Icon(
                  icon,
                  size: 32,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              child: Column(
                children: [
                  Text(
                    title,
                    style: t.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    subtitle,
                    style: t.bodySmall,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// PROYECTOS POR CATEGORÍA – MINI VISOR
// ---------------------------------------------------------------------------

class _ProjectsByCategorySection extends StatelessWidget {
  const _ProjectsByCategorySection({super.key});

  @override
  Widget build(BuildContext context) {
    final filters = FiltersController.instance;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1100),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: FutureBuilder<List<String>>(
            future: ProjectService.getCategories(),
            builder: (context, snapshot) {
              final categories = snapshot.data ?? [];
              return AnimatedBuilder(
                animation: filters,
                builder: (ctx, _) {
                  final st = filters.state;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const _SectionHeader(
                        title: 'Proyectos por categoría',
                        subtitle:
                            'Algunos de los proyectos georreferenciados desarrollados por GEODOS en diferentes ámbitos.',
                        icon: Icons.location_on_outlined,
                      ),
                      const SizedBox(height: 24),
                      Card(
                        elevation: 3,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              const Text('Categoría'),
                              const SizedBox(width: 16),
                              Expanded(
                                child: DropdownButtonFormField<String?>(
                                  value: st.category,
                                  decoration: const InputDecoration(
                                    border: OutlineInputBorder(),
                                  ),
                                  items: [
                                    const DropdownMenuItem<String?>(
                                      value: null,
                                      child: Text('Todas'),
                                    ),
                                    ...categories.map(
                                      (c) => DropdownMenuItem<String?>(
                                        value: c,
                                        child: Text(c),
                                      ),
                                    ),
                                  ],
                                  onChanged: filters.setCategory,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      const VisorEmbed(startExpanded: false),
                    ],
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// CÓMO TRABAJAMOS
// ---------------------------------------------------------------------------

class _WorkflowSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1100),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const _SectionHeader(
                title: 'Cómo trabajamos',
                subtitle:
                'Metodología basada en el análisis, la participación y la implementación rigurosa.',
                icon: Icons.route,
              ),
              const SizedBox(height: 24),
              Wrap(
                spacing: 32,
                runSpacing: 16,
                alignment: WrapAlignment.center,
                children: const [
                  _WorkflowStep(
                    icon: Icons.search,
                    title: '1. Análisis inicial',
                    description:
                    'Revisión de contexto, normativa y actores implicados. Identificación de necesidades.',
                  ),
                  _WorkflowStep(
                    icon: Icons.science,
                    title: '2. Estudio técnico',
                    description:
                    'Trabajo de campo, análisis espacial y elaboración de propuestas.',
                  ),
                  _WorkflowStep(
                    icon: Icons.handshake,
                    title: '3. Soluciones personalizadas',
                    description:
                    'Diseño de alternativas adaptadas al territorio y a cada organización.',
                  ),
                  _WorkflowStep(
                    icon: Icons.task_alt,
                    title: '4. Implementación y seguimiento',
                    description:
                    'Acompañamiento en la ejecución, indicadores y mejora continua.',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WorkflowStep extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _WorkflowStep({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return SizedBox(
      width: 240,
      child: Column(
        children: [
          Icon(icon, size: 32, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 12),
          Text(
            title,
            style: t.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            description,
            style: t.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// QUIÉNES SOMOS
// ---------------------------------------------------------------------------

class _AboutSection extends StatelessWidget {
  const _AboutSection({super.key});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    const officeImageUrl =
        'https://images.pexels.com/photos/3184465/pexels-photo-3184465.jpeg?auto=compress&cs=tinysrgb&w=1200';
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1100),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const _SectionHeader(
                title: 'Quiénes somos',
                subtitle:
                'Un equipo especializado en medio ambiente, territorio y sistemas de información geográfica.',
                icon: Icons.people_outline,
              ),
              const SizedBox(height: 24),
              LayoutBuilder(
                builder: (ctx, constraints) {
                  final isWide = constraints.maxWidth > 800;
                  final image = Expanded(
                    flex: 1,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: AspectRatio(
                        aspectRatio: 4 / 3,
                        child: Image.network(
                          officeImageUrl,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  );
                  final text = Expanded(
                    flex: 2,
                    child: Padding(
                      padding: EdgeInsets.only(
                        left: isWide ? 32 : 0,
                        top: isWide ? 0 : 16,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Geodos es una consultora especializada en estudios medioambientales, manejo SIG, ordenación del territorio, patrimonio, paisaje, urbanismo y divulgación. Trabajamos con administraciones públicas, empresas y entidades sociales para integrar la variable espacial en la toma de decisiones.',
                            style: t.bodyMedium,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Desde Canarias, pero con vocación nacional e internacional, combinamos experiencia técnica y capacidad de comunicación para que los resultados sean comprensibles y útiles para todos los agentes implicados.',
                            style: t.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                  );
                  if (isWide) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [image, text],
                    );
                  } else {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [image, text],
                    );
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// BLOG / NOTICIAS – CARRUSEL ESTÁTICO
// ---------------------------------------------------------------------------

class _BlogPost {
  final String title;
  final String description;
  final String imageUrl;
  const _BlogPost({required this.title, required this.description, required this.imageUrl});
}

class _BlogSection extends StatefulWidget {
  const _BlogSection({super.key});
  @override
  State<_BlogSection> createState() => _BlogSectionState();
}

class _BlogSectionState extends State<_BlogSection> {
  final _pageCtrl = PageController(viewportFraction: 0.9);
  int _current = 0;
  Timer? _timer;

  final List<_BlogPost> _posts = const [
    _BlogPost(
      title: 'Nuevas metodologías para la evaluación ambiental estratégica',
      description: 'Cómo integrar variables territoriales y climáticas en la planificación a largo plazo.',
      imageUrl:
      'https://images.pexels.com/photos/3137064/pexels-photo-3137064.jpeg?auto=compress&cs=tinysrgb&w=1200',
    ),
    _BlogPost(
      title: 'Cartografía colaborativa para la gestión del patrimonio',
      description: 'Proyectos donde ciudadanía y administraciones construyen mapas de patrimonio compartidos.',
      imageUrl:
      'https://images.pexels.com/photos/1181467/pexels-photo-1181467.jpeg?auto=compress&cs=tinysrgb&w=1200',
    ),
    _BlogPost(
      title: 'El papel del SIG en la adaptación al cambio climático',
      description: 'Uso de datos geoespaciales para identificar riesgos y priorizar actuaciones.',
      imageUrl:
      'https://images.pexels.com/photos/7571043/pexels-photo-7571043.jpeg?auto=compress&cs=tinysrgb&w=1200',
    ),
    _BlogPost(
      title: 'Participación ciudadana en proyectos territoriales',
      description: 'Herramientas digitales para recoger aportaciones y mejorar la toma de decisiones.',
      imageUrl:
      'https://images.pexels.com/photos/3861964/pexels-photo-3861964.jpeg?auto=compress&cs=tinysrgb&w=1200',
    ),
    _BlogPost(
      title: 'Tendencias en planificación urbana sostenible',
      description: 'Movilidad, renaturalización de espacios y resiliencia climática en las ciudades.',
      imageUrl:
      'https://images.pexels.com/photos/2486168/pexels-photo-2486168.jpeg?auto=compress&cs=tinysrgb&w=1200',
    ),
  ];

  @override
  void initState() {
    super.initState();
    // Carrusel automático: avanza cada 7 segundos.
    _timer = Timer.periodic(const Duration(seconds: 7), (_) {
      if (!mounted) return;
      final next = (_current + 1) % _posts.length;
      _pageCtrl.animateToPage(
        next,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageCtrl.dispose();
    super.dispose();
  }

  void _goTo(int index) {
    final target = index.clamp(0, _posts.length - 1);
    _pageCtrl.animateToPage(
      target,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1100),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const _SectionHeader(
                title: 'Blog y actualidad',
                subtitle:
                'Reflexiones, proyectos y noticias relacionadas con la planificación territorial y el medio ambiente.',
                icon: Icons.article_outlined,
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 280,
                child: PageView.builder(
                  controller: _pageCtrl,
                  itemCount: _posts.length,
                  onPageChanged: (i) => setState(() => _current = i),
                  itemBuilder: (ctx, index) {
                    final p = _posts[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: Card(
                        elevation: 3,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                        clipBehavior: Clip.antiAlias,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              height: 130,
                              width: double.infinity,
                              child: Image.network(
                                p.imageUrl,
                                fit: BoxFit.cover,
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    p.title,
                                    style: t.titleMedium?.copyWith(
                                        fontWeight: FontWeight.w600),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    p.description,
                                    style: t.bodySmall,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Solo admin podrá editar estas noticias en la versión conectada a Firebase.',
                                    style: t.labelSmall?.copyWith(
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    onPressed: () => _goTo(_current - 1),
                    icon: const Icon(Icons.chevron_left),
                  ),
                  const SizedBox(width: 8),
                  ...List.generate(_posts.length, (i) {
                    final selected = i == _current;
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: selected ? 12 : 8,
                      height: selected ? 12 : 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: selected
                            ? Theme.of(context).colorScheme.primary
                            : Colors.grey.shade400,
                      ),
                    );
                  }),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () => _goTo(_current + 1),
                    icon: const Icon(Icons.chevron_right),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// CTA FINAL
// ---------------------------------------------------------------------------

class _FinalCtaSection extends StatelessWidget {
  const _FinalCtaSection({super.key});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 28),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0C6372), Color(0xFF2A7F62)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '¿Hablamos de tu territorio?',
                      style: t.headlineSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Cuéntanos tu proyecto y te ayudamos a definir la mejor solución técnica y ambiental.',
                      style: t.bodyMedium?.copyWith(
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 24),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Theme.of(context).colorScheme.primary,
                    ),
                    onPressed: () => Navigator.pushNamed(context, '/contacto'),
                    child: const Text('Habla con un experto'),
                  ),
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white),
                    ),
                    onPressed: () => Navigator.pushNamed(context, '/contacto'),
                    child: const Text('Pídenos un presupuesto'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// FOOTER
// ---------------------------------------------------------------------------

class _FooterSection extends StatelessWidget {
  const _FooterSection({super.key});
  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Container(
      color: const Color(0xFF0B1F26),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '© ${DateTime.now().year} GEODOS · Consultoría ambiental y territorial',
                style: t.bodySmall?.copyWith(color: Colors.white70),
              ),
              Wrap(
                spacing: 16,
                children: const [
                  _FooterLink('Aviso legal'),
                  _FooterLink('Política de privacidad'),
                  _FooterLink('Política de cookies'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FooterLink extends StatelessWidget {
  final String label;
  const _FooterLink(this.label);
  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
        color: Colors.white,
        decoration: TextDecoration.underline,
      ),
    );
  }
}