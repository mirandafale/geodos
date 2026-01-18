import 'dart:math' as math;
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
        child: _ProjectsMap(mapCtrl: _mapCtrl, filters: filters),
      ),
    );
  }
}

class _ProjectsMap extends StatefulWidget {
  final MapController mapCtrl;
  final FiltersController filters;
  const _ProjectsMap({required this.mapCtrl, required this.filters});

  @override
  State<_ProjectsMap> createState() => _ProjectsMapState();
}

class _ProjectsMapState extends State<_ProjectsMap> {
  final _distance = const Distance();
  bool _mapReady = false;
  VoidCallback? _pendingCameraAction;
  double _zoom = 7;
  List<String> _lastProjectIds = const [];
  BaseMapStyle _baseMapStyle = BaseMapStyle.standard;

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

              final clusterColor =
              _dominantClusterColor(context, cluster.items);
              return Marker(
                point: cluster.center,
                width: 30,
                height: 30,
                child: GestureDetector(
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
                    ],
                  ),
                ),
              );
            }).toList();

            final currentIds = projects.map((p) => p.id).toList()..sort();
            final projectsChanged =
                currentIds.length != _lastProjectIds.length ||
                    !_lastProjectIds
                        .asMap()
                        .entries
                        .every((entry) => entry.value == currentIds[entry.key]);
            if (projectsChanged) {
              _lastProjectIds = currentIds;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!mounted) return;
                _runWhenMapReady(() {
                  if (projects.isNotEmpty) {
                    final latLngs =
                    projects.map((p) => LatLng(p.lat, p.lon)).toList();
                    final bounds = LatLngBounds.fromPoints(latLngs);
                    mapCtrl.fitCamera(
                      CameraFit.bounds(
                        bounds: bounds,
                        padding: const EdgeInsets.all(60),
                      ),
                    );
                  } else {
                    mapCtrl.move(center, 7);
                  }
                });
              });
            }

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
                    minZoom: 4,
                    maxZoom: 18,
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

                // 🧩 B3: Barra informativa dinámica
                if (projects.isNotEmpty)
                  Positioned(
                    left: 12,
                    bottom: 12,
                    right: 12,
                    child: _InfoBar(total: projects.length, filters: st),
                  ),

                // 🧩 Control de selección de mapa base
                Positioned(
                  top: 12,
                  right: 12,
                  child: _BaseMapControl(
                    value: _baseMapStyle,
                    onChanged: (style) =>
                        setState(() => _baseMapStyle = style),
                  ),
                ),

                if (projects.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(emptyMessage, textAlign: TextAlign.center),
                          const SizedBox(height: 10),
                          ElevatedButton.icon(
                            onPressed: filters.reset,
                            icon: const Icon(Icons.visibility),
                            label: const Text('Ver todos'),
                          ),
                          if (kDebugMode)
                            const SizedBox(height: 14),
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
        final maxWidth = math.min(720.0, size.width * 0.9);
        final maxHeight = size.height * 0.75;
        final desiredHeight = (56 + projects.length * 64 + 40)
            .clamp(220.0, maxHeight)
            .toDouble();

        return Dialog(
          child: SizedBox(
            width: maxWidth,
            height: desiredHeight,
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
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: projects.length,
                    separatorBuilder: (_, __) => const Divider(),
                    itemBuilder: (_, i) {
                      final p = projects[i];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor:
                          _categoryColor(dialogContext, p.category),
                          radius: 6,
                        ),
                        title: Text(p.title, maxLines: 2),
                        trailing: TextButton(
                          onPressed: () {
                            Navigator.pop(dialogContext);
                            _runWhenMapReady(() {
                              widget.mapCtrl.move(
                                LatLng(p.lat, p.lon),
                                _zoom < 13 ? 13 : _zoom,
                              );
                            });
                          },
                          child: const Text('Ver'),
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

  Color _categoryColor(BuildContext context, String category) {
    final c = category.toUpperCase();
    if (c.contains('MEDIOAMBIENTE')) return const Color(0xFF1B8A3D);
    if (c.contains('ORDENACION') || c.contains('ORDENACIÓN'))
      return const Color(0xFF1565C0);
    if (c.contains('PATRIMONIO')) return const Color(0xFF6D4C41);
    if (c.contains('DESARROLLO')) return const Color(0xFF00897B);
    if (c.contains('SISTEMAS')) return const Color(0xFF3949AB);
    return Theme.of(context).colorScheme.primary;
  }

  Color _dominantClusterColor(
      BuildContext context, List<Project> projects) {
    final counts = <String, int>{};
    for (final p in projects) {
      counts[p.category] = (counts[p.category] ?? 0) + 1;
    }
    final top = counts.entries.reduce(
            (a, b) => a.value >= b.value ? a : b);
    return _categoryColor(context, top.key);
  }
}

class _InfoBar extends StatelessWidget {
  final int total;
  final FiltersState filters;

  const _InfoBar({required this.total, required this.filters});

  String _formatLabel() {
    final parts = <String>[];
    if (filters.category?.isNotEmpty ?? false) parts.add(filters.category!);
    if (filters.island?.isNotEmpty ?? false) parts.add(filters.island!);
    if (filters.year != null) parts.add(filters.year.toString());
    if (parts.isEmpty) return 'Todos los proyectos';
    return parts.join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme.surface.withOpacity(0.9);
    final textColor = theme.colorScheme.onSurface;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 2)),
        ],
      ),
      child: DefaultTextStyle(
        style: theme.textTheme.bodySmall!.copyWith(
          color: textColor,
          fontWeight: FontWeight.w600,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(_formatLabel()),
            Text('Mostrando $total proyecto${total == 1 ? '' : 's'}'),
          ],
        ),
      ),
    );
  }
}

enum BaseMapStyle {
  standard(
    label: 'Estándar',
    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
    icon: Icons.map,
  ),
  satellite(
    label: 'Satélite',
    urlTemplate:
    'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}',
    icon: Icons.satellite_alt,
  ),
  terrain(
    label: 'Relieve',
    urlTemplate: 'https://tile.opentopomap.org/{z}/{x}/{y}.png',
    icon: Icons.terrain,
  );

  final String label;
  final String urlTemplate;
  final IconData icon;
  const BaseMapStyle({
    required this.label,
    required this.urlTemplate,
    required this.icon,
  });
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
      elevation: 3,
      color: Colors.white.withOpacity(0.9),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: BaseMapStyle.values.map((style) {
          return IconButton(
            tooltip: style.label,
            icon: Icon(
              style.icon,
              color:
              style == value ? Theme.of(context).primaryColor : Colors.grey,
            ),
            onPressed: () => onChanged(style),
          );
        }).toList(),
      ),
    );
  }
}

class _ProjectCluster {
  _ProjectCluster(this.center, this.items);
  LatLng center;
  final List<Project> items;

  void recenter() {
    var lat = 0.0, lon = 0.0;
    for (final p in items) {
      lat += p.lat;
      lon += p.lon;
    }
    center = LatLng(lat / items.length, lon / items.length);
  }
}
