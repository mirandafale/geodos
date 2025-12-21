// visor_page.dart con filtros profesionales y visor de proyectos

import 'package:flutter/material.dart';
import 'package:geodos/brand/brand.dart';
import 'package:geodos/models/project.dart';
import 'package:geodos/services/filters_controller.dart';
import 'package:geodos/services/project_service.dart';
import 'package:geodos/widgets/visor_embed.dart';
import 'package:geodos/widgets/app_shell.dart';

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

  @override
  void initState() {
    super.initState();
    _yearsFuture = ProjectService.getYears();
    _categoriesFuture = ProjectService.getCategories();
    _scopesFuture = ProjectService.getScopes();
    _islandsFuture = ProjectService.getIslands();
    _searchCtrl.text = filters.state.search;
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: const Text('Visor de proyectos'),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final vertical = constraints.maxWidth < 1100;
          final content = [
            _FiltersPanel(
              filters: filters,
              yearsFuture: _yearsFuture,
              categoriesFuture: _categoriesFuture,
              scopesFuture: _scopesFuture,
              islandsFuture: _islandsFuture,
              searchController: _searchCtrl,
            ),
            const SizedBox(width: 20, height: 20),
            const Expanded(
              child: Padding(
                padding: EdgeInsets.all(12.0),
                child: VisorEmbed(startExpanded: true),
              ),
            ),
          ];

          return Container(
            color: Brand.mist,
            padding: const EdgeInsets.all(16),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1400),
                child: vertical
                    ? Column(
                        children: content,
                      )
                    : Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(width: 360, child: content.first),
                          ...content.sublist(1),
                        ],
                      ),
              ),
            ),
          );
        },
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

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: AnimatedBuilder(
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
                    final selectedCategory =
                        items.contains(st.category) ? st.category : null;
                    return DropdownButtonFormField<String?>(
                      value: selectedCategory,
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
                    final selectedIsland = items.contains(st.island) ? st.island : null;
                    return DropdownButtonFormField<String?>(
                      value: selectedIsland,
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
                    Text('Proyectos mostrados dinámicamente en el mapa.', style: t.bodySmall),
                  ],
                ),
              ],
            );
          },
        ),
      ),
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
