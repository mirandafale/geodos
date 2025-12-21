import 'package:flutter/material.dart';
import 'package:geodos/brand/brand.dart';

// Menú lateral con las diferentes opciones de navegación.
import '../widgets/app_drawer.dart';
// Visor incrustado para mostrar los proyectos georreferenciados.
import '../widgets/visor_embed.dart';
// Formulario de contacto reutilizable.
import '../widgets/contact_form.dart';

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
  final _aboutKey = GlobalKey();
  final _workflowKey = GlobalKey();
  final _visorKey = GlobalKey();
  final _contactKey = GlobalKey();
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
            onPressed: () => _scrollTo(_aboutKey),
            child: const Text('Quiénes somos', style: TextStyle(color: Colors.white)),
          ),
          TextButton(
            onPressed: () => _scrollTo(_workflowKey),
            child: const Text('Cómo trabajamos', style: TextStyle(color: Colors.white)),
          ),
          TextButton(
            onPressed: () => _scrollTo(_visorKey),
            child: const Text('Visor', style: TextStyle(color: Colors.white)),
          ),
          TextButton(
            onPressed: () => _scrollTo(_contactKey),
            child: const Text('Contacto', style: TextStyle(color: Colors.white)),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: ListView(
        controller: _scrollCtrl,
        padding: EdgeInsets.zero,
        children: [
          _HeroSection(
            onExplore: () => Navigator.pushNamed(context, '/visor'),
            onContact: () => _scrollTo(_contactKey),
          ),
          const SizedBox(height: 40),
          _AboutSection(key: _aboutKey),
          const SizedBox(height: 32),
          _WorkflowSection(key: _workflowKey),
          const SizedBox(height: 32),
          _VisorPreviewSection(key: _visorKey),
          const SizedBox(height: 32),
          _ContactSection(key: _contactKey),
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
    final primary = Brand.primary;

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      color: Colors.white,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          border: Border(
            left: BorderSide(
              color: primary,
              width: 5,
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
                  size: 24,
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
                      color: Brand.ink,
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
  final VoidCallback onExplore;
  final VoidCallback onContact;

  const _HeroSection({
    required this.onExplore,
    required this.onContact,
  });

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(32, 48, 32, 64),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Brand.primary, Brand.secondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isCompact = constraints.maxWidth < 900;
              final content = Column(
                crossAxisAlignment:
                    isCompact ? CrossAxisAlignment.center : CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.14),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white24),
                    ),
                    child: Text(
                      'Consultoría ambiental, territorial y SIG',
                      style: t.labelLarge?.copyWith(color: Colors.white),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Decisiones estratégicas con rigor territorial',
                    style: t.displaySmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      height: 1.1,
                    ),
                    textAlign: isCompact ? TextAlign.center : TextAlign.start,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Integramos datos geoespaciales, evaluación ambiental y planificación para que instituciones y empresas actúen con confianza y visión de futuro.',
                    style: t.titleMedium?.copyWith(
                      color: Colors.white.withOpacity(0.92),
                      height: 1.4,
                    ),
                    textAlign: isCompact ? TextAlign.center : TextAlign.start,
                  ),
                  const SizedBox(height: 26),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      FilledButton.icon(
                        onPressed: onExplore,
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Brand.ink,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        icon: const Icon(Icons.explore),
                        label: const Text('Explorar visor'),
                      ),
                      OutlinedButton.icon(
                        onPressed: onContact,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Colors.white),
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        icon: const Icon(Icons.chat),
                        label: const Text('Contactar'),
                      ),
                    ],
                  ),
                ],
              );

              final image = Container(
                height: 280,
                margin: EdgeInsets.only(left: isCompact ? 0 : 32, top: isCompact ? 32 : 0),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white24),
                  image: const DecorationImage(
                    image: NetworkImage(
                      'https://images.pexels.com/photos/1181467/pexels-photo-1181467.jpeg?auto=compress&cs=tinysrgb&w=1600',
                    ),
                    fit: BoxFit.cover,
                    alignment: Alignment.center,
                  ),
                ),
                padding: const EdgeInsets.all(18),
                child: Align(
                  alignment: Alignment.bottomLeft,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.45),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.shield_outlined, color: Colors.white, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          'Proyectos territoriales con impacto medible',
                          style: t.bodySmall?.copyWith(color: Colors.white, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ),
              );

              if (isCompact) {
                return Column(
                  children: [content, image],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(child: content),
                  Expanded(child: image),
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
// CÓMO TRABAJAMOS
// ---------------------------------------------------------------------------

class _WorkflowSection extends StatelessWidget {
  const _WorkflowSection({super.key});

  @override
  Widget build(BuildContext context) {
    final steps = const [
      _WorkflowStep(
        icon: Icons.search,
        title: 'Descubrimiento',
        description: 'Diagnóstico técnico, normativa y objetivos con los equipos implicados.',
      ),
      _WorkflowStep(
        icon: Icons.data_usage,
        title: 'Análisis y modelos',
        description: 'Procesamos datos geoespaciales, escenarios y riesgos para tomar decisiones.',
      ),
      _WorkflowStep(
        icon: Icons.psychology_alt,
        title: 'Propuesta ejecutable',
        description: 'Definimos alternativas, indicadores y visualizaciones claras para stakeholders.',
      ),
      _WorkflowStep(
        icon: Icons.task_alt,
        title: 'Entrega y seguimiento',
        description: 'Implantación, capacitación y mejora continua con indicadores medibles.',
      ),
    ];

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
                subtitle: 'Metodología clara de principio a fin para proyectos territoriales de alto impacto.',
                icon: Icons.route,
              ),
              const SizedBox(height: 24),
              Wrap(
                spacing: 16,
                runSpacing: 16,
                alignment: WrapAlignment.center,
                children: steps,
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
      width: 250,
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Brand.primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 24, color: Brand.primary),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: t.titleMedium?.copyWith(fontWeight: FontWeight.w700, color: Brand.ink),
              ),
              const SizedBox(height: 6),
              Text(
                description,
                style: t.bodySmall?.copyWith(height: 1.45),
              ),
            ],
          ),
        ),
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
        'https://images.pexels.com/photos/3137064/pexels-photo-3137064.jpeg?auto=compress&cs=tinysrgb&w=1600';
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1100),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const _SectionHeader(
                title: 'Quiénes somos',
                subtitle: 'Equipo multidisciplinar en evaluación ambiental, planificación territorial y análisis SIG.',
                icon: Icons.people_outline,
              ),
              const SizedBox(height: 24),
              Card(
                elevation: 5,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: LayoutBuilder(
                    builder: (ctx, constraints) {
                      final isWide = constraints.maxWidth > 900;
                      final bullets = [
                        'Especialistas en evaluación ambiental estratégica y proyectos singulares.',
                        'Expertos en datos geoespaciales, SIG y visualización para la toma de decisiones.',
                        'Acompañamiento integral: diagnóstico, diseño, comunicación y formación.',
                      ];

                      final text = Expanded(
                        flex: 2,
                        child: Column(
                          crossAxisAlignment:
                              isWide ? CrossAxisAlignment.start : CrossAxisAlignment.center,
                          children: [
                            Text(
                              'Conectamos ciencia, territorio y estrategia.',
                              style: t.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: Brand.ink,
                              ),
                              textAlign: isWide ? TextAlign.start : TextAlign.center,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'GEODOS colabora con administraciones, empresas y organizaciones sociales para activar decisiones sostenibles con datos claros y participación informada.',
                              style: t.bodyMedium?.copyWith(height: 1.45),
                              textAlign: isWide ? TextAlign.start : TextAlign.center,
                            ),
                            const SizedBox(height: 12),
                            ...bullets.map(
                              (b) => Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Icon(Icons.check_circle, color: Brand.secondary, size: 20),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        b,
                                        style: t.bodyMedium?.copyWith(height: 1.4),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      );

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

                      if (isWide) {
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [text, const SizedBox(width: 24), image],
                        );
                      }
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [text, const SizedBox(height: 20), image],
                      );
                    },
                  ),
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
// VISOR PREVIEW
// ---------------------------------------------------------------------------

class _VisorPreviewSection extends StatelessWidget {
  const _VisorPreviewSection({super.key});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1100),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const _SectionHeader(
                title: 'Visor geográfico',
                subtitle: 'Explora proyectos georreferenciados y filtra por temática, año o ubicación.',
                icon: Icons.map_outlined,
              ),
              const SizedBox(height: 20),
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Vista previa interactiva',
                        style: t.titleMedium?.copyWith(fontWeight: FontWeight.w700, color: Brand.ink),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Analiza iniciativas ambientales, territoriales y de patrimonio en un visor construido con datos abiertos y propios.',
                        style: t.bodyMedium?.copyWith(height: 1.45),
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 12,
                        runSpacing: 8,
                        children: [
                          FilledButton.icon(
                            onPressed: () => Navigator.pushNamed(context, '/visor'),
                            style: FilledButton.styleFrom(
                              backgroundColor: Brand.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                            icon: const Icon(Icons.explore_outlined),
                            label: const Text('Abrir visor completo'),
                          ),
                          OutlinedButton.icon(
                            onPressed: () => Navigator.pushNamed(context, '/visor'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Brand.primary,
                              side: const BorderSide(color: Brand.primary),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                            icon: const Icon(Icons.visibility_outlined),
                            label: const Text('Ver proyectos destacados'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: const VisorEmbed(startExpanded: false),
                      ),
                    ],
                  ),
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
// CONTACTO
// ---------------------------------------------------------------------------

class _ContactSection extends StatelessWidget {
  const _ContactSection({super.key});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: Column(
            children: [
              const _SectionHeader(
                title: 'Contacto',
                subtitle: 'Cuéntanos tu proyecto y te contactaremos pronto.',
                icon: Icons.mail_outline,
              ),
              const SizedBox(height: 20),
              Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFEFF6F9), Color(0xFFF9FBFC)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Brand.primary.withOpacity(0.08)),
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Trabajemos juntos',
                      style: t.titleLarge?.copyWith(fontWeight: FontWeight.w800, color: Brand.ink),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'El equipo revisará tu consulta y guardará la solicitud de forma segura en Firebase.',
                      style: t.bodyMedium?.copyWith(height: 1.4),
                    ),
                    const SizedBox(height: 16),
                    const ContactForm(),
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