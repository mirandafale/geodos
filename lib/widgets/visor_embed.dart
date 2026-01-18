import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geodos/models/project.dart';
import 'package:geodos/services/filters_controller.dart';
import 'package:geodos/services/project_service.dart';
import 'package:geodos/theme/base_map_style.dart';
import 'package:geodos/theme/brand.dart';
import 'package:latlong2/latlong.dart';

class VisorEmbed extends StatefulWidget {
  final bool startExpanded;
  const VisorEmbed({super.key, this.startExpanded = false});

  @override
  State<VisorEmbed> createState() => _VisorEmbedState();
}

class _VisorEmbedState extends State<VisorEmbed> {
  static const _minZoom = 4.0;
  static const _maxZoom = 18.0;
  static const _initialCenter = LatLng(28.3, -16.5);
  static const _initialZoom = 7.0;
  static const _collapsedMapHeight = 420.0;

  final _distance = const Distance();
  final _mapCtrl = MapController();
  BaseMapStyle _baseMapStyle = BaseMapStyle.standard;
  bool _mapReady = false;
  VoidCallback? _pendingCameraAction;
  double _zoom = _initialZoom;
  List<String> _lastProjectIds = const [];
  late final TextEditingController _searchCtrl;
  bool _filtersExpanded = false;
  bool _updatingSearch = false;

  @override
  void initState() {
    super.initState();
    final filters = FiltersController.instance;
    _filtersExpanded = widget.startExpanded;
    _searchCtrl = TextEditingController(text: filters.state.search);
    _searchCtrl.addListener(_handleSearchChanged);
  }

