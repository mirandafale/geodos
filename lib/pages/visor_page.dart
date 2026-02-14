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
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1400),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final viewportHeight = MediaQuery.of(context).size.height;
                final width = constraints.maxWidth;
                final isDesktop = width >= 1200;
                final isTablet = width >= 900;
                final isMobile = !isTablet;

                final mapHeight = isDesktop
                    ? (viewportHeight * 0.70).clamp(600.0, 780.0)
                    : isTablet
                        ? (viewportHeight * 0.60).clamp(520.0, 720.0)
                        : 440.0;

                final filtersPanel = _FiltersPanel(
                  filters: filters,
                  yearsFuture: _yearsFuture,
                  categoriesFuture: _categoriesFuture,
                  scopesFuture: _scopesFuture,
                  islandsFuture: _islandsFuture,
                  searchController: _searchCtrl,
                );

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      margin: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 10,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: SizedBox(
                        width: double.infinity,
                        height: mapHeight,
                        child: Stack(
                          children: [
                            Positioned.fill(
                              child: VisorEmbed(baseHeight: mapHeight),
                            ),
                            if (isMobile)
                              Positioned(
                                left: 12,
                                right: 12,
                                top: 12,
                                child: Material(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(14),
                                  elevation: 3,
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(14),
                                    child: ExpansionTile(
                                      tilePadding: const EdgeInsets.symmetric(horizontal: 12),
                                      title: const Text('Filtros'),
                                      initiallyExpanded: false,
                                      children: [
                                        ConstrainedBox(
                                          constraints: BoxConstraints(maxHeight: mapHeight * 0.55),
                                          child: SingleChildScrollView(
                                            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                                            child: filtersPanel,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              )
                            else
                              Positioned(
                                left: 16,
                                top: 16,
                                child: ConstrainedBox(
                                  constraints: BoxConstraints(
                                    maxWidth: 320,
                                    maxHeight: mapHeight - 32,
                                  ),
                                  child: Material(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(14),
                                    elevation: 3,
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(14),
                                      child: SingleChildScrollView(
                                        padding: const EdgeInsets.all(12),
                                        child: filtersPanel,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    AnimatedOpacity(
                      duration: const Duration(milliseconds: 500),
                      curve: Curves.easeOut,
                      opacity: 1,
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
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
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Colors.grey[700],
                                  ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 24),
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
    );
  }
}

class _FiltersPanel extends StatelessWidget {
  final FiltersController filters;
  final Future<List<int>> yearsFuture;
  final Future<List<String>> categoriesFuture;
  final Future<List<ProjectScope>> scopesFuture;
  final Future<List<String>> islandsFuture;
  final TextEditingController searchController;

  const _FiltersPanel({
    required this.filters,
    required this.yearsFuture,
    required this.categoriesFuture,
    required this.scopesFuture,
    required this.islandsFuture,
    required this.searchController,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final t = theme.textTheme;

    return AnimatedBuilder(
      animation: filters,
      builder: (context, _) {
        final st = filters.state;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Filtros', style: t.titleLarge?.copyWith(fontWeight: FontWeight.w700, color: Brand.primary)),
            const SizedBox(height: 4),
            Text('Refina los proyectos por categoría, ámbito, isla y año.', style: t.bodyMedium),
            const Divider(height: 24),
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
            Wrap(
              spacing: 12,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
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
                Text('Proyectos mostrados dinámicamente en el mapa.', style: t.bodySmall),
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
