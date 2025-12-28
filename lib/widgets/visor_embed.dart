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
import 'package:geodos/brand/brand.dart';


class VisorEmbed extends StatefulWidget {
  const VisorEmbed({super.key, this.startExpanded = false});

  final bool startExpanded;

  @override
  State<VisorEmbed> createState() => _VisorEmbedState();
}

class _VisorEmbedState extends State<VisorEmbed> {
  late final MapController _mapCtrl;
  late final FiltersController filters;

  @override
  void initState() {
    super.initState();
    _mapCtrl = MapController();
    filters = FiltersController.instance;
  }

  @override
  Widget build(BuildContext context) {
    return _ProjectsMap(
      mapCtrl: _mapCtrl,
      filters: filters,
      startExpanded: widget.startExpanded,
    );
  }
}

class _ProjectsMap extends StatefulWidget {
  const _ProjectsMap({
    required this.mapCtrl,
    required this.filters,
    required this.startExpanded,
  });

  final MapController mapCtrl;
  final FiltersController filters;
  final bool startExpanded;

  @override
  State<_ProjectsMap> createState() => _ProjectsMapState();
}

class _ProjectsMapState extends State<_ProjectsMap> {
  final _distance = const Distance();

  OverlayEntry? _backdrop;
  bool _expanded = false;
  double _zoom = 7;

  // --- Map readiness gate (avoid using MapController before FlutterMap renders) ---

  bool _mapReady = false;
  VoidCallback? _pendingCameraAction;


  Color _categoryColor(BuildContext context, String category) {
    final c = category.trim().toLowerCase();

    if (c.contains('impacto')) return Colors.green.shade700;
    if (c.contains('urban')) return Colors.blue.shade700;
    if (c.contains('paisaje')) return Colors.teal.shade700;
    if (c.contains('patrimonio')) return Colors.brown.shade700;
    if (c.contains('sig') || c.contains('información')) return Colors.indigo.shade700;
    if (c.contains('geomarketing')) return Colors.deepPurple.shade700;

    return Theme.of(context).colorScheme.primary;
  }

  void _runWhenMapReady(VoidCallback action) {
    if (_mapReady) {
      action();
    } else {
      _pendingCameraAction = action;
    }
  }

  @override
  void initState() {
    super.initState();
    _expanded = widget.startExpanded;
  }

  @override
  void dispose() {
    _backdrop?.remove();
    _backdrop = null;
    super.dispose();
  }

  double get _targetHeight =>
      _expanded ? MediaQuery.of(context).size.height * 0.8 : 360;

  void _showBackdrop() {
    if (_backdrop != null) return;
    final topOffset = MediaQuery.of(context).padding.top + kToolbarHeight;
    _backdrop = OverlayEntry(
      builder: (_) => Positioned(
        left: 0,
        right: 0,
        top: topOffset,
        bottom: 0,
        child: GestureDetector(
          onTap: _hideBackdrop,
          child: Container(color: Colors.black.withOpacity(0.15)),
        ),
      ),
    );
    Overlay.of(context).insert(_backdrop!);
  }

  void _hideBackdrop() {
    _backdrop?.remove();
    _backdrop = null;
    if (_expanded) setState(() => _expanded = false);
  }