  @override
  void dispose() {
    _searchCtrl
      ..removeListener(_handleSearchChanged)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filters = FiltersController.instance;

    if (!_updatingSearch && _searchCtrl.text != filters.state.search) {
      _updatingSearch = true;
      _searchCtrl.value = TextEditingValue(
        text: filters.state.search,
        selection:
            TextSelection.collapsed(offset: filters.state.search.length),
      );
      _updatingSearch = false;
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final needsHeight = !constraints.hasBoundedHeight;

        return SizedBox(
          height: needsHeight ? _collapsedMapHeight : null,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: DecoratedBox(
              decoration: const BoxDecoration(color: Colors.white),
              child: AnimatedBuilder(
                animation: filters,
                builder: (ctx, _) {
                  final FiltersState st = filters.state;

                  return StreamBuilder<List<Project>>(
                    stream: ProjectService.stream(
                      year: st.year,
                      category: st.category,
                      scope: st.scope,
                      island: st.island,
                      search: st.search,
                    ),
                    builder: (ctx, snap) {
                      final projects = snap.data ?? [];
                      final categories =
                          _mergeSelection(st.category, _uniqueCategories(projects));
                      final islands =
                          _mergeSelection(st.island, _uniqueIslands(projects));
                      final scopes =
                          _mergeScopeSelection(st.scope, _uniqueScopes(projects));
                      final years =
                          _mergeYearSelection(st.year, _uniqueYears(projects));

                      final clusters = _buildClusters(projects, _zoom);
                      final markers = clusters.map((cluster) {
                        if (cluster.items.length == 1) {
                          final project = cluster.items.first;
                          final color = _categoryColor(context, project.category);
                          return Marker(
                            point: cluster.center,
                            width: 24,
                            height: 24,
                            child: Tooltip(
                              message:
                                  '${project.title}\n${project.category} · ${project.year ?? 's/f'}',
                              child: Center(
                                child: Container(
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    color: color,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                        color: Colors.white, width: 1),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }
                        final clusterCategories =
                            _clusterCategories(cluster.items);
                        final clusterColor =
                            _dominantClusterColor(context, cluster.items);
                        return Marker(
                          point: cluster.center,
                          width: 28,
                          height: 28,
                          child: Tooltip(
                            message: '${cluster.items.length} proyectos',
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () =>
                                  _openClusterSheet(context, cluster.items),
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  Container(
                                    decoration: BoxDecoration(
                                      color: clusterColor,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                          color: Colors.white, width: 1.5),
                                      boxShadow: const [
                                        BoxShadow(
                                          color: Colors.black26,
                                          blurRadius: 3,
                                        ),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    '${cluster.items.length}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12,
                                      color: Colors.white,
                                    ),
                                  ),
                                  if (clusterCategories.length > 1)
                                    Positioned(
                                      bottom: 4,
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: clusterCategories
                                            .take(3)
                                            .map(
                                              (category) => Container(
                                                margin:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 1),
                                                width: 5,
                                                height: 5,
                                                decoration: BoxDecoration(
                                                  color: _categoryColor(
                                                      context, category),
                                                  shape: BoxShape.circle,
                                                  border: Border.all(
                                                      color: Colors.white,
                                                      width: 0.6),
                                                ),
                                              ),
                                            )
                                            .toList(),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }).toList();

                      final currentIds = projects.map((p) => p.id).toList()
                        ..sort();
                      final projectsChanged =
                          currentIds.length != _lastProjectIds.length ||
                              !_lastProjectIds.asMap().entries.every(
                                  (entry) =>
                                      entry.value == currentIds[entry.key]);
                      if (projectsChanged) {
                        _lastProjectIds = currentIds;
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (!mounted) return;
                          _runWhenMapReady(() {
                            if (projects.isNotEmpty) {
                              final latLngs = projects
                                  .map((p) => LatLng(p.lat, p.lon))
                                  .toList();
                              var swLat = latLngs.first.latitude;
                              var swLng = latLngs.first.longitude;
                              var neLat = swLat;
                              var neLng = swLng;

                              for (final ll in latLngs) {
                                if (ll.latitude < swLat) swLat = ll.latitude;
                                if (ll.longitude < swLng) swLng = ll.longitude;
                                if (ll.latitude > neLat) neLat = ll.latitude;
                                if (ll.longitude > neLng) neLng = ll.longitude;
                              }

                              final bounds = LatLngBounds(
                                LatLng(swLat, swLng),
                                LatLng(neLat, neLng),
                              );
                              _mapCtrl.fitCamera(
                                CameraFit.bounds(
                                  bounds: bounds,
                                  padding: const EdgeInsets.all(60),
                                ),
                              );
                            } else {
                              _mapCtrl.move(_initialCenter, _initialZoom);
                            }
                          });
                        });
                      }

                      final emptyMessage = snap.hasError
                          ? snap.error.toString()
                          : 'No hay proyectos que coincidan con el filtro.';

                      return Stack(
                        children: [
                          Positioned.fill(
                            child: FlutterMap(
                              mapController: _mapCtrl,
                              options: MapOptions(
                                initialCenter: _initialCenter,
                                initialZoom: _initialZoom,
                                minZoom: _minZoom,
                                maxZoom: _maxZoom,
                                onMapReady: () {
                                  if (!mounted) return;
                                  _mapReady = true;
                                  final pending = _pendingCameraAction;
                                  _pendingCameraAction = null;
                                  pending?.call();
                                },
                                onMapEvent: (event) {
                                  if (!mounted) return;
                                  if (_zoom != event.camera.zoom) {
                                    setState(() => _zoom = event.camera.zoom);
                                  }
                                },
                                interactionOptions: InteractionOptions(
                                  flags: InteractiveFlag.all,
                                ),
                              ),
                              children: [
                                TileLayer(
                                  urlTemplate: _baseMapStyle.urlTemplate,
                                  userAgentPackageName: 'geodos.app',
                                  tileProvider: NetworkTileProvider(),
                                ),
                                MarkerLayer(markers: markers),
                              ],
                            ),
                          ),
                          Positioned(
                            top: 12,
                            left: 12,
                            child: _MapFiltersPanel(
                              expanded: _filtersExpanded,
                              filtersState: st,
                              categories: categories,
                              islands: islands,
                              scopes: scopes,
                              years: years,
                              searchController: _searchCtrl,
                              onReset: filters.reset,
                              onToggle: () {
                                setState(() => _filtersExpanded = !_filtersExpanded);
                              },
                              onCategoryChanged: filters.setCategory,
                              onIslandChanged: filters.setIsland,
                              onScopeChanged: filters.setScope,
                              onYearChanged: filters.setYear,
                            ),
                          ),
                          Positioned(
                            bottom: 12,
                            right: 12,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _BaseMapToggle(
                                  value: _baseMapStyle,
                                  onChanged: (style) {
                                    setState(() => _baseMapStyle = style);
                                  },
                                ),
                                const SizedBox(height: 8),
                                _ZoomControls(
                                  zoom: _zoom,
                                  minZoom: _minZoom,
                                  maxZoom: _maxZoom,
                                  onZoomIn: _zoomIn,
                                  onZoomOut: _zoomOut,
                                ),
                              ],
                            ),
                          ),
                          if (projects.isEmpty)
                            Center(
                              child: Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      emptyMessage,
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 10),
                                    ElevatedButton.icon(
                                      onPressed: filters.reset,
                                      icon: const Icon(Icons.visibility),
                                      label: const Text('Ver todos'),
                                    ),
                                    if (kDebugMode) ...[
                                      const SizedBox(height: 14),
                                      _DebugEmptyPanel(filtersState: st),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                        ],
                      );
                    },
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  void _runWhenMapReady(VoidCallback action) {
    if (_mapReady) action();
    else _pendingCameraAction = action;
  }

  void _handleSearchChanged() {
    if (_updatingSearch) return;
    FiltersController.instance.setSearch(_searchCtrl.text);
  }

  void _zoomIn() {
    _runWhenMapReady(() {
      final nextZoom = (_zoom + 1).clamp(_minZoom, _maxZoom);
      _mapCtrl.move(_mapCtrl.camera.center, nextZoom);
    });
  }

  void _zoomOut() {
    _runWhenMapReady(() {
      final nextZoom = (_zoom - 1).clamp(_minZoom, _maxZoom);
      _mapCtrl.move(_mapCtrl.camera.center, nextZoom);
    });
  }

  List<_ProjectCluster> _buildClusters(List<Project> projects, double zoom) {
    final threshold = _clusterThresholdMeters(zoom);
    final clusters = <_ProjectCluster>[];

    for (final project in projects) {
      final point = LatLng(project.lat, project.lon);
      _ProjectCluster? match;
      for (final cluster in clusters) {
        for (final item in cluster.items) {
          final distance = _distance.as(
            LengthUnit.Meter,
            point,
            LatLng(item.lat, item.lon),
          );
          if (distance <= threshold) {
            match = cluster;
            break;
          }
        }
        if (match != null) break;
      }
      if (match == null) {
        clusters.add(_ProjectCluster(point, [project]));
      } else {
        match.items.add(project);
        match.recenter();
      }
    }
    return clusters;
  }

  double _clusterThresholdMeters(double zoom) {
    if (zoom >= 13) return 60;
    if (zoom >= 11) return 120;
    if (zoom >= 9) return 250;
    return 450;
  }

  void _openClusterSheet(BuildContext context, List<Project> projects) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        final size = MediaQuery.of(dialogContext).size;
        final maxWidth = math.min(720.0, size.width * 0.9);
        final maxHeight = size.height * 0.75;
        const minHeight = 220.0;
        final desiredHeight = 56 + projects.length * 64 + 40;
        final dialogHeight =
            desiredHeight.clamp(minHeight, maxHeight).toDouble();
        final isMaxHeight = dialogHeight >= maxHeight;
        final listView = ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          itemCount: projects.length,
          physics: const AlwaysScrollableScrollPhysics(),
          shrinkWrap: !isMaxHeight,
          separatorBuilder: (_, __) => const Divider(height: 24),
          itemBuilder: (_, index) {
            final project = projects[index];
            return Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: _categoryColor(
                      dialogContext,
                      project.category,
                    ),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    project.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(dialogContext).textTheme.titleSmall,
                  ),
                ),
                const SizedBox(width: 12),
                TextButton(
                  onPressed: () {
                    Navigator.of(dialogContext).pop();
                    _runWhenMapReady(() {
                      final target = LatLng(project.lat, project.lon);
                      final double targetZoom = _zoom < 13.0 ? 13.0 : _zoom;
                      _mapCtrl.move(target, targetZoom);
                    });
                  },
                  child: const Text('Ver'),
                ),
              ],
            );
          },
        );

        return Dialog(
          child: SizedBox(
            width: maxWidth,
            height: dialogHeight,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Proyectos (${projects.length})',
                          style: Theme.of(dialogContext).textTheme.titleSmall,
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(dialogContext).pop(),
                        icon: const Icon(Icons.close),
                        tooltip: 'Cerrar',
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                if (isMaxHeight)
                  Expanded(child: listView)
                else
                  Flexible(fit: FlexFit.loose, child: listView),
              ],
            ),
          ),
        );
      },
    );
  }

  Color _categoryColor(BuildContext context, String category) {
    final c = category.toUpperCase();
    if (c.contains('IMPACTO') ||
        c.contains('AMBIENTAL') ||
        c.contains('MEDIOAMBIENTE')) {
      return const Color(0xFF1B8A3D);
    }
    if (c.contains('URBANISMO') ||
        c.contains('ORDENACION') ||
        c.contains('ORDENACIÓN')) {
      return const Color(0xFF1565C0);
    }
    if (c.contains('PAISAJE')) return const Color(0xFF00897B);
    if (c.contains('PATRIMONIO') || c.contains('GEODIVERSIDAD')) {
      return const Color(0xFF6D4C41);
    }
    if (c.contains('SIG') ||
        c.contains('SISTEMA DE INFORMACION GEOGRAFICA') ||
        c.contains('SISTEMA DE INFORMACIÓN GEOGRÁFICA')) {
      return const Color(0xFF3949AB);
    }
    if (c.contains('GEOMARKETING')) return const Color(0xFF8E24AA);
    return Theme.of(context).colorScheme.primary;
  }

  List<String> _clusterCategories(List<Project> projects) {
    final categories =
        projects.map((project) => project.category).toSet().toList()
          ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return categories;
  }

  Color _dominantClusterColor(BuildContext context, List<Project> projects) {
    final counts = <String, int>{};
    var bestCategory = projects.first.category;
    var bestCount = 0;
    for (final project in projects) {
      final category = project.category;
      final nextCount = (counts[category] ?? 0) + 1;
      counts[category] = nextCount;
      if (nextCount > bestCount) {
        bestCount = nextCount;
        bestCategory = category;
      }
    }
    return _categoryColor(context, bestCategory);
  }

  List<String> _uniqueCategories(List<Project> projects) {
    final set = projects.map((project) => project.category).toSet();
    final list = set.toList();
    list.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return list;
  }

  List<String> _uniqueIslands(List<Project> projects) {
    final set = projects.map((project) => project.island).toSet();
    final list = set.where((value) => value.trim().isNotEmpty).toList();
    list.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return list;
  }

  List<ProjectScope> _uniqueScopes(List<Project> projects) {
    final set = projects.map((project) => project.scope).toSet();
    final list = set.toList();
    const order = {
      ProjectScope.municipal: 0,
      ProjectScope.comarcal: 1,
      ProjectScope.insular: 2,
      ProjectScope.regional: 3,
      ProjectScope.unknown: 4,
    };
    list.sort((a, b) => (order[a] ?? 0).compareTo(order[b] ?? 0));
    return list;
  }

  List<int> _uniqueYears(List<Project> projects) {
    final set = projects.map((project) => project.year).whereType<int>().toSet();
    final list = set.toList()..sort((a, b) => b.compareTo(a));
    return list;
  }

  List<String> _mergeSelection(String? value, List<String> items) {
    if (value == null || value.trim().isEmpty) return items;
    if (items.contains(value)) return items;
    return [value, ...items];
  }

  List<ProjectScope> _mergeScopeSelection(
    ProjectScope? value,
    List<ProjectScope> items,
  ) {
    if (value == null) return items;
    if (items.contains(value)) return items;
    return [value, ...items];
  }

  List<int> _mergeYearSelection(int? value, List<int> items) {
    if (value == null) return items;
    if (items.contains(value)) return items;
    return [value, ...items];
  }
}

