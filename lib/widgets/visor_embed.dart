// visor_embed.dart adaptado con mejoras funcionales y leyenda de categorías

import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import 'package:geodos/brand/brand.dart';
import 'package:geodos/models/project.dart';
import 'package:geodos/services/filters_controller.dart';
import 'package:geodos/services/project_service.dart';
import 'package:geodos/widgets/project_info_dialog.dart';

class VisorEmbed extends StatefulWidget {
  final bool startExpanded;
  const VisorEmbed({super.key, this.startExpanded = false});

  @override
  State<VisorEmbed> createState() => _VisorEmbedState();
}

class _VisorEmbedState extends State<VisorEmbed> {
  late bool _expanded;
  OverlayEntry? _backdrop;
  final _mapCtrl = MapController();
  final _legendKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _expanded = widget.startExpanded;
  }

  double get _targetHeight => _expanded ? MediaQuery.of(context).size.height * 0.8 : 360;

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
  VoidCallback? _pendingCameraAction;
  double _zoom = 7;
  bool _mapReady = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final mapCtrl = widget.mapCtrl;
    final filters = widget.filters;
    const center = LatLng(28.2916, -16.6291);

    return AnimatedBuilder(
      animation: filters,
      builder: (ctx, _) {
        final st = filters.state;

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
                final color = _colorForCategory(context, project.category);
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
              final clusterColor = _dominantClusterColor(context, cluster.items);
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
                                      margin: const EdgeInsets.symmetric(horizontal: 1),
                                      width: 5,
                                      height: 5,
                                      decoration: BoxDecoration(
                                        color: _colorForCategory(context, category),
                                        shape: BoxShape.circle,
                                        border: Border.all(color: Colors.white, width: 0.6),
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
              _runWhenMapReady(() {
                if (projects.isNotEmpty) {
                  final latLngs = projects.map((p) => LatLng(p.lat, p.lon)).toList();
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

                  final bounds = LatLngBounds(LatLng(swLat, swLng), LatLng(neLat, neLng));
                  mapCtrl.fitCamera(
                    CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(60)),
                  );
                } else {
                  mapCtrl.move(center, 7);
                }
              });
            });

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
                      _zoom = widget.mapCtrl.camera.zoom;
                      _flushCameraActions();
                    },
                    onMapEvent: (event) {
                      if (!mounted) return;
                      if (_zoom != event.camera.zoom) {
                        setState(() => _zoom = event.camera.zoom);
                      }
                    },
                    interactionOptions: InteractionOptions(flags: InteractiveFlag.all),
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
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
                            ProjectService.lastRemoteCount == 0
                                ? 'No hay proyectos disponibles desde Firestore. Añade un proyecto o ajusta los filtros.'
                                : 'No hay proyectos visibles con los filtros actuales.',
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
                  right: 12,
                  child: _Legend(
                    key: widget.legendKey,
                    categories: projects.map((e) => e.category).toSet().toList(),
                    total: projects.length,
                    colorForCategory: (c) => _colorForCategory(context, c),
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
    if (_mapReady) {
      action();
      return;
    }
    _pendingCameraAction = action;
  }

  void _flushCameraActions() {
    final pending = _pendingCameraAction;
    _pendingCameraAction = null;
    pending?.call();
  }

  List<_ProjectCluster> _buildClusters(List<Project> projects, double zoom) {
    final threshold = _clusterThresholdMeters(zoom);
    final clusters = <_ProjectCluster>[];

    for (final project in projects) {
      final point = LatLng(project.lat, project.lon);
      _ProjectCluster? match;
      for (final cluster in clusters) {
        final distance = _distance.as(LengthUnit.Meter, point, cluster.center);
        if (distance <= threshold) {
          match = cluster;
          break;
        }
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
    const minZoom = 11.0;
    const maxZoom = 15.0;
    const maxThreshold = 80.0;
    const minThreshold = 40.0;
    final t = ((zoom - minZoom) / (maxZoom - minZoom)).clamp(0.0, 1.0);
    return maxThreshold + (minThreshold - maxThreshold) * t;
  }

  void _openClusterSheet(BuildContext context, List<Project> projects) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      isDismissible: true,
      enableDrag: true,
      showDragHandle: true,
      builder: (sheetContext) {
        final screenHeight = MediaQuery.of(sheetContext).size.height;
        final minHeight = 180.0;
        final maxHeight = screenHeight * 0.6;
        const headerHeight = 52.0;
        const itemHeight = 78.0;
        final listPadding = projects.isEmpty ? 24.0 : 36.0;
        final desiredHeight =
            headerHeight + (projects.length * itemHeight) + listPadding + 1;
        final sheetHeight =
            desiredHeight.clamp(minHeight, maxHeight).toDouble();
        return SafeArea(
          child: SizedBox(
            height: sheetHeight,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 8, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Proyectos del cluster (${projects.length})',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(sheetContext).pop(),
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
                      return InkWell(
                        onTap: () {
                          Navigator.of(sheetContext).pop();
                          _runWhenMapReady(() {
                            final target = LatLng(project.lat, project.lon);
                            widget.mapCtrl.move(target, 13.5);
                          });
                        },
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              margin: const EdgeInsets.only(top: 6),
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: _colorForCategory(context, project.category),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    project.title,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(context).textTheme.titleSmall,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${_normalizeCategory(project.category)} · ${project.year ?? 's/f'} · ${project.municipality}',
                                    style: Theme.of(context).textTheme.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            TextButton(
                              onPressed: () {
                                showDialog<void>(
                                  context: sheetContext,
                                  builder: (_) => ProjectInfoDialog(project: project),
                                );
                              },
                              child: const Text('Ver'),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Color _colorForCategory(BuildContext context, String category) {
    final c = category.toUpperCase();
    if (c.contains('MEDIOAMBIENTE')) return Colors.green.shade700;
    if (c.contains('ORDENACION') || c.contains('ORDENACIÓN')) return Brand.primary;
    if (c.contains('PATRIMONIO')) return Colors.purple.shade700;
    if (c.contains('ESTUDIOS') || c.contains('DESARROLLO')) {
      return Colors.teal.shade700;
    }
    if (c.contains('SIG') ||
        c.contains('SISTEMA DE INFORMACION GEOGRAFICA') ||
        c.contains('SISTEMA DE INFORMACIÓN GEOGRÁFICA')) {
      return Colors.indigo.shade700;
    }
    if (c.contains('SISTEMAS')) return Colors.orange.shade800;
    final palette = [
      Colors.red.shade700,
      Colors.blueGrey.shade700,
      Colors.cyan.shade700,
      Colors.lime.shade700,
      Colors.pink.shade600,
      Colors.amber.shade800,
      Colors.deepPurple.shade600,
      Colors.lightBlue.shade700,
    ];
    final index = _stableHash(c) % palette.length;
    return palette[index];
  }

  int _stableHash(String input) {
    var hash = 0x811c9dc5;
    for (final codeUnit in input.codeUnits) {
      hash ^= codeUnit;
      hash = (hash * 0x01000193) & 0x7fffffff;
    }
    return hash;
  }

  List<String> _clusterCategories(List<Project> projects) {
    final categories = projects.map((project) => project.category).toSet().toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return categories;
  }

  Color _clusterColor(BuildContext context, List<String> categories) {
    if (categories.length == 1) {
      return _colorForCategory(context, categories.first);
    }
    return Brand.primary;
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
    return _colorForCategory(context, bestCategory);
  }

  String _normalizeCategory(String raw) {
    final normalized = raw.replaceAll(RegExp(r'\s+'), ' ').trim();
    return normalized.isEmpty ? raw.trim() : normalized;
  }
}

class _Legend extends StatelessWidget {
  final List<String> categories;
  final int total;
  final Color Function(String) colorForCategory;

  const _Legend({
    super.key,
    required this.categories,
    required this.total,
    required this.colorForCategory,
  });

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final titleStyle = t.labelSmall?.copyWith(
          fontWeight: FontWeight.w600,
          fontSize: 10,
        ) ??
        const TextStyle(fontWeight: FontWeight.w600, fontSize: 10);
    final itemStyle =
        t.labelSmall?.copyWith(fontSize: 9) ?? const TextStyle(fontSize: 9);
    final sorted = [...categories]
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 200),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Proyectos visibles: $total',
            style: titleStyle,
          ),
          const SizedBox(height: 6),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 140),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: sorted
                    .map(
                      (raw) => Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          mainAxisSize: MainAxisSize.max,
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: colorForCategory(raw),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                _normalizeCategory(raw),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: itemStyle,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          ),
        ],
      ),
    );
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