  @override
  Widget build(BuildContext context) {
    final center = const LatLng(28.3, -15.5);

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
            final projects = snap.data ?? [];

            final clusters = _buildClusters(projects, _zoom);
            final markers = clusters.map((cluster) {
              if (cluster.items.length == 1) {
                final proj = cluster.items.first;
                return Marker(
                  point: cluster.center,
                  width: 40,
                  height: 40,
                  child: Tooltip(
                    message: proj.title,
                    child: InkWell(
                      onTap: () => _openProjectDialog(context, proj),
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _categoryColor(context, category)
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(Icons.place, color: Colors.white),
                      ),
                    ),
                  ),
                );
              }

              return Marker(
                point: cluster.center,
                width: 30,
                height: 30,
                child: Tooltip(
                  message: '${cluster.items.length} proyectos',
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => _openClusterSheet(context, cluster.items),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Brand.categoryColor(
                          context,
                          _dominantCategory(cluster.items),
                        ),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1.5),
                        boxShadow: const [
                          BoxShadow(color: Colors.black26, blurRadius: 4),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          '${cluster.items.length}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList();

            // Ajuste de cámara: usar MapController solo cuando el mapa esté listo.
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

                final bounds =
                LatLngBounds(LatLng(swLat, swLng), LatLng(neLat, neLng));

                _runWhenMapReady(() {
                  widget.mapCtrl.fitCamera(
                    CameraFit.bounds(
                      bounds: bounds,
                      padding: const EdgeInsets.all(60),
                    ),
                  );
                });
              } else {
                _runWhenMapReady(() {
                  widget.mapCtrl.move(center, 7);
                });
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
                _LegendOverlay(
                  expanded: _expanded,
                  targetHeight: _targetHeight,
                  onOpen: () {
                    if (_expanded) return;
                    setState(() => _expanded = true);
                    _showBackdrop();
                  },
                  onClose: _hideBackdrop,
                  category: st.category,
                  scope: st.scope?.name,
                  island: st.island,
                  year: st.year,
                  search: st.search,
                ),
                if (projects.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            (snap.hasError ? snap.error.toString() : 'No hay proyectos que coincidan con el filtro.'),
                            textAlign: TextAlign.center,
                          ),
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

  String _dominantCategory(List<Project> items) {
    final counts = <String, int>{};
    for (final p in items) {
      counts[p.category] = (counts[p.category] ?? 0) + 1;
    }
    var bestKey = items.first.category;
    var bestVal = -1;
    for (final e in counts.entries) {
      if (e.value > bestVal) {
        bestVal = e.value;
        bestKey = e.key;
      }
    }
    return bestKey;
  }

  List<_Cluster> _buildClusters(List<Project> projects, double zoom) {
    final thresholdMeters = _thresholdForZoom(zoom);

    final clusters = <_Cluster>[];
    for (final p in projects) {
      final point = LatLng(p.lat, p.lon);

      _Cluster? found;
      for (final c in clusters) {
        final d = _distance.as(LengthUnit.Meter, c.center, point);
        if (d <= thresholdMeters) {
          found = c;
          break;
        }
      }

      if (found == null) {
        clusters.add(_Cluster(center: point, items: [p]));
      } else {
        found.items.add(p);
        found.center = _averageLatLng(found.items);
      }
    }
    return clusters;
  }

  double _thresholdForZoom(double zoom) {
    if (zoom >= 13) return 60;
    if (zoom >= 11) return 120;
    if (zoom >= 9) return 250;
    return 450;
  }

  LatLng _averageLatLng(List<Project> items) {
    var lat = 0.0;
    var lng = 0.0;
    for (final p in items) {
      lat += p.lat;
      lng += p.lon;
    }
    return LatLng(lat / items.length, lng / items.length);
  }

  void _openProjectDialog(BuildContext context, Project proj) {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(proj.title),
        content: Text(proj.description ?? ''),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  void _openClusterSheet(BuildContext context, List<Project> projects) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) {
        return SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              const headerH = 52.0;
              const rowH = 64.0;
              const paddingV = 24.0;

              final desired = headerH + (projects.length * rowH) + paddingV;
              final maxH = constraints.maxHeight * 0.60;
              final sheetH = desired.clamp(160.0, maxH);

              return SizedBox(
                height: sheetH,
                child: Column(
                  children: [
                    SizedBox(
                      height: headerH,
                      child: Row(
                        children: [
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              'Proyectos (${projects.length})',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ),
                          IconButton(
                            tooltip: 'Cerrar',
                            onPressed: () => Navigator.of(sheetContext).pop(),
                            icon: const Icon(Icons.close),
                          ),
                          const SizedBox(width: 4),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    Expanded(
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                        itemCount: projects.length,
                        separatorBuilder: (_, __) =>
                        const Divider(height: 24),
                        itemBuilder: (_, index) {
                          final project = projects[index];

                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                margin: const EdgeInsets.only(top: 4),
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                  color: _categoryColor(
                                      context, _dominantCategory(cluster.items),)
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
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleSmall,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${project.category} · ${project.year ?? 's/f'}',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              TextButton(
                                onPressed: () {
                                  Navigator.of(sheetContext).pop();
                                  final target =
                                  LatLng(project.lat, project.lon);
                                  final nextZoom = math.max(_zoom, 13);

                                  _runWhenMapReady(() {
                                    widget.mapCtrl.move(
                                        target, nextZoom.toDouble());
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
              );
            },
          ),
        );
      },
    );
  }
}

class _Cluster {
  _Cluster({required this.center, required this.items});
  LatLng center;
  final List<Project> items;
}

class _LegendOverlay extends StatelessWidget {
  const _LegendOverlay({
    required this.expanded,
    required this.targetHeight,
    required this.onOpen,
    required this.onClose,
    required this.category,
    required this.scope,
    required this.island,
    required this.year,
    required this.search,
  });

  final bool expanded;
  final double targetHeight;
  final VoidCallback onOpen;
  final VoidCallback onClose;

  final String? category;
  final String? scope;
  final String? island;
  final int? year;
  final String? search;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 12,
      top: 12,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        width: 300,
        height: expanded ? targetHeight : 48,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.95),
          borderRadius: BorderRadius.circular(14),
          boxShadow: const [
            BoxShadow(color: Colors.black26, blurRadius: 10),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: expanded ? null : onOpen,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: expanded
                  ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.info_outline, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Filtros activos',
                          style: Theme.of(context)
                              .textTheme
                              .titleSmall,
                        ),
                      ),
                      IconButton(
                        tooltip: 'Cerrar',
                        onPressed: onClose,
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _summaryText(),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Toca un marcador para ver detalles.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              )
                  : Row(
                children: [
                  const Icon(Icons.filter_alt_outlined, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Filtros',
                      style:
                      Theme.of(context).textTheme.titleSmall,
                    ),
                  ),
                  const Icon(Icons.expand_more),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _summaryText() {
    final parts = <String>[
      if ((category ?? '').isNotEmpty) 'categoría: $category',
      if ((scope ?? '').isNotEmpty) 'ámbito: $scope',
      if ((island ?? '').isNotEmpty) 'isla: $island',
      if (year != null) 'año: $year',
      if ((search ?? '').isNotEmpty) 'busca: "$search"',
    ];
    return parts.join(' · ');
  }
}
