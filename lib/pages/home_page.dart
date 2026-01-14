import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geodos/brand/brand.dart';
import 'package:geodos/models/carousel_item.dart';
import 'package:geodos/models/news_item.dart';
import 'package:geodos/services/auth_service.dart';
import 'package:geodos/services/news_service.dart';
import 'package:provider/provider.dart';
import 'package:geodos/widgets/app_shell.dart';
import 'package:geodos/pages/news_detail_page.dart';
import 'package:url_launcher/url_launcher.dart';
import '../widgets/hero_animated_section.dart';
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

  void _scrollToTop() {
    _scrollCtrl.animateTo(
      0,
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isWide = MediaQuery.of(context).size.width >= 980;

    return AppShell(
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.18),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withOpacity(0.4)),
            ),
            child: const Icon(Icons.public, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'GEODOS',
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.8,
                ),
              ),
              Text(
                'Consultoría ambiental y SIG',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: Colors.white.withOpacity(0.85),
                  letterSpacing: 0.4,
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        if (isWide)
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _NavAction(
                    label: 'Servicios',
                    onPressed: () => _scrollTo(_servicesKey),
                  ),
                  _NavAction(
                    label: 'Proyectos',
                    onPressed: () => Navigator.pushNamed(context, '/visor'),
                  ),
                  _NavAction(
                    label: 'Quiénes somos',
                    onPressed: () => _scrollTo(_aboutKey),
                  ),
                  _NavAction(
                    label: 'Blog',
                    onPressed: () => _scrollTo(_blogKey),
                  ),
                  _NavAction(
                    label: 'Contacto',
                    onPressed: () => _scrollTo(_ctaKey),
                    isPrimary: true,
                  ),
                ],
              ),
            ),
          ),
      ],
      body: Container(
        color: const Color(0xFFF8F9FA),
        child: ListView(
          controller: _scrollCtrl,
          padding: EdgeInsets.zero,
          children: [
            const HeroAnimatedSection(),
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
            _FooterSection(
              key: _footerKey,
              onHomeTap: _scrollToTop,
              onServicesTap: () => _scrollTo(_servicesKey),
              onProjectsTap: () => Navigator.pushNamed(context, '/visor'),
              onBlogTap: () => _scrollTo(_blogKey),
              onContactTap: () => _scrollTo(_ctaKey),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavAction extends StatelessWidget {
  const _NavAction({
    required this.label,
    required this.onPressed,
    this.isPrimary = false,
  });

  final String label;
  final VoidCallback onPressed;
  final bool isPrimary;

  @override
  Widget build(BuildContext context) {
    final baseStyle = Theme.of(context).textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w600,
          letterSpacing: 0.3,
        );
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: TextButton(
        onPressed: onPressed,
        style: ButtonStyle(
          padding: MaterialStateProperty.all(
            const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          ),
          textStyle: MaterialStateProperty.all(baseStyle),
          foregroundColor: MaterialStateProperty.resolveWith(
            (states) {
              if (states.contains(MaterialState.hovered) || states.contains(MaterialState.focused)) {
                return Colors.white;
              }
              return Colors.white.withOpacity(0.92);
            },
          ),
          backgroundColor: MaterialStateProperty.resolveWith((states) {
            if (states.contains(MaterialState.pressed)) {
              return Brand.secondary.withOpacity(0.28);
            }
            if (states.contains(MaterialState.hovered) || states.contains(MaterialState.focused)) {
              return Brand.secondary.withOpacity(0.22);
            }
            return isPrimary ? Colors.white.withOpacity(0.16) : Colors.transparent;
          }),
          overlayColor: MaterialStateProperty.resolveWith((states) {
            if (states.contains(MaterialState.pressed)) {
              return Brand.secondary.withOpacity(0.3);
            }
            if (states.contains(MaterialState.hovered)) {
              return Brand.secondary.withOpacity(0.22);
            }
            return Colors.transparent;
          }),
          shape: MaterialStateProperty.all(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
          ),
        ),
        child: Text(label),
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
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
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
            if (icon != null) const SizedBox(height: 10),
            Text(
              title,
              textAlign: TextAlign.center,
              style: t.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: primary,
              ),
            ),
            if (subtitle != null) const SizedBox(height: 6),
            if (subtitle != null)
              Text(
                subtitle!,
                textAlign: TextAlign.center,
                style: t.bodyMedium?.copyWith(
                  color: Colors.grey.shade800,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// CARRUSEL PRINCIPAL
// ---------------------------------------------------------------------------

class _CarouselSection extends StatelessWidget {
  const _CarouselSection({
    required this.carouselStream,
  });

  final Stream<List<CarouselItem>> carouselStream;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.zero,
      child: StreamBuilder<List<CarouselItem>>(
        stream: carouselStream,
        builder: (context, snapshot) {
          final items = snapshot.data;
          if (items != null && items.isNotEmpty) {
            return _CarouselSlider(
              key: const ValueKey('carousel-loaded'),
              items: items,
            );
          }
          return const HeroAnimatedSection();
        },
      ),
    );
  }
}

class _CarouselPlaceholder extends StatelessWidget {
  const _CarouselPlaceholder.loading({super.key}) : _isLoading = true;
  const _CarouselPlaceholder.fallback({super.key}) : _isLoading = false;

  final bool _isLoading;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final height = constraints.maxWidth >= 900 ? 420.0 : 300.0;
        return Column(
          children: [
            SizedBox(
              height: height,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(22),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Brand.primary.withOpacity(0.95),
                        Brand.secondary.withOpacity(0.9),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Align(
                        alignment: Alignment.topRight,
                        child: Opacity(
                          opacity: 0.12,
                          child: Icon(
                            Icons.public,
                            size: height * 0.7,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'GEODOS',
                              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 1.6,
                                  ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              _isLoading
                                  ? 'Preparando contenidos institucionales...'
                                  : 'Consultoría ambiental y territorial con datos confiables.',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    color: Colors.white.withOpacity(0.9),
                                    fontWeight: FontWeight.w500,
                                  ),
                            ),
                            const SizedBox(height: 20),
                            if (_isLoading)
                              Row(
                                children: [
                                  SizedBox(
                                    height: 22,
                                    width: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Brand.accent.withOpacity(0.95),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    'Cargando carrusel',
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                          color: Colors.white.withOpacity(0.85),
                                        ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(3, (i) {
                return Container(
                  width: i == 0 ? 14 : 8,
                  height: i == 0 ? 14 : 8,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: i == 0
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

class _CarouselSlider extends StatefulWidget {
  const _CarouselSlider({
    Key? key,
    required this.items,
  }) : super(key: key);

  final List<CarouselItem> items;

  @override
  State<_CarouselSlider> createState() => _CarouselSliderState();
}


class _CarouselSliderState extends State<_CarouselSlider> {
  late final PageController _carouselCtrl;
  Timer? _autoTimer;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _carouselCtrl = PageController(viewportFraction: 0.95);
    _restartAutoPlay();
  }

  @override
  void didUpdateWidget(covariant _CarouselSlider oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.items.length != oldWidget.items.length && _index >= widget.items.length) {
      setState(() => _index = 0);
      if (_carouselCtrl.hasClients) {
        _carouselCtrl.jumpToPage(0);
      }
    }
    if (widget.items.length != oldWidget.items.length) {
      _restartAutoPlay();
    }
  }

  @override
  void dispose() {
    _autoTimer?.cancel();
    _carouselCtrl.dispose();
    super.dispose();
  }

  void _restartAutoPlay() {
    _autoTimer?.cancel();
    if (widget.items.length <= 1) return;
    _autoTimer = Timer.periodic(const Duration(seconds: 7), (_) {
      if (!mounted || widget.items.isEmpty || !_carouselCtrl.hasClients) return;
      final nextIndex = _index + 1 >= widget.items.length ? 0 : _index + 1;
      _carouselCtrl.animateToPage(
        nextIndex,
        duration: const Duration(milliseconds: 550),
        curve: Curves.easeInOut,
      );
    });
  }

  Future<void> _handleTap(CarouselItem item) async {
    final link = item.linkUrl?.trim();
    if (link == null || link.isEmpty) return;
    final uri = Uri.tryParse(link);
    if (uri == null) return;
    final success = await launchUrl(uri, mode: LaunchMode.platformDefault);
    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo abrir el enlace.')),
      );
    }
  }

  void _goTo(int index) {
    if (widget.items.isEmpty) return;
    final target = index.clamp(0, widget.items.length - 1);
    _carouselCtrl.animateToPage(
      target,
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeInOut,
    );
    _restartAutoPlay();
  }

  @override
  Widget build(BuildContext context) {
    final showNav = widget.items.length > 1;
    return LayoutBuilder(
      builder: (context, constraints) {
        final height = constraints.maxWidth >= 900 ? 420.0 : 300.0;
        return Column(
          children: [
            SizedBox(
              height: height,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  PageView.builder(
                    controller: _carouselCtrl,
                    itemCount: widget.items.length,
                    onPageChanged: (i) {
                      setState(() => _index = i);
                      _restartAutoPlay();
                    },
                    itemBuilder: (context, index) {
                      final item = widget.items[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(22),
                          onTap: item.linkUrl == null ? null : () => _handleTap(item),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(22),
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                Image.network(
                                  item.imageUrl,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      color: Colors.grey.shade200,
                                      alignment: Alignment.center,
                                      child: const Icon(Icons.broken_image_outlined),
                                    );
                                  },
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
                                ),
                                DecoratedBox(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Brand.primary.withOpacity(0.14),
                                        Brand.secondary.withOpacity(0.22),
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                  ),
                                ),
                                if (item.title != null || item.linkUrl != null)
                                  Align(
                                    alignment: Alignment.bottomCenter,
                                    child: Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          begin: Alignment.topCenter,
                                          end: Alignment.bottomCenter,
                                          colors: [
                                            Colors.transparent,
                                            Brand.primary.withOpacity(0.55),
                                            Brand.secondary.withOpacity(0.7),
                                          ],
                                        ),
                                      ),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          if (item.title != null)
                                            Text(
                                              item.title!,
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .titleLarge
                                                  ?.copyWith(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                            ),
                                          if (item.linkUrl != null) ...[
                                            const SizedBox(height: 8),
                                            FilledButton(
                                              style: FilledButton.styleFrom(
                                                backgroundColor: Colors.white,
                                                foregroundColor:
                                                    Theme.of(context).colorScheme.primary,
                                              ),
                                              onPressed: () => _handleTap(item),
                                              child: const Text('Ver más'),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  if (showNav)
                    Positioned(
                      left: 6,
                      child: _NavButton(
                        icon: Icons.chevron_left,
                        onPressed: _index > 0 ? () => _goTo(_index - 1) : null,
                      ),
                    ),
                  if (showNav)
                    Positioned(
                      right: 6,
                      child: _NavButton(
                        icon: Icons.chevron_right,
                        onPressed: _index < widget.items.length - 1
                            ? () => _goTo(_index + 1)
                            : null,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(widget.items.length, (i) {
                final selected = i == _index;
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
                    imageAsset: 'assets/services/impacto_ambiental.png',
                  ),
                  _ServiceCard(
                    icon: Icons.map,
                    title: 'Ordenación del Territorio y Urbanismo',
                    subtitle: 'Planes, informes y apoyo técnico a la planificación territorial y urbanística.',
                    imageAsset: 'assets/services/ordenacion_urbanismo.png',
                  ),
                  _ServiceCard(
                    icon: Icons.terrain,
                    title: 'Estudios de Paisaje',
                    subtitle: 'Análisis visual y paisajístico para integración y mejora del entorno.',
                    imageAsset: 'assets/services/estudios_paisaje.png',
                  ),
                  _ServiceCard(
                    icon: Icons.account_balance,
                    title: 'Patrimonio y Geodiversidad',
                    subtitle: 'Identificación, valoración y divulgación de patrimonio natural y cultural.',
                    imageAsset: 'assets/services/patrimonio_geodiversidad.png',
                  ),
                  _ServiceCard(
                    icon: Icons.spatial_tracking,
                    title: 'Sistemas de Información Geográfica (SIG)',
                    subtitle: 'Modelización espacial, cartografía avanzada y cuadros de mando geográficos.',
                    imageAsset: 'assets/services/sig_geoespacial.png',
                  ),
                  _ServiceCard(
                    icon: Icons.analytics,
                    title: 'Geomarketing y análisis socioterritorial',
                    subtitle: 'Apoyo a la toma de decisiones en localización, movilidad y demografía.',
                    imageAsset: 'assets/services/geomarketing.png',
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
  final String imageAsset;

  const _ServiceCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.imageAsset,
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
        child: Stack(
          children: [
            Positioned.fill(
              child: Image.asset(
                imageAsset,
                fit: BoxFit.cover,
                alignment: Alignment.center,
              ),
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFFE8F2F5).withOpacity(0.85),
                      const Color(0xFFD6E8F1).withOpacity(0.7),
                      const Color(0xFFC5DDEA).withOpacity(0.55),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
            ),
            const Positioned.fill(child: _CardTexture()),
            Column(
              children: [
                Container(
                  height: 98,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Theme.of(context).colorScheme.primary.withOpacity(0.2),
                        Theme.of(context).colorScheme.primary.withOpacity(0.06),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Stack(
                    children: [
                      Align(
                        alignment: Alignment.topRight,
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Icon(
                            icon,
                            size: 54,
                            color: Colors.white.withOpacity(0.18),
                          ),
                        ),
                      ),
                      Center(
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.75),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            icon,
                            size: 28,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ),
                    ],
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
                        style: t.bodySmall?.copyWith(color: Colors.grey.shade700),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CardTexture extends StatelessWidget {
  const _CardTexture();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DotPainter(
        color: Theme.of(context).colorScheme.primary.withOpacity(0.08),
      ),
    );
  }
}

class _DotPainter extends CustomPainter {
  _DotPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    const spacing = 24.0;
    const radius = 1.8;
    for (var y = spacing / 2; y < size.height; y += spacing) {
      for (var x = spacing / 2; x < size.width; x += spacing) {
        canvas.drawCircle(Offset(x, y), radius, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DotPainter oldDelegate) => oldDelegate.color != color;
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
                      borderRadius: BorderRadius.circular(18),
                      child: AspectRatio(
                        aspectRatio: 4 / 3,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.network(
                              officeImageUrl,
                              fit: BoxFit.cover,
                            ),
                            DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.transparent,
                                    Colors.black.withOpacity(0.35),
                                  ],
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                ),
                              ),
                            ),
                            Positioned(
                              left: 16,
                              bottom: 16,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.85),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  'Equipo GEODOS',
                                  style: t.labelMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                  final text = Expanded(
                    flex: 2,
                    child: Padding(
                      padding: EdgeInsets.only(
                        left: isWide ? 32 : 0,
                        top: isWide ? 0 : 20,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Geodos es una consultora especializada en estudios medioambientales, manejo SIG, ordenación del territorio, patrimonio, paisaje, urbanismo y divulgación. Trabajamos con administraciones públicas, empresas y entidades sociales para integrar la variable espacial en la toma de decisiones.',
                            style: t.bodyMedium?.copyWith(height: 1.6),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Desde Canarias, pero con vocación nacional e internacional, combinamos experiencia técnica y capacidad de comunicación para que los resultados sean comprensibles y útiles para todos los agentes implicados.',
                            style: t.bodyMedium?.copyWith(height: 1.6),
                          ),
                        ],
                      ),
                    ),
                  );
                  final content = isWide
                      ? Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [image, text],
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [image, text],
                        );
                  return Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: content,
                    ),
                  );
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
                        const SizedBox(height: 16),
                        Align(
                          alignment: Alignment.center,
                          child: TextButton.icon(
                            onPressed: () => Navigator.pushNamed(context, '/blog'),
                            icon: const Icon(Icons.open_in_new),
                            label: const Text('Ver todas las noticias'),
                          ),
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
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 720;
              final textColumn = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '¿Hablamos de tu territorio?',
                    softWrap: true,
                    textAlign: TextAlign.left,
                    overflow: TextOverflow.visible,
                    style: t.headlineSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Cuéntanos tu proyecto y te ayudamos a definir la mejor solución técnica y ambiental.',
                    softWrap: true,
                    textAlign: TextAlign.left,
                    overflow: TextOverflow.visible,
                    style: t.bodyMedium?.copyWith(
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                ],
              );
              final actions = Wrap(
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
              );

              if (isNarrow) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    textColumn,
                    const SizedBox(height: 16),
                    actions,
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(child: textColumn),
                  const SizedBox(width: 24),
                  actions,
                ],
              );
            },
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
  const _FooterSection({
    super.key,
    required this.onHomeTap,
    required this.onServicesTap,
    required this.onProjectsTap,
    required this.onBlogTap,
    required this.onContactTap,
  });

  final VoidCallback onHomeTap;
  final VoidCallback onServicesTap;
  final VoidCallback onProjectsTap;
  final VoidCallback onBlogTap;
  final VoidCallback onContactTap;

  Future<void> _openExternalLink(BuildContext context, String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    final ok = await launchUrl(uri, mode: LaunchMode.platformDefault);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo abrir el enlace.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Container(
      color: const Color(0xFF0B1F26),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 48,
                runSpacing: 24,
                children: [
                  SizedBox(
                    width: 250,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'GEODOS',
                          style: t.titleMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Consultoría ambiental y SIG',
                          style: t.bodySmall?.copyWith(color: Colors.white70),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Contacto: info@geodos.es',
                          style: t.bodySmall?.copyWith(color: Colors.white70),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Ubicación: Canarias · España',
                          style: t.bodySmall?.copyWith(color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                  _FooterColumn(
                    title: 'Navegación',
                    children: [
                      _FooterAction(label: 'Inicio', onTap: onHomeTap),
                      _FooterAction(label: 'Servicios', onTap: onServicesTap),
                      _FooterAction(label: 'Proyectos', onTap: onProjectsTap),
                      _FooterAction(label: 'Blog', onTap: onBlogTap),
                      _FooterAction(label: 'Contacto', onTap: onContactTap),
                    ],
                  ),
                  _FooterColumn(
                    title: 'Legal',
                    children: const [
                      _FooterLink(label: 'Política de privacidad', route: '/privacy'),
                      _FooterLink(label: 'Cookies', route: '/cookies'),
                      _FooterLink(label: 'Términos de uso', route: '/terms'),
                    ],
                  ),
                  _FooterColumn(
                    title: 'Síguenos',
                    children: [
                      _FooterIconLink(
                        label: 'LinkedIn',
                        icon: Icons.business_center_outlined,
                        url: 'https://www.linkedin.com',
                        onLaunch: _openExternalLink,
                      ),
                      _FooterIconLink(
                        label: 'X (Twitter)',
                        icon: Icons.alternate_email_outlined,
                        url: 'https://x.com',
                        onLaunch: _openExternalLink,
                      ),
                      _FooterIconLink(
                        label: 'Instagram',
                        icon: Icons.camera_alt_outlined,
                        url: 'https://www.instagram.com',
                        onLaunch: _openExternalLink,
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Divider(color: Colors.white24),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '© ${DateTime.now().year} GEODOS · Consultoría ambiental y territorial',
                    style: t.bodySmall?.copyWith(color: Colors.white70),
                  ),
                  Text(
                    'Compromiso con la privacidad y la sostenibilidad',
                    style: t.bodySmall?.copyWith(color: Colors.white70),
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

class _FooterColumn extends StatelessWidget {
  const _FooterColumn({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return SizedBox(
      width: 180,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: t.titleSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}

class _FooterAction extends StatelessWidget {
  const _FooterAction({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white70),
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
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white70),
        ),
      ),
    );
  }
}

class _FooterIconLink extends StatelessWidget {
  const _FooterIconLink({
    required this.label,
    required this.icon,
    required this.url,
    required this.onLaunch,
  });

  final String label;
  final IconData icon;
  final String url;
  final Future<void> Function(BuildContext context, String url) onLaunch;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onLaunch(context, url),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: Colors.white70),
            const SizedBox(width: 8),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }
}
