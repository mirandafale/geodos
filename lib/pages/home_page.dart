import 'package:flutter/material.dart';
import 'package:geodos/brand/brand.dart';

import '../widgets/app_drawer.dart';
import '../widgets/contact_form.dart';
import '../widgets/visor_embed.dart';

/// Página de inicio renovada con foco corporativo y secciones claras.
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _aboutKey = GlobalKey();
  final _workflowKey = GlobalKey();
  final _visorKey = GlobalKey();
  final _contactKey = GlobalKey();

  void _scrollTo(GlobalKey key) {
    final ctx = key.currentContext;
    if (ctx == null) return;

    Scrollable.ensureVisible(
      ctx,
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeInOut,
      alignment: 0.08,
    );
  }

  ButtonStyle get _primaryButtonStyle => FilledButton.styleFrom(
        backgroundColor: Brand.primary,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(fontWeight: FontWeight.w700),
      );

  ButtonStyle get _secondaryButtonStyle => OutlinedButton.styleFrom(
        foregroundColor: Brand.primary,
        side: const BorderSide(color: Brand.primary, width: 1.4),
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(fontWeight: FontWeight.w700),
      );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Colors.white),
        flexibleSpace: Container(decoration: const BoxDecoration(gradient: Brand.appBarGradient)),
        title: Text(
          'GEODOS',
          style: theme.textTheme.titleLarge?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.1,
          ),
        ),
        actions: [
          _NavButton(label: 'Quiénes somos', onTap: () => _scrollTo(_aboutKey)),
          _NavButton(label: 'Cómo trabajamos', onTap: () => _scrollTo(_workflowKey)),
          _NavButton(label: 'Visor', onTap: () => _scrollTo(_visorKey)),
          _NavButton(label: 'Contacto', onTap: () => _scrollTo(_contactKey)),
          const SizedBox(width: 16),
        ],
      ),
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          _HeroSection(
            primaryStyle: _primaryButtonStyle,
            secondaryStyle: _secondaryButtonStyle,
            onExploreTap: () => Navigator.pushNamed(context, '/visor'),
            onContactTap: () => _scrollTo(_contactKey),
          ),
          _AboutSection(key: _aboutKey),
          _WorkflowSection(key: _workflowKey),
          _VisorPreviewSection(key: _visorKey),
          _ContactSection(
            key: _contactKey,
            primaryStyle: _primaryButtonStyle,
            secondaryStyle: _secondaryButtonStyle,
          ),
          const _FooterSection(),
        ],
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _NavButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onTap,
      child: Text(
        label,
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _SectionShell extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;

  const _SectionShell({required this.child, this.padding = const EdgeInsets.symmetric(horizontal: 24, vertical: 32)});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: padding,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: child,
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SectionHeader({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: textTheme.headlineSmall?.copyWith(
            color: Brand.primary,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          style: textTheme.bodyLarge?.copyWith(color: Colors.grey.shade800, height: 1.4),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// HERO
// ---------------------------------------------------------------------------

class _HeroSection extends StatelessWidget {
  final ButtonStyle primaryStyle;
  final ButtonStyle secondaryStyle;
  final VoidCallback onExploreTap;
  final VoidCallback onContactTap;

  const _HeroSection({
    required this.primaryStyle,
    required this.secondaryStyle,
    required this.onExploreTap,
    required this.onContactTap,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.fromLTRB(28, 56, 28, 64),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Brand.primary, Brand.secondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1120),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 900;
              final heroCopy = _HeroCopy(
                textTheme: textTheme,
                onContactTap: onContactTap,
                onExploreTap: onExploreTap,
                primaryStyle: primaryStyle,
                secondaryStyle: secondaryStyle,
              );

              if (isWide) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(flex: 3, child: heroCopy),
                    const SizedBox(width: 28),
                    const Expanded(flex: 2, child: _HeroCard()),
                  ],
                );
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  heroCopy,
                  const SizedBox(height: 20),
                  const _HeroCard(),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _HeroCopy extends StatelessWidget {
  final TextTheme textTheme;
  final ButtonStyle primaryStyle;
  final ButtonStyle secondaryStyle;
  final VoidCallback onExploreTap;
  final VoidCallback onContactTap;

  const _HeroCopy({
    required this.textTheme,
    required this.primaryStyle,
    required this.secondaryStyle,
    required this.onExploreTap,
    required this.onContactTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Decisiones territoriales con datos, rigor y visión ambiental.',
          style: textTheme.headlineMedium?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            height: 1.15,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'GEODOS integra consultoría ambiental, planificación y sistemas de información geográfica para impulsar proyectos sostenibles y bien fundamentados.',
          style: textTheme.bodyLarge?.copyWith(color: Colors.white.withOpacity(0.92), height: 1.5),
        ),
        const SizedBox(height: 24),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            FilledButton(
              style: primaryStyle,
              onPressed: onExploreTap,
              child: const Text('Explorar visor'),
            ),
            OutlinedButton(
              style: secondaryStyle.copyWith(
                foregroundColor: MaterialStateProperty.all(Colors.white),
                side: const MaterialStatePropertyAll(BorderSide(color: Colors.white, width: 1.4)),
              ),
              onPressed: onContactTap,
              child: const Text('Contactar'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: const [
            _Pill(text: 'Consultoría ambiental'),
            _Pill(text: 'SIG y cartografía'),
            _Pill(text: 'Planificación territorial'),
          ],
        ),
      ],
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Card(
      color: Colors.white,
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Brand.primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.public, color: Brand.primary, size: 32),
            ),
            const SizedBox(height: 16),
            Text(
              'Acompañamos a administraciones y empresas en todo el ciclo del proyecto, desde el diagnóstico hasta la implementación.',
              style: textTheme.bodyMedium?.copyWith(height: 1.5),
            ),
            const SizedBox(height: 18),
            Row(
              children: const [
                _Metric(title: '150+', subtitle: 'Proyectos territoriales'),
                SizedBox(width: 12),
                _Metric(title: '15 años', subtitle: 'Expertos en SIG y medio ambiente'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final String text;

  const _Pill({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.3)),
      ),
      child: Text(
        text,
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  final String title;
  final String subtitle;

  const _Metric({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Brand.mist,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: textTheme.titleLarge?.copyWith(
                color: Brand.primary,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: textTheme.bodyMedium?.copyWith(color: Colors.grey.shade800, height: 1.4),
            ),
          ],
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
    return _SectionShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          _SectionHeader(
            title: 'Quiénes somos',
            subtitle: 'GEODOS es un equipo multidisciplinar especializado en territorio, medio ambiente y datos geoespaciales. Colaboramos con administraciones, ingenierías y consultoras para diseñar soluciones sólidas y accionables.',
          ),
          SizedBox(height: 18),
          _AboutHighlights(),
        ],
      ),
    );
  }
}

class _AboutHighlights extends StatelessWidget {
  const _AboutHighlights();

  @override
  Widget build(BuildContext context) {
    final items = [
      'Evaluaciones ambientales con enfoque estratégico.',
      'Planificación y ordenación del territorio apoyada en datos.',
      'Cartografía y dashboards para comunicar con claridad.',
      'Metodologías participativas y acompañamiento en la implementación.',
    ];

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ...items.map(
              (item) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.check_circle, color: Brand.secondary, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        item,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.5),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
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
    return _SectionShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeader(
            title: 'Cómo trabajamos',
            subtitle: 'Metodología clara para acompañarte desde la detección de necesidades hasta la entrega y el seguimiento.',
          ),
          const SizedBox(height: 22),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: const [
              _WorkflowCard(
                icon: Icons.explore,
                title: '1. Descubrimiento',
                description: 'Reunimos a los equipos, analizamos el contexto y definimos objetivos comunes con enfoque ambiental.',
              ),
              _WorkflowCard(
                icon: Icons.analytics_outlined,
                title: '2. Análisis y datos',
                description: 'Modelizamos el territorio con SIG, teledetección y trabajo de campo para obtener insights accionables.',
              ),
              _WorkflowCard(
                icon: Icons.design_services,
                title: '3. Propuesta',
                description: 'Diseñamos alternativas, visualizamos escenarios y priorizamos junto a los decisores.',
              ),
              _WorkflowCard(
                icon: Icons.check_circle_outline,
                title: '4. Entrega y seguimiento',
                description: 'Implementamos, formamos equipos y desplegamos indicadores para medir el impacto.',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _WorkflowCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _WorkflowCard({required this.icon, required this.title, required this.description});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return SizedBox(
      width: 250,
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Brand.secondary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: Brand.secondary, size: 28),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Text(
                description,
                style: textTheme.bodyMedium?.copyWith(height: 1.45, color: Colors.grey.shade800),
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
    return _SectionShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeader(
            title: 'Visor geoespacial',
            subtitle: 'Explora proyectos georreferenciados y filtra por ámbito desde un visor rápido y accesible.',
          ),
          const SizedBox(height: 18),
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text('Vista previa interactiva', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                  SizedBox(height: 12),
                  VisorEmbed(startExpanded: false),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// CONTACTO
// ---------------------------------------------------------------------------

class _ContactSection extends StatelessWidget {
  final ButtonStyle primaryStyle;
  final ButtonStyle secondaryStyle;

  const _ContactSection({super.key, required this.primaryStyle, required this.secondaryStyle});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return _SectionShell(
      child: Card(
        elevation: 5,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 860;
              final content = [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Conversemos sobre tu proyecto',
                        style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800, color: Brand.primary),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Cuéntanos tus retos y diseñaremos la mejor manera de acompañarte con soluciones técnicas, ambientales y geoespaciales.',
                        style: textTheme.bodyLarge?.copyWith(height: 1.5),
                      ),
                      const SizedBox(height: 18),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          FilledButton(
                            style: primaryStyle,
                            onPressed: () => Navigator.pushNamed(context, '/visor'),
                            child: const Text('Ver proyectos'),
                          ),
                          OutlinedButton(
                            style: secondaryStyle,
                            onPressed: () => Navigator.pushNamed(context, '/contact'),
                            child: const Text('Contactar'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 22, height: 22),
                const Expanded(
                  child: ContactForm(),
                ),
              ];

              if (isWide) return Row(crossAxisAlignment: CrossAxisAlignment.start, children: content);
              return Column(crossAxisAlignment: CrossAxisAlignment.start, children: content);
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
  const _FooterSection();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      color: const Color(0xFF0B1F26),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 22),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                '© ${DateTime.now().year} GEODOS · Consultoría ambiental y territorial',
                style: textTheme.bodySmall?.copyWith(color: Colors.white70),
              ),
              Wrap(
                spacing: 16,
                children: const [
                  _FooterLink(label: 'Aviso legal', route: '/about'),
                  _FooterLink(label: 'Política de privacidad', route: '/privacy'),
                  _FooterLink(label: 'Política de cookies', route: '/cookies'),
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
