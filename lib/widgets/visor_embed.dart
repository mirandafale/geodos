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
  BaseMapStyle _baseMapStyle = BaseMapStyle.standard;

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

  void _onBaseMapChanged(BaseMapStyle style) {
    setState(() => _baseMapStyle = style);
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
          baseMapStyle: _baseMapStyle,
          onBaseMapChanged: _onBaseMapChanged,
        ),
      ),
    );
  }
}

class _ProjectsMap extends StatefulWidget {
  final MapController mapCtrl;
  final FiltersController filters;
  final BaseMapStyle baseMapStyle;
  final ValueChanged<BaseMapStyle> onBaseMapChanged;

  const _ProjectsMap({
    required this.mapCtrl,
    required this.filters,
    required this.baseMapStyle,
    required this.onBaseMapChanged,
  });

  @override
  State<_ProjectsMap> createState() => _ProjectsMapState();
}

class _ProjectsMapState extends State<_ProjectsMap> {
  final _distance = const Distance();
  bool _mapReady = false;
  VoidCallback? _pendingCameraAction;
  double _zoom = 7;
  List<Project> _lastProjects = const [];

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
                width: 28,
                height: 28,
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
                    ],
                  ),
                ),
              );
            }).toList();

            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;
              _lastProjects = projects;
            });

            return Stack(
              children: [
                FlutterMap(
                  mapController: mapCtrl,
                  options: MapOptions(
                    initialCenter: center,
                    initialZoom: 7,
                    minZoom: 4,
                    maxZoom: 18,
                    onMapEvent: (event) {
                      if (!mounted) return;
                      if (_zoom != event.camera.zoom) {
                        setState(() => _zoom = event.camera.zoom);
                      }
                    },
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: widget.baseMapStyle.urlTemplate,
                      userAgentPackageName: 'geodos.app',
                      tileProvider: NetworkTileProvider(),
                    ),
                    MarkerLayer(markers: markers),
                  ],
                ),
                Positioned(
                  top: 12,
                  right: 12,
                  child: _BaseMapControl(
                    value: widget.baseMapStyle,
                    onChanged: widget.onBaseMapChanged,
                  ),
                ),
                Positioned(
                  bottom: 12,
                  right: 12,
                  child: _ZoomControls(
                    onZoomIn: () {
                      mapCtrl.move(mapCtrl.camera.center, _zoom + 1);
                    },
                    onZoomOut: () {
                      mapCtrl.move(mapCtrl.camera.center, _zoom - 1);
                    },
                    onCenter: () {
                      if (_lastProjects.isEmpty) return;
                      final latLngs =
                      _lastProjects.map((p) => LatLng(p.lat, p.lon)).toList();
                      final bounds = LatLngBounds.fromPoints(latLngs);
                      mapCtrl.fitCamera(CameraFit.bounds(
                        bounds: bounds,
                        padding: const EdgeInsets.all(60),
                      ));
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
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

        return Dialog(
          child: SizedBox(
            width: maxWidth,
            height: dialogHeight,
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: projects.length,
              separatorBuilder: (_, __) => const Divider(height: 24),
              itemBuilder: (_, index) {
                final project = projects[index];
                return Row(
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
                      child: Text(project.title,
                          maxLines: 2, overflow: TextOverflow.ellipsis),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.of(dialogContext).pop();
                        final target = LatLng(project.lat, project.lon);
                        final double targetZoom = _zoom < 13.0 ? 13.0 : _zoom;
                        widget.mapCtrl.move(target, targetZoom);
                      },
                      child: const Text('Ver'),
                    ),
                  ],
                );
              },
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
  const _BaseMapControl({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      elevation: 5,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: BaseMapStyle.values.map((style) {
          final selected = style == value;
          return IconButton(
            tooltip: style.label,
            icon: Icon(
              style.icon,
              color: selected
                  ? Theme.of(context).colorScheme.primary
                  : Colors.grey.shade600,
            ),
            onPressed: () => onChanged(style),
          );
        }).toList(),
      ),
    );
  }
}

class _ZoomControls extends StatelessWidget {
  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;
  final VoidCallback onCenter;
  const _ZoomControls({
    required this.onZoomIn,
    required this.onZoomOut,
    required this.onCenter,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: 'Acercar',
            icon: const Icon(Icons.add),
            onPressed: onZoomIn,
          ),
          const Divider(height: 1),
          IconButton(
            tooltip: 'Alejar',
            icon: const Icon(Icons.remove),
            onPressed: onZoomOut,
          ),
          const Divider(height: 1),
          IconButton(
            tooltip: 'Centrar mapa',
            icon: const Icon(Icons.my_location),
            onPressed: onCenter,
          ),
        ],
      ),
    );
  }
}
