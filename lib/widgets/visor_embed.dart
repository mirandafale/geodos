import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import 'package:geodos/models/project.dart';
import 'package:geodos/services/filters_controller.dart';
import 'package:geodos/services/project_service.dart';

class VisorEmbed extends StatefulWidget {
  final bool startExpanded;
  const VisorEmbed({super.key, this.startExpanded = false});

  @override
  State<VisorEmbed> createState() => _VisorEmbedState();
}

class _VisorEmbedState extends State<VisorEmbed> {
  bool _expanded = false;
  OverlayEntry? _backdrop;
  final _mapCtrl = MapController();
  final _legendKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _expanded = widget.startExpanded;
  }

  double get _targetHeight =>
      _expanded ? MediaQuery.of(context).size.height * 0.8 : 360;

  void _showBackdrop() {
    if (_backdrop != null) return;
    final topOffset = MediaQuery.of(context).padding.top + kToolbarHeight;
    _backdrop = OverlayEntry(
      builder: (_) => Positioned(
        top: topOffset,
        left: 0,
        right: 0,
        bottom: 0,
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: _collapse,
          child: Container(color: Colors.transparent),
        ),
      ),
    );
    Overlay.of(context, rootOverlay: true).insert(_backdrop!);
  }

  void _removeBackdrop() {
    _backdrop?.remove();
    _backdrop = null;
  }

  void _expand() {
    if (!_expanded) {
      setState(() => _expanded = true);
      _showBackdrop();
    }
  }

  void _collapse() {
    if (_expanded) {
      setState(() => _expanded = false);
      _removeBackdrop();
    }
  }

  @override
  void dispose() {
    _removeBackdrop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filters = FiltersController.instance;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
      height: _targetHeight,
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 12, offset: Offset(0, 6)),
        ],
      ),
      child: Listener(
        onPointerDown: (_) => _expand(),
        child: _ProjectsMap(
          mapCtrl: _mapCtrl,
          filters: filters,
          legendKey: _legendKey,
        ),
      ),
    );
  }
}

class _ProjectsMap extends StatefulWidget {
  final MapController mapCtrl;
  final FiltersController filters;
  final GlobalKey legendKey;

  const _ProjectsMap({
    required this.mapCtrl,
    required this.filters,
    required this.legendKey,
  });

  @override
  State<_ProjectsMap> createState() => _ProjectsMapState();
}

class _ProjectsMapState extends State<_ProjectsMap> {
  final _distance = const Distance();
  bool _mapReady = false;
  VoidCallback? _pendingCameraAction;
  double _zoom = 7;

