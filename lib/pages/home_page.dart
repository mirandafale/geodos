import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geodos/models/news_item.dart';
import 'package:geodos/services/auth_service.dart';
import 'package:geodos/services/news_service.dart';
import 'package:provider/provider.dart';
import 'package:geodos/widgets/app_shell.dart';
import 'package:geodos/pages/news_detail_page.dart';
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

    return AppShell(
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
                  final selectedCategory =
                      categories.contains(st.category) ? st.category : null;
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
                                  value: selectedCategory,
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
// BLOG / NOTICIAS – CARRUSEL DESDE FIRESTORE
// ---------------------------------------------------------------------------

class _BlogSection extends StatefulWidget {
  const _BlogSection({super.key});
  @override
  State<_BlogSection> createState() => _BlogSectionState();
}

class _BlogSectionState extends State<_BlogSection> {
  bool _sampleSeeded = false;
  bool _isSeeding = false;

  Future<void> _maybeSeedDebugNews(List<NewsItem> currentPosts) async {
    if (_sampleSeeded || _isSeeding || !kDebugMode || currentPosts.length >= 3) {
      _sampleSeeded = _sampleSeeded || currentPosts.length >= 3;
      return;
    }

    setState(() {
      _isSeeding = true;
    });

    final now = DateTime.now();
    final samples = [
      NewsItem(
        id: 'sample_news_1',
        title: 'Ejemplo de noticia: Participación ciudadana',
        body: 'Exploramos cómo la cartografía colaborativa mejora la gestión territorial y la transparencia.',
        imageUrl: '',
        createdAt: now,
        updatedAt: now,
        published: true,
        hasCreatedAt: false,
      ),
      NewsItem(
        id: 'sample_news_2',
        title: 'Ejemplo de noticia: Innovación ambiental',
        body: 'Nuevas herramientas digitales para medir el impacto ambiental y tomar decisiones informadas.',
        imageUrl: '',
        createdAt: now.subtract(const Duration(days: 2)),
        updatedAt: now.subtract(const Duration(days: 2)),
        published: true,
        hasCreatedAt: false,
      ),
    ];

    try {
      final existingIds = currentPosts.map((e) => e.id).toSet();
      final missingSamples = samples
          .where((s) => !existingIds.contains(s.id))
          .take(3 - currentPosts.length)
          .toList();
      if (missingSamples.isNotEmpty) {
        await NewsService.seedDebugSamples(missingSamples);
      }
      _sampleSeeded = true;
    } finally {
      if (mounted) {
        setState(() {
          _isSeeding = false;
        });
      } else {
        _isSeeding = false;
      }
    }
  }

  String _excerpt(String text, {int maxLength = 200}) {
    final clean = text.trim();
    if (clean.length <= maxLength) return clean;
    return '${clean.substring(0, maxLength).trimRight()}…';
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final auth = context.watch<AuthService>();
    return StreamBuilder<List<NewsItem>>(
      stream: NewsService.publishedStream(),
      builder: (context, snapshot) {
        final posts = snapshot.data ?? [];
        final isLoading = snapshot.connectionState == ConnectionState.waiting;
        final hasError = snapshot.hasError;
        final errorMessage = snapshot.error?.toString();

        if (!isLoading && !hasError) {
          _maybeSeedDebugNews(posts);
        }

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
                  if (hasError)
                    Card(
                      color: Colors.red.shade50,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          children: [
                            Icon(Icons.error_outline, color: Colors.red.shade700),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'No se pudieron cargar las noticias: ${errorMessage ?? 'Error desconocido'}',
                                style: t.bodyMedium?.copyWith(color: Colors.red.shade800),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else if (isLoading)
                    _NewsSkeleton(textTheme: t)
                  else if (posts.isEmpty)
                    Card(
                      elevation: 1,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.article_outlined, color: Colors.grey.shade600, size: 32),
                            const SizedBox(height: 12),
                            Text(
                              'Aún no hay noticias publicadas',
                              style: t.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Cuando haya novedades las verás aquí. Vuelve pronto para conocer la actualidad de GEODOS.',
                              textAlign: TextAlign.center,
                              style: t.bodyMedium?.copyWith(color: Colors.grey.shade700),
                            ),
                            if (auth.isAdmin) ...[
                              const SizedBox(height: 16),
                              FilledButton.icon(
                                icon: const Icon(Icons.add),
                                onPressed: () => Navigator.pushNamed(context, '/admin'),
                                label: const Text('Publicar noticia'),
                              ),
                            ],
                          ],
                        ),
                      ),
                    )
                  else
                    Column(
                      children: [
                        _NewsCarousel(
                          items: posts,
                          excerptBuilder: _excerpt,
                          onSelect: (item) => _openNewsDetail(context, item),
                        ),
                        const SizedBox(height: 24),
                        _NewsList(
                          items: posts,
                          excerptBuilder: _excerpt,
                          onSelect: (item) => _openNewsDetail(context, item),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _openNewsDetail(BuildContext context, NewsItem item) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => NewsDetailPage(item: item),
      ),
    );
  }
}

class _NewsCarousel extends StatefulWidget {
  const _NewsCarousel({
    required this.items,
    required this.excerptBuilder,
    required this.onSelect,
  });

  final List<NewsItem> items;
  final String Function(String text, {int maxLength}) excerptBuilder;
  final ValueChanged<NewsItem> onSelect;

  @override
  State<_NewsCarousel> createState() => _NewsCarouselState();
}

class _NewsCarouselState extends State<_NewsCarousel> {
  late final PageController _newsCtrl;
  int _newsIndex = 0;
  Timer? _autoTimer;

  @override
  void initState() {
    super.initState();
    _newsCtrl = PageController(viewportFraction: 0.92);
    _restartAutoPlay();
  }

  @override
  void didUpdateWidget(covariant _NewsCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.items.length != oldWidget.items.length && _newsIndex >= widget.items.length) {
      setState(() {
        _newsIndex = 0;
      });
      if (_newsCtrl.hasClients) {
        _newsCtrl.jumpToPage(0);
      }
    }
    if (widget.items.length != oldWidget.items.length) {
      _restartAutoPlay();
    }
  }

  @override
  void dispose() {
    _autoTimer?.cancel();
    _newsCtrl.dispose();
    super.dispose();
  }

  void _restartAutoPlay() {
    _autoTimer?.cancel();
    if (widget.items.length <= 1) return;
    _autoTimer = Timer.periodic(const Duration(seconds: 6), (_) {
      if (!mounted || widget.items.isEmpty || !_newsCtrl.hasClients) return;
      final nextIndex = _newsIndex + 1 >= widget.items.length ? 0 : _newsIndex + 1;
      _newsCtrl.animateToPage(
        nextIndex,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    });
  }

  void _goTo(int index) {
    if (widget.items.isEmpty) return;
    final target = index.clamp(0, widget.items.length - 1);
    _newsCtrl.animateToPage(
      target,
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeInOut,
    );
    _restartAutoPlay();
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 900;
        final height = constraints.maxWidth >= 900 ? 420.0 : 320.0;
        final showNav = constraints.maxWidth >= 700 && widget.items.length > 1;

        return Column(
          children: [
            SizedBox(
              height: height,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  PageView.builder(
                    controller: _newsCtrl,
                    physics: const PageScrollPhysics(),
                    itemCount: widget.items.length,
                    onPageChanged: (i) {
                      setState(() => _newsIndex = i);
                      _restartAutoPlay();
                    },
                    itemBuilder: (ctx, index) {
                      final item = widget.items[index];
                      final subtitle = item.body.trim().isNotEmpty
                          ? widget.excerptBuilder(item.body, maxLength: 80)
                          : (item.hasCreatedAt
                              ? "Publicado: ${item.createdAt.toLocal().toIso8601String().split('T').first}"
                              : null);
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(22),
                          onTap: () => widget.onSelect(item),
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(22),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.12),
                                  blurRadius: 18,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(22),
                                child: Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    _NewsHeroImage(
                                      imageUrl: item.imageUrl,
                                      title: item.title,
                                    ),
                                    if (subtitle != null)
                                      Positioned(
                                        left: 20,
                                        right: 20,
                                        bottom: 76,
                                        child: Text(
                                          subtitle,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: t.bodySmall?.copyWith(
                                            color: Colors.white70,
                                          ),
                                        ),
                                      ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  if (showNav)
                    Positioned(
                      left: isWide ? 8 : 4,
                      child: _NavButton(
                        icon: Icons.chevron_left,
                        onPressed: _newsIndex > 0 ? () => _goTo(_newsIndex - 1) : null,
                      ),
                    ),
                  if (showNav)
                    Positioned(
                      right: isWide ? 8 : 4,
                      child: _NavButton(
                        icon: Icons.chevron_right,
                        onPressed: _newsIndex < widget.items.length - 1
                            ? () => _goTo(_newsIndex + 1)
                            : null,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(widget.items.length, (i) {
                final selected = i == _newsIndex;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: selected ? 14 : 8,
                  height: selected ? 14 : 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: selected
                        ? Theme.of(context).colorScheme.primary
                        : Colors.grey.shade400,
                  ),
                );
              }),
            ),
          ],
        );
      },
    );
  }
}

class _NewsList extends StatelessWidget {
  const _NewsList({
    required this.items,
    required this.excerptBuilder,
    required this.onSelect,
  });

  final List<NewsItem> items;
  final String Function(String text, {int maxLength}) excerptBuilder;
  final ValueChanged<NewsItem> onSelect;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 700;
        return ListView.separated(
          itemCount: items.length,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final item = items[index];
            final excerpt = item.body.trim().isEmpty
                ? 'Noticia sin resumen disponible.'
                : excerptBuilder(item.body, maxLength: 140);
            return InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: () => onSelect(item),
              child: Card(
                elevation: 1,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: isWide
                      ? Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(14),
                              child: SizedBox(
                                width: 180,
                                height: 110,
                                child: Image.network(
                                  item.imageUrl,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      color: Colors.grey.shade200,
                                      alignment: Alignment.center,
                                      child: const Icon(Icons.broken_image_outlined),
                                    );
                                  },
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.title,
                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                          fontWeight: FontWeight.w700,
                                        ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    excerpt,
                                    maxLines: 3,
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(color: Colors.grey.shade700),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Icon(Icons.chevron_right),
                          ],
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(14),
                              child: AspectRatio(
                                aspectRatio: 16 / 9,
                                child: Image.network(
                                  item.imageUrl,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      color: Colors.grey.shade200,
                                      alignment: Alignment.center,
                                      child: const Icon(Icons.broken_image_outlined),
                                    );
                                  },
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              item.title,
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              excerpt,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(color: Colors.grey.shade700),
                            ),
                          ],
                        ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _NewsHeroImage extends StatelessWidget {
  const _NewsHeroImage({required this.imageUrl, required this.title});

  final String? imageUrl;
  final String title;

  @override
  Widget build(BuildContext context) {
    final url = imageUrl?.trim() ?? '';
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (url.isEmpty)
              const _NewsHeroFallback()
            else
              Image.network(
                url,
                fit: BoxFit.cover,
                alignment: Alignment.center,
                width: double.infinity,
                height: double.infinity,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    color: Colors.grey.shade200,
                    alignment: Alignment.center,
                    child: const SizedBox(
                      height: 28,
                      width: 28,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return const _NewsHeroFallback();
                },
              ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                color: Colors.black54,
                child: Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NewsHeroFallback extends StatelessWidget {
  const _NewsHeroFallback();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0C6372), Color(0xFF2A7F62)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Align(
        alignment: Alignment.center,
        child: Icon(
          Icons.image_not_supported_outlined,
          color: Colors.white.withOpacity(0.7),
          size: 48,
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({required this.icon, required this.onPressed});

  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final isDisabled = onPressed == null;
    return AnimatedOpacity(
      opacity: isDisabled ? 0.35 : 1,
      duration: const Duration(milliseconds: 200),
      child: Material(
        color: Colors.white.withOpacity(0.85),
        shape: const CircleBorder(),
        child: IconButton(
          onPressed: onPressed,
          icon: Icon(icon, color: Colors.black87),
          tooltip: icon == Icons.chevron_left ? 'Anterior' : 'Siguiente',
        ),
      ),
    );
  }
}

class _NewsSkeleton extends StatelessWidget {
  const _NewsSkeleton({required this.textTheme});

  final TextTheme textTheme;

  @override
  Widget build(BuildContext context) {
    final baseColor = textTheme.bodySmall?.color?.withOpacity(0.15) ??
        Colors.grey.shade300;
    return Column(
      children: List.generate(2, (index) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6.0),
          child: Card(
            elevation: 1,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Container(
                    height: 90,
                    width: 110,
                    decoration: BoxDecoration(
                      color: baseColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(height: 16, width: 160, color: baseColor),
                        const SizedBox(height: 10),
                        Container(height: 12, width: double.infinity, color: baseColor),
                        const SizedBox(height: 8),
                        Container(height: 12, width: 140, color: baseColor),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }),
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
                    onPressed: () => Navigator.pushNamed(context, '/contact'),
                    child: const Text('Habla con un experto'),
                  ),
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white),
                    ),
                    onPressed: () => Navigator.pushNamed(context, '/contact'),
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
                  _FooterLink(label: 'Privacidad', route: '/privacy'),
                  _FooterLink(label: 'Cookies', route: '/cookies'),
                  _FooterLink(label: 'Ajustes de datos', route: '/data-privacy'),
                  _FooterLink(label: 'Términos de uso', route: '/terms'),
                  _FooterLink(label: 'Accesibilidad', route: '/accessibility'),
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
  final String route;
  const _FooterLink({required this.label, required this.route});
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => Navigator.pushNamed(context, route),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Colors.white,
          decoration: TextDecoration.underline,
        ),
      ),
    );
  }
}
