// visor_embed.dart — visor estable + gate MapController + clustering por proximidad

import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import 'package:geodos/brand/brand.dart';
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
  late bool _expanded;
  OverlayEntry? _backdrop;

  final MapController _mapCtrl = MapController();
  final GlobalKey _legendKey = GlobalKey();

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
      duration: const Duration(milliseconds: 350),
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

  void _runWhenMapReady(VoidCallback action) {
    if (_mapReady) {
      action();
    } else {
      _pendingCameraAction = action;
    }
  }

  @override
  Widget build(BuildContext context) {
    const center = LatLng(28.2916, -16.6291);

    return AnimatedBuilder(
      animation: widget.filters,
      builder: (ctx, _) {
        final st = widget.filters.state;

        return StreamBuilder<List<Project>>(
          stream: ProjectService.stream(
            year: st.year,
            category: st.category,
            scope: st.scope,
            island: st.island,
            search: st.search,
          ),
          builder: (ctx, snap) {
            final projects = snap.data ?? const <Project>[];

            // (2) Construcción de markers usando clusters (por proximidad)
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
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => _openProjectDialog(context, project),
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
                  ),
                );
              }

              return Marker(
                point: cluster.center,
                width: 28,
                height: 28,
                child: Tooltip(
                  message: '${cluster.items.length} proyectos',
                  child: _ClusterMarker(
                    count: cluster.items.length,
                    color: _dominantClusterColor(context, cluster.items),
                    onTap: () => _openClusterSheet(context, cluster.items),
                  ),
                ),
              );
            }).toList();

            // Fit bounds / move center con gate de MapController
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;

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

                _runWhenMapReady(() {
                  widget.mapCtrl.fitCamera(
                    CameraFit.bounds(
                      bounds: bounds,
                      padding: const EdgeInsets.all(60),
                    ),
                  );
                });
              } else {
                _runWhenMapReady(() => widget.mapCtrl.move(center, 7));
              }
            });

            return Stack(
              children: [
                FlutterMap(
                  mapController: widget.mapCtrl,
                  options: MapOptions(
                    initialCenter: center,
                    initialZoom: 7,
                    onMapReady: () {
                      if (!mounted) return;
                      setState(() => _mapReady = true);
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
                    const InteractionOptions(flags: InteractiveFlag.all),
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

                // Leyenda compacta y discreta
                Positioned(
                  right: 10,
                  bottom: 10,
                  child: _CompactLegend(
                    key: widget.legendKey,
                    total: projects.length,
                    categories:
                    projects.map((p) => p.category).toSet().toList(),
                    colorForCategory: (c) => _categoryColor(context, c),
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
                            ProjectService.lastRemoteCount == 0
                                ? 'No hay proyectos disponibles desde Firestore.\nAñade un proyecto o ajusta los filtros.'
                                : 'No hay proyectos visibles con los filtros actuales.',
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 10),
                          ElevatedButton.icon(
                            onPressed: widget.filters.reset,
                            icon: const Icon(Icons.visibility),
                            label: const Text('Ver todos'),
                          ),
                          if (kDebugMode && snap.hasError) ...[
                            const SizedBox(height: 10),
                            Text(
                              'Error: ${snap.error}',
                              textAlign: TextAlign.center,
                            ),
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
    );
  }

  // (1) Clustering por proximidad (en metros), con merge si un punto toca varios clusters
  List<_ProjectCluster> _buildClusters(List<Project> projects, double zoom) {
    final threshold = _clusterThresholdMeters(zoom);
    final clusters = <_ProjectCluster>[];

    for (final project in projects) {
      final point = LatLng(project.lat, project.lon);
      final matchingClusters = <_ProjectCluster>[];

      for (final cluster in clusters) {
        for (final item in cluster.items) {
          final distance = _distance.as(
            LengthUnit.Meter,
            point,
            LatLng(item.lat, item.lon),
          );
          if (distance <= threshold) {
            matchingClusters.add(cluster);
            break;
          }
        }
      }

      if (matchingClusters.isEmpty) {
        clusters.add(_ProjectCluster(point, [project]));
      } else {
        final target = matchingClusters.first;
        target.items.add(project);

        if (matchingClusters.length > 1) {
          final mergedClusters = matchingClusters.skip(1).toList();
          for (final cluster in mergedClusters) {
            target.items.addAll(cluster.items);
            clusters.remove(cluster);
          }
        }

        target.recenter();
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

  // (4) BottomSheet con lista de proyectos
  void _openClusterSheet(BuildContext context, List<Project> projects) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      isDismissible: true,
      enableDrag: true,
      showDragHandle: true,
      builder: (sheetContext) {
        final screenHeight = MediaQuery.of(sheetContext).size.height;
        final maxHeight = screenHeight * 0.6;
        const headerHeight = 56.0;
        const itemHeight = 60.0;
        final listPadding = projects.isEmpty ? 24.0 : 28.0;
        final desiredHeight =
            headerHeight + (projects.length * itemHeight) + listPadding;
        final minHeight = headerHeight + listPadding;
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
                          'Proyectos (${projects.length})',
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
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: _categoryColor(context, project.category),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              project.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                          ),
                          const SizedBox(width: 12),
                          TextButton(
                            onPressed: () {
                              Navigator.of(sheetContext).pop();
                              _runWhenMapReady(() {
                                final target = LatLng(project.lat, project.lon);
                                final double targetZoom = math.max(_zoom, 13.0);
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
        );
      },
    );
  }

  void _openProjectDialog(BuildContext context, Project proj) {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(proj.title),
        content: Text((proj.description ?? '').trim().isEmpty
            ? '${proj.category} · ${proj.year ?? 's/f'}'
            : proj.description!.trim()),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  // Colores más diferenciables (si Brand.primary existe, lo respetamos para “ordenación”)
  Color _categoryColor(BuildContext context, String category) {
    final c = category.toUpperCase();

    if (c.contains('IMPACTO') ||
        c.contains('AMBIENTAL') ||
        c.contains('MEDIOAMBIENTE')) {
      return const Color(0xFF1B8A3D); // verde
    }

    if (c.contains('URBANISMO') ||
        c.contains('ORDENACION') ||
        c.contains('ORDENACIÓN')) {
      return const Color(0xFF1565C0); // azul
    }

    if (c.contains('PAISAJE')) return const Color(0xFF00897B); // teal

    if (c.contains('PATRIMONIO') || c.contains('GEODIVERSIDAD')) {
      return const Color(0xFF6D4C41); // marrón
    }

    if (c.contains('SIG') ||
        c.contains('SISTEMA DE INFORMACION GEOGRAFICA') ||
        c.contains('SISTEMA DE INFORMACIÓN GEOGRÁFICA')) {
      return const Color(0xFF3949AB); // índigo
    }

    if (c.contains('GEOMARKETING')) return const Color(0xFF8E24AA); // púrpura

    // fallback (más consistente que Theme a secas)
    return Brand.primary;
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

// (3) Widget marker de cluster
class _ClusterMarker extends StatelessWidget {
  final int count;
  final Color color;
  final VoidCallback onTap;

  const _ClusterMarker({
    required this.count,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 1.5),
          boxShadow: const [
            BoxShadow(color: Colors.black26, blurRadius: 3),
          ],
        ),
        alignment: Alignment.center,
        child: Text(
          '$count',
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 12,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

// Leyenda compacta (para que no se coma el visor)
class _CompactLegend extends StatelessWidget {
  final int total;
  final List<String> categories;
  final Color Function(String) colorForCategory;

  const _CompactLegend({
    super.key,
    required this.total,
    required this.categories,
    required this.colorForCategory,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final sorted = [...categories]
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

    return Material(
      color: theme.colorScheme.surface.withOpacity(0.92),
      elevation: 2,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () {
          showModalBottomSheet<void>(
            context: context,
            showDragHandle: true,
            builder: (ctx) => SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Leyenda ($total)',
                          style: theme.textTheme.titleSmall,
                        ),
                        const Spacer(),
                        IconButton(
                          onPressed: () => Navigator.of(ctx).pop(),
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                    const Divider(height: 1),
                    const SizedBox(height: 12),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 240),
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: sorted.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (_, i) {
                          final raw = sorted[i];
                          return Row(
                            children: [
                              Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                  color: colorForCategory(raw),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  raw,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.bodySmall,
                                ),
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
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.layers_outlined, size: 16),
              const SizedBox(width: 8),
              Text(
                'Proyectos: $total',
                style: theme.textTheme.labelMedium
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.expand_more, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}