  @override
  Widget build(BuildContext context) {
    final mapCtrl = widget.mapCtrl;
    final filters = widget.filters;
    const center = LatLng(28.2916, -16.6291);

    return AnimatedBuilder(
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
                          border: Border.all(color: Colors.white, width: 1),
                        ),
                      ),
                    ),
                  ),
                );
              }
              final clusterCategories = _clusterCategories(cluster.items);
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
                    onTap: () => _openClusterSheet(context, cluster.items),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: clusterColor,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 1.5),
                            boxShadow: const [
                              BoxShadow(color: Colors.black26, blurRadius: 3),
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
                                          const EdgeInsets.symmetric(horizontal: 1),
                                      width: 5,
                                      height: 5,
                                      decoration: BoxDecoration(
                                        color:
                                            _categoryColor(context, category),
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                            color: Colors.white, width: 0.6),
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

            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;
              _runWhenMapReady(() {
                if (projects.isNotEmpty) {
                  final latLngs =
                      projects.map((p) => LatLng(p.lat, p.lon)).toList();
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

                  final bounds =
                      LatLngBounds(LatLng(swLat, swLng), LatLng(neLat, neLng));
                  mapCtrl.fitCamera(
                    CameraFit.bounds(
                        bounds: bounds, padding: const EdgeInsets.all(60)),
                  );
                } else {
                  mapCtrl.move(center, 7);
                }
              });
            });

            final emptyMessage = snap.hasError
                ? snap.error.toString()
                : 'No hay proyectos que coincidan con el filtro.';

            return Stack(
              children: [
                FlutterMap(
                  mapController: mapCtrl,
                  options: MapOptions(
                    initialCenter: center,
                    initialZoom: 7,
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
                    interactionOptions:
                        InteractionOptions(flags: InteractiveFlag.all),
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'geodos.app',
                      tileProvider: NetworkTileProvider(),
                    ),
                    MarkerLayer(markers: markers),
                  ],
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
                Positioned(
                  top: 12,
                  left: 12,
                  child: _Legend(
                    key: widget.legendKey,
                    filtersState: st,
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _runWhenMapReady(VoidCallback action) {
    if (_mapReady) action();
    else _pendingCameraAction = action;
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
        final maxWidth = (size.width * 0.9) < 720 ? size.width * 0.9 : 720.0;
        final maxHeight = size.height * 0.7;
        final horizontalInset = (size.width - maxWidth) / 2;
        final verticalInset = (size.height - maxHeight) / 2;

        return Dialog(
          insetPadding: EdgeInsets.symmetric(
            horizontal: horizontalInset < 0 ? 0 : horizontalInset,
            vertical: verticalInset < 0 ? 0 : verticalInset,
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: maxWidth,
              maxHeight: maxHeight,
            ),
            child: SizedBox(
              width: maxWidth,
              height: maxHeight,
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
                  Expanded(
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                      itemCount: projects.length,
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
                                style: Theme.of(dialogContext)
                                    .textTheme
                                    .titleSmall,
                              ),
                            ),
                            const SizedBox(width: 12),
                            TextButton(
                              onPressed: () {
                                Navigator.of(dialogContext).pop();
                                _runWhenMapReady(() {
                                  final target =
                                      LatLng(project.lat, project.lon);
                                  final double targetZoom =
                                      _zoom < 13.0 ? 13.0 : _zoom;
                                  widget.mapCtrl.move(target, targetZoom);
                                });
                              },
                              child: const Text('Ver'),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ),
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

  String _normalizeCategory(String raw) {
    final normalized = raw.replaceAll(RegExp(r'\s+'), ' ').trim();
    return normalized.isEmpty ? raw.trim() : normalized;
  }
}

class _Legend extends StatefulWidget {
  final FiltersState filtersState;

  const _Legend({
    super.key,
    required this.filtersState,
  });

  @override
  State<_Legend> createState() => _LegendState();
}

class _LegendState extends State<_Legend> {
  bool _expanded = false;

  void _collapse() {
    if (_expanded) {
      setState(() => _expanded = false);
    }
  }

  void _expand() {
    if (!_expanded) {
      setState(() => _expanded = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final surfaceColor = theme.colorScheme.surface;
    final outlineColor = theme.colorScheme.outlineVariant.withOpacity(0.45);
    final secondaryText = textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
          fontSize: 11,
          height: 1.2,
        ) ??
        TextStyle(
          color: theme.colorScheme.onSurfaceVariant,
          fontSize: 11,
          height: 1.2,
        );

    final activeFilters = _activeFilters(widget.filtersState);

    return AnimatedSize(
      duration: const Duration(milliseconds: 200),
      alignment: Alignment.topLeft,
      curve: Curves.easeInOut,
      child: Material(
        color: surfaceColor,
        elevation: 3,
        shadowColor: Colors.black12,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: _expanded ? null : _expand,
          child: Container(
            padding: _expanded
                ? const EdgeInsets.fromLTRB(12, 10, 10, 10)
                : const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            constraints: _expanded
                ? const BoxConstraints(maxWidth: 240, maxHeight: 240)
                : const BoxConstraints(minHeight: 44),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: outlineColor),
            ),
            child: _expanded
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Filtros activos',
                              style: textTheme.labelSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: _collapse,
                            icon: const Icon(Icons.close, size: 16),
                            tooltip: 'Cerrar',
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(
                              minWidth: 24,
                              minHeight: 24,
                            ),
                            splashRadius: 16,
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      if (activeFilters.isNotEmpty)
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxHeight: 200),
                          child: SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: activeFilters
                                  .map(
                                    (filter) => Padding(
                                      padding: const EdgeInsets.only(bottom: 6),
                                      child: Text(filter, style: secondaryText),
                                    ),
                                  )
                                  .toList(),
                            ),
                          ),
                        ),
                    ],
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.tune, size: 16),
                      const SizedBox(width: 6),
                      Text(
                        'Filtros',
                        style: textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Icon(Icons.expand_more, size: 18),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  List<String> _activeFilters(FiltersState st) {
    final filters = <String>[];
    if (st.category != null && st.category!.trim().isNotEmpty) {
      filters.add('Categoría: ${_normalizeCategory(st.category!)}');
    }
    if (st.island != null && st.island!.trim().isNotEmpty) {
      filters.add('Isla: ${st.island}');
    }
    if (st.scope != null) {
      filters.add('Ámbito: ${st.scope!.name}');
    }
    if (st.year != null) {
      filters.add('Año: ${st.year}');
    }
    if (st.search.isNotEmpty) {
      filters.add('Búsqueda: "${st.search}"');
    }
    return filters;
  }

  String _normalizeCategory(String raw) {
    final normalized = raw.replaceAll(RegExp(r'\s+'), ' ').trim();
    return normalized.isEmpty ? raw.trim() : normalized;
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
