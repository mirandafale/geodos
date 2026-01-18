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

  final _distance = const Distance();
  final _mapCtrl = MapController();
  BaseMapStyle _baseMapStyle = BaseMapStyle.standard;
  bool _mapReady = false;
  VoidCallback? _pendingCameraAction;
  double _zoom = _initialZoom;
  List<String> _lastProjectIds = const [];

  @override
  Widget build(BuildContext context) {
    final filters = FiltersController.instance;

    return ClipRRect(
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
                                          margin: const EdgeInsets.symmetric(
                                              horizontal: 1),
                                          width: 5,
                                          height: 5,
                                          decoration: BoxDecoration(
                                            color: _categoryColor(
                                                context, category),
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

                final currentIds = projects.map((p) => p.id).toList()..sort();
                final projectsChanged =
                    currentIds.length != _lastProjectIds.length ||
                        !_lastProjectIds.asMap().entries.every(
                            (entry) => entry.value == currentIds[entry.key]);
                if (projectsChanged) {
                  _lastProjectIds = currentIds;
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
                          interactionOptions:
                              InteractionOptions(flags: InteractiveFlag.all),
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
                      right: 12,
                      child: _FloatingFiltersPanel(
                        filtersState: st,
                        onReset: filters.reset,
                      ),
                    ),
                    Positioned(
                      bottom: 12,
                      right: 12,
                      child: _ZoomControls(
                        zoom: _zoom,
                        minZoom: _minZoom,
                        maxZoom: _maxZoom,
                        onZoomIn: _zoomIn,
                        onZoomOut: _zoomOut,
                      ),
                    ),
                    Positioned(
                      bottom: 12,
                      left: 12,
                      child: _BaseMapControl(
                        value: _baseMapStyle,
                        onChanged: (style) {
                          setState(() => _baseMapStyle = style);
                        },
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
    );
  }

  void _runWhenMapReady(VoidCallback action) {
    if (_mapReady) action();
    else _pendingCameraAction = action;
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

class _FloatingFiltersPanel extends StatelessWidget {
  final FiltersState filtersState;
  final VoidCallback onReset;

  const _FloatingFiltersPanel({
    required this.filtersState,
    required this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    final activeFilters = _activeFilters(filtersState);
    final textTheme = Theme.of(context).textTheme;

    return Card(
      elevation: 8,
      shadowColor: Colors.black26,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 260),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
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
                      Icons.tune,
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
                  if (activeFilters.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Brand.primary.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        '${activeFilters.length}',
                        style: textTheme.labelSmall?.copyWith(
                          color: Brand.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              if (activeFilters.isEmpty)
                Text(
                  'Sin filtros aplicados',
                  style: textTheme.bodySmall?.copyWith(
                    color: Colors.grey.shade700,
                  ),
                )
              else
                ...activeFilters.map(
                  (filter) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text(
                      filter,
                      style: textTheme.bodySmall?.copyWith(
                        color: Colors.grey.shade800,
                      ),
                    ),
                  ),
                ),
              if (activeFilters.isNotEmpty) ...[
                const SizedBox(height: 6),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: onReset,
                    style: TextButton.styleFrom(
                      foregroundColor: Brand.primary,
                    ),
                    child: const Text('Limpiar'),
                  ),
                ),
              ],
            ],
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

class _BaseMapControl extends StatelessWidget {
  final BaseMapStyle value;
  final ValueChanged<BaseMapStyle> onChanged;

  const _BaseMapControl({
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 6,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: BaseMapStyle.values
              .map(
                (style) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Tooltip(
                    message: style.label,
                    child: InkResponse(
                      radius: 20,
                      onTap: () => onChanged(style),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 160),
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: value == style
                              ? Brand.primary.withOpacity(0.12)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: value == style
                                ? Brand.primary
                                : Colors.grey.shade300,
                          ),
                        ),
                        child: Icon(
                          style.icon,
                          size: 18,
                          color: value == style
                              ? Brand.primary
                              : Colors.grey.shade800,
                        ),
                      ),
                    ),
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