class _ZoomControls extends StatelessWidget {
  final double zoom;
  final double minZoom;
  final double maxZoom;
  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;

  const _ZoomControls({
    required this.zoom,
    required this.minZoom,
    required this.maxZoom,
    required this.onZoomIn,
    required this.onZoomOut,
  });

  @override
  Widget build(BuildContext context) {
    final canZoomIn = zoom < maxZoom;
    final canZoomOut = zoom > minZoom;

    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            onPressed: canZoomIn ? onZoomIn : null,
            icon: const Icon(Icons.add),
            tooltip: 'Acercar',
          ),
          const Divider(height: 1),
          IconButton(
            onPressed: canZoomOut ? onZoomOut : null,
            icon: const Icon(Icons.remove),
            tooltip: 'Alejar',
          ),
        ],
      ),
    );
  }
}

class _MapFiltersPanel extends StatelessWidget {
  final FiltersState filtersState;
  final bool expanded;
  final List<String> categories;
  final List<String> islands;
  final List<ProjectScope> scopes;
  final List<int> years;
  final TextEditingController searchController;
  final VoidCallback onReset;
  final VoidCallback onToggle;
  final ValueChanged<String?> onCategoryChanged;
  final ValueChanged<String?> onIslandChanged;
  final ValueChanged<ProjectScope?> onScopeChanged;
  final ValueChanged<int?> onYearChanged;

