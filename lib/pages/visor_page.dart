// visor_page.dart con filtros profesionales y visor de proyectos

import 'package:flutter/material.dart';
import 'package:geodos/brand/brand.dart';
import 'package:geodos/models/project.dart';
import 'package:geodos/services/filters_controller.dart';
import 'package:geodos/services/project_service.dart';
import 'package:geodos/widgets/contact_form.dart';
import 'package:geodos/widgets/visor_embed.dart';

class VisorPage extends StatefulWidget {
  const VisorPage({super.key});

  @override
  State<VisorPage> createState() => _VisorPageState();
}

class _VisorPageState extends State<VisorPage> {
  final filters = FiltersController.instance;
  late Future<List<int>> _yearsFuture;
  late Future<List<String>> _categoriesFuture;
  late Future<List<ProjectScope>> _scopesFuture;
  late Future<List<String>> _islandsFuture;
  final _searchCtrl = TextEditingController();
  final _scrollController = ScrollController();
  final _formAnchorKey = GlobalKey();
  bool _showScrollTop = false;

  @override
  void initState() {
    super.initState();
    _yearsFuture = ProjectService.getYears();
    _categoriesFuture = ProjectService.getCategories();
    _scopesFuture = ProjectService.getScopes();
    _islandsFuture = ProjectService.getIslands();
    _searchCtrl.text = filters.state.search;
    _scrollController.addListener(() {
      final shouldShow = _scrollController.offset > 300;
      if (shouldShow != _showScrollTop) {
        setState(() => _showScrollTop = shouldShow);
      }
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Visor de proyectos'),
        flexibleSpace: Container(decoration: const BoxDecoration(gradient: Brand.appBarGradient)),
        foregroundColor: Colors.white,
        backgroundColor: Colors.transparent,
      ),
      backgroundColor: const Color(0xFFF8F9FA),
      floatingActionButton: AnimatedScale(
        scale: _showScrollTop ? 1 : 0,
        duration: const Duration(milliseconds: 200),
        child: FloatingActionButton.small(
          onPressed: () => _scrollController.animateTo(
            0,
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeOut,
          ),
          tooltip: 'Volver arriba',
          child: const Icon(Icons.keyboard_arrow_up),
        ),
      ),
      body: SingleChildScrollView(
        controller: _scrollController,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1200),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _ResponsiveMapSection(
                        filters: filters,
                        yearsFuture: _yearsFuture,
                        categoriesFuture: _categoriesFuture,
                        scopesFuture: _scopesFuture,
                        islandsFuture: _islandsFuture,
                        searchController: _searchCtrl,
                        onTapConsulta: _scrollToForm,
                      ),
                      const SizedBox(height: 20),
                      KeyedSubtree(
                        key: _formAnchorKey,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: const [
                              BoxShadow(
                                color: Colors.black12,
                                blurRadius: 10,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                '¿Quieres que te contactemos?',
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: Brand.primary,
                                    ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Cuéntanos sobre tu proyecto o consulta, y nuestro equipo te responderá lo antes posible.',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[700]),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 18),
                              const ContactForm(originSection: 'visor'),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _scrollToForm() async {
    final context = _formAnchorKey.currentContext;
    if (context == null) return;
    await Scrollable.ensureVisible(
      context,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOut,
    );
  }
}

class _ResponsiveMapSection extends StatelessWidget {
  final FiltersController filters;
  final Future<List<int>> yearsFuture;
  final Future<List<String>> categoriesFuture;
  final Future<List<ProjectScope>> scopesFuture;
  final Future<List<String>> islandsFuture;
  final TextEditingController searchController;
  final VoidCallback onTapConsulta;

  const _ResponsiveMapSection({
    required this.filters,
    required this.yearsFuture,
    required this.categoriesFuture,
    required this.scopesFuture,
    required this.islandsFuture,
    required this.searchController,
    required this.onTapConsulta,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final viewportHeight = MediaQuery.of(context).size.height;
        final isMobile = width < 900;
        double mapHeight;

        if (width >= 1200) {
          mapHeight = (viewportHeight * 0.62).clamp(520.0, 720.0);
        } else if (width >= 900) {
          mapHeight = (viewportHeight * 0.55).clamp(460.0, 640.0);
        } else {
          mapHeight = 420;
        }

        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            boxShadow: const [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: SizedBox(
            height: mapHeight,
            width: double.infinity,
            child: Stack(
              children: [
                Positioned.fill(child: VisorEmbed(baseHeight: mapHeight)),
                if (isMobile)
                  Positioned(
                    left: 12,
                    top: 12,
                    right: 12,
                    child: _FloatingFiltersMobile(
                      filters: filters,
                      yearsFuture: yearsFuture,
                      categoriesFuture: categoriesFuture,
                      scopesFuture: scopesFuture,
                      islandsFuture: islandsFuture,
                      searchController: searchController,
                      maxHeight: mapHeight - 24,
                    ),
                  )
                else
                  Positioned(
                    left: 16,
                    top: 16,
                    child: SizedBox(
                      width: 320,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(maxHeight: mapHeight - 32),
                        child: _FloatingFiltersDesktop(
                          filters: filters,
                          yearsFuture: yearsFuture,
                          categoriesFuture: categoriesFuture,
                          scopesFuture: scopesFuture,
                          islandsFuture: islandsFuture,
                          searchController: searchController,
                        ),
                      ),
                    ),
                  ),
                Positioned(
                  right: 16,
                  bottom: 16,
                  child: FilledButton.icon(
                    onPressed: onTapConsulta,
                    icon: const Icon(Icons.arrow_downward),
                    label: const Text('Hacer consulta'),
                    style: FilledButton.styleFrom(
                      backgroundColor: Brand.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _FloatingFiltersDesktop extends StatelessWidget {
  final FiltersController filters;
  final Future<List<int>> yearsFuture;
  final Future<List<String>> categoriesFuture;
  final Future<List<ProjectScope>> scopesFuture;
  final Future<List<String>> islandsFuture;
  final TextEditingController searchController;

  const _FloatingFiltersDesktop({
    required this.filters,
    required this.yearsFuture,
    required this.categoriesFuture,
    required this.scopesFuture,
    required this.islandsFuture,
    required this.searchController,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 6,
      color: Colors.white.withOpacity(0.95),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: _FiltersContent(
          filters: filters,
          yearsFuture: yearsFuture,
          categoriesFuture: categoriesFuture,
          scopesFuture: scopesFuture,
          islandsFuture: islandsFuture,
          searchController: searchController,
        ),
      ),
    );
  }
}

class _FloatingFiltersMobile extends StatelessWidget {
  final FiltersController filters;
  final Future<List<int>> yearsFuture;
  final Future<List<String>> categoriesFuture;
  final Future<List<ProjectScope>> scopesFuture;
  final Future<List<String>> islandsFuture;
  final TextEditingController searchController;
  final double maxHeight;

  const _FloatingFiltersMobile({
    required this.filters,
    required this.yearsFuture,
    required this.categoriesFuture,
    required this.scopesFuture,
    required this.islandsFuture,
    required this.searchController,
    required this.maxHeight,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 5,
      color: Colors.white.withOpacity(0.96),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          title: const Text('Filtros'),
          tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
          childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
          collapsedShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          children: [
            ConstrainedBox(
              constraints: BoxConstraints(maxHeight: maxHeight * 0.7),
              child: SingleChildScrollView(
                child: _FiltersContent(
                  filters: filters,
                  yearsFuture: yearsFuture,
                  categoriesFuture: categoriesFuture,
                  scopesFuture: scopesFuture,
                  islandsFuture: islandsFuture,
                  searchController: searchController,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FiltersContent extends StatelessWidget {
  final FiltersController filters;
  final Future<List<int>> yearsFuture;
  final Future<List<String>> categoriesFuture;
  final Future<List<ProjectScope>> scopesFuture;
  final Future<List<String>> islandsFuture;
  final TextEditingController searchController;

  const _FiltersContent({
    required this.filters,
    required this.yearsFuture,
    required this.categoriesFuture,
    required this.scopesFuture,
    required this.islandsFuture,
    required this.searchController,
  });

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;

    return AnimatedBuilder(
      animation: filters,
      builder: (context, _) {
        final st = filters.state;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Filtros', style: t.titleMedium?.copyWith(fontWeight: FontWeight.w700, color: Brand.primary)),
            const SizedBox(height: 4),
            Text('Refina los proyectos por categoría, ámbito, isla y año.', style: t.bodySmall),
            const Divider(height: 22),
                TextFormField(
                  controller: searchController,
                  decoration: const InputDecoration(
                    labelText: 'Buscar por título o municipio',
                    prefixIcon: Icon(Icons.search),
                  ),
                  onChanged: filters.setSearch,
                ),
                const SizedBox(height: 14),
                FutureBuilder<List<String>>(
                  future: categoriesFuture,
                  builder: (context, snapshot) {
                    final items = snapshot.data ?? [];
                    return DropdownButtonFormField<String?>(
                      value: st.category,
                      decoration: const InputDecoration(labelText: 'Categoría'),
                      items: [
                        const DropdownMenuItem<String?>(value: null, child: Text('Todas')),
                        ...items.map(
                          (c) => DropdownMenuItem<String?>(value: c, child: Text(c)),
                        ),
                      ],
                      onChanged: filters.setCategory,
                    );
                  },
                ),
                const SizedBox(height: 14),
                FutureBuilder<List<ProjectScope>>(
                  future: scopesFuture,
                  builder: (context, snapshot) {
                    final scopes = snapshot.data ?? [];
                    return DropdownButtonFormField<ProjectScope?>(
                      value: st.scope,
                      decoration: const InputDecoration(labelText: 'Ámbito'),
                      items: [
                        const DropdownMenuItem<ProjectScope?>(value: null, child: Text('Todos')),
                        ...scopes.map(
                          (s) => DropdownMenuItem<ProjectScope?>(
                            value: s,
                            child: Text(_scopeLabel(s)),
                          ),
                        ),
                      ],
                      onChanged: filters.setScope,
                    );
                  },
                ),
                const SizedBox(height: 14),
                FutureBuilder<List<String>>(
                  future: islandsFuture,
                  builder: (context, snapshot) {
                    final items = snapshot.data ?? [];
                    return DropdownButtonFormField<String?>(
                      value: st.island,
                      decoration: const InputDecoration(labelText: 'Isla'),
                      items: [
                        const DropdownMenuItem<String?>(value: null, child: Text('Todas las islas')),
                        ...items.map(
                          (c) => DropdownMenuItem<String?>(value: c, child: Text(c)),
                        ),
                      ],
                      onChanged: filters.setIsland,
                    );
                  },
                ),
                const SizedBox(height: 14),
                FutureBuilder<List<int>>(
                  future: yearsFuture,
                  builder: (context, snapshot) {
                    final items = snapshot.data ?? [];
                    return DropdownButtonFormField<int?>(
                      value: st.year,
                      decoration: const InputDecoration(labelText: 'Año'),
                      items: [
                        const DropdownMenuItem<int?>(value: null, child: Text('Todos los años')),
                        ...items.map(
                          (y) => DropdownMenuItem<int?>(value: y, child: Text(y.toString())),
                        ),
                      ],
                      onChanged: filters.setYear,
                    );
                  },
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    ElevatedButton.icon(
                      onPressed: () {
                        searchController.clear();
                        filters.reset();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Brand.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                      icon: const Icon(Icons.filter_alt_off),
                      label: const Text('Limpiar filtros'),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text('Proyectos mostrados dinámicamente en el mapa.', style: t.bodySmall),
                    ),
                  ],
                ),
              ],
            );
      },
    );
  }

  static String _scopeLabel(ProjectScope scope) {
    switch (scope) {
      case ProjectScope.municipal:
        return 'Municipal';
      case ProjectScope.comarcal:
        return 'Comarcal';
      case ProjectScope.insular:
        return 'Insular';
      case ProjectScope.regional:
        return 'Regional';
      case ProjectScope.unknown:
        return 'Otro';
    }
  }
}