  const _MapFiltersPanel({
    required this.filtersState,
    required this.expanded,
    required this.categories,
    required this.islands,
    required this.scopes,
    required this.years,
    required this.searchController,
    required this.onReset,
    required this.onToggle,
    required this.onCategoryChanged,
    required this.onIslandChanged,
    required this.onScopeChanged,
    required this.onYearChanged,
  });

  @override
  Widget build(BuildContext context) {
    final hasFilters = _hasActiveFilters(filtersState);
    final textTheme = Theme.of(context).textTheme;
    const borderRadius = BorderRadius.all(Radius.circular(16));

    return Material(
      elevation: 8,
      shadowColor: Colors.black26,
      borderRadius: borderRadius,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 320),
        child: ClipRRect(
          borderRadius: borderRadius,
          child: AnimatedCrossFade(
            firstCurve: Curves.easeOut,
            secondCurve: Curves.easeIn,
            sizeCurve: Curves.easeOut,
            duration: const Duration(milliseconds: 200),
            crossFadeState:
                expanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            firstChild: InkWell(
              onTap: onToggle,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.filter_alt, size: 18),
                    SizedBox(width: 6),
                    Text('Filtros'),
                  ],
                ),
              ),
            ),
            secondChild: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 420),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Brand.primary.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.filter_alt,
                            size: 16,
                            color: Brand.primary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Filtros',
                            style: textTheme.labelLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: Brand.primary,
                            ),
                          ),
                        ),
                        IconButton(
                          tooltip: 'Ocultar filtros',
                          onPressed: onToggle,
                          icon: const Icon(Icons.close, size: 18),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    _FilterField(
                      label: 'Categoría',
                      child: DropdownButtonFormField<String?>(
                        isExpanded: true,
                        value: filtersState.category,
                        decoration: _filterDecoration(),
                        items: [
                          const DropdownMenuItem<String?>(
                            value: null,
                            child: Text('Todas'),
                          ),
                          ...categories.map(
                            (category) => DropdownMenuItem<String?>(
                              value: category,
                              child: Text(category),
                            ),
                          ),
                        ],
                        onChanged: onCategoryChanged,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _FilterField(
                      label: 'Isla',
                      child: DropdownButtonFormField<String?>(
                        isExpanded: true,
                        value: filtersState.island,
                        decoration: _filterDecoration(),
                        items: [
                          const DropdownMenuItem<String?>(
                            value: null,
                            child: Text('Todas'),
                          ),
                          ...islands.map(
                            (island) => DropdownMenuItem<String?>(
                              value: island,
                              child: Text(island),
                            ),
                          ),
                        ],
                        onChanged: onIslandChanged,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _FilterField(
                      label: 'Ámbito',
                      child: DropdownButtonFormField<ProjectScope?>(
                        isExpanded: true,
                        value: filtersState.scope,
                        decoration: _filterDecoration(),
                        items: [
                          const DropdownMenuItem<ProjectScope?>(
                            value: null,
                            child: Text('Todos'),
                          ),
                          ...scopes.map(
                            (scope) => DropdownMenuItem<ProjectScope?>(
                              value: scope,
                              child: Text(_scopeLabel(scope)),
                            ),
                          ),
                        ],
                        onChanged: onScopeChanged,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _FilterField(
                      label: 'Año',
                      child: DropdownButtonFormField<int?>(
                        isExpanded: true,
                        value: filtersState.year,
                        decoration: _filterDecoration(),
                        items: [
                          const DropdownMenuItem<int?>(
                            value: null,
                            child: Text('Todos'),
                          ),
                          ...years.map(
                            (year) => DropdownMenuItem<int?>(
                              value: year,
                              child: Text(year.toString()),
                            ),
                          ),
                        ],
                        onChanged: onYearChanged,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _FilterField(
                      label: 'Búsqueda',
                      child: TextField(
                        controller: searchController,
                        decoration: _filterDecoration().copyWith(
                          hintText: 'Buscar proyecto...',
                          prefixIcon: const Icon(Icons.search, size: 18),
                        ),
                      ),
                    ),
                    if (hasFilters) ...[
                      const SizedBox(height: 10),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: onReset,
                          style: TextButton.styleFrom(
                            foregroundColor: Brand.primary,
                          ),
                          child: const Text('Limpiar filtros'),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  bool _hasActiveFilters(FiltersState st) {
    return (st.category != null && st.category!.trim().isNotEmpty) ||
        (st.island != null && st.island!.trim().isNotEmpty) ||
        st.scope != null ||
        st.year != null ||
        st.search.trim().isNotEmpty;
  }

  InputDecoration _filterDecoration() {
    return InputDecoration(
      isDense: true,
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    );
  }

  String _scopeLabel(ProjectScope scope) {
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

class _FilterField extends StatelessWidget {
  final String label;
  final Widget child;

  const _FilterField({
    required this.label,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: textTheme.labelSmall?.copyWith(
            color: Colors.grey.shade700,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        child,
      ],
    );
  }
}

class _BaseMapToggle extends StatelessWidget {
  final BaseMapStyle value;
  final ValueChanged<BaseMapStyle> onChanged;

  const _BaseMapToggle({
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    const styles = [
      BaseMapStyle.standard,
      BaseMapStyle.satellite,
    ];
    final selected = styles.map((style) => style == value).toList();

    return Card(
      elevation: 6,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: ToggleButtons(
          isSelected: selected,
          onPressed: (index) => onChanged(styles[index]),
          borderRadius: BorderRadius.circular(12),
          selectedBorderColor: Brand.primary,
          borderColor: Colors.grey.shade300,
          fillColor: Brand.primary,
          color: Colors.grey.shade800,
          selectedColor: Colors.white,
          constraints: const BoxConstraints(minHeight: 34, minWidth: 44),
          children: styles
              .map(
                (style) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(style.icon, size: 16),
                      const SizedBox(width: 6),
                      Text(
                        style.label,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}

class _ProjectCluster {
  _ProjectCluster(this.center, this.items);

  LatLng center;
  final List<Project> items;

  void recenter() {
    var lat = 0.0;
    var lon = 0.0;
    for (final project in items) {
      lat += project.lat;
      lon += project.lon;
    }
    center = LatLng(lat / items.length, lon / items.length);
  }
}

class _DebugEmptyPanel extends StatelessWidget {
  final FiltersState filtersState;

  const _DebugEmptyPanel({
    required this.filtersState,
  });

  @override
  Widget build(BuildContext context) {
    final remoteCount = ProjectService.lastRemoteCount;
    final usingFallback = ProjectService.usingLocalFallback;
    final fallbackCount = ProjectService.localFallbackCount;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade400),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Diagnóstico (debug)',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 6),
            Text('Proyectos recibidos de Firestore: $remoteCount'),
            if (usingFallback)
              Text('Fallback local activo: $fallbackCount proyectos'),
            Text('Filtros actuales: ${_filtersSummary(filtersState)}'),
          ],
        ),
      ),
    );
  }

  String _filtersSummary(FiltersState st) {
    final parts = <String>[
      'categoría: ${st.category?.toLowerCase() ?? 'todas'}',
      'isla: ${st.island ?? 'todas'}',
      'ámbito: ${st.scope?.name ?? 'todos'}',
      'año: ${st.year?.toString() ?? 'todos'}',
      'búsqueda: ${st.search.isEmpty ? 'ninguna' : '"${st.search}"'}',
    ];
    return parts.join(' · ');
  }
}
