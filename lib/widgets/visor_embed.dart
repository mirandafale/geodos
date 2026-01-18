import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import 'package:geodos/models/project.dart';
import 'package:geodos/services/filters_controller.dart';
import 'package:geodos/services/project_service.dart';

/// ===============================================================
///  GEODOS VISOR — Bloque B1
///  Selector de mapa base: Estándar / Satélite / Relieve
/// ===============================================================
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

  // 🔹 Nuevo: tipo de mapa base (Bloque B1)
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
          baseMapStyle: _baseMapStyle,
          onBaseMapChanged: (style) =>
              setState(() => _baseMapStyle = style),
        ),
      ),
    );
  }
}

/// ===============================================================
///  Subwidget principal con mapa + controles + leyenda
/// ===============================================================
class _ProjectsMap extends StatefulWidget {
  final MapController mapCtrl;
  final FiltersController filters;
  final GlobalKey legendKey;
  final BaseMapStyle baseMapStyle;
  final ValueChanged<BaseMapStyle> onBaseMapChanged;

  const _ProjectsMap({
    required this.mapCtrl,
    required this.filters,
    required this.legendKey,
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
  List<String> _lastProjectIds = const [];

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
              final clusterColor =
              _dominantClusterColor(context, cluster.items);
              return Marker(
                point: cluster.center,
                width: 28,
                height: 28,
                child: Tooltip(
                  message: '${cluster.items.length} proyectos',
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
                ),
              );
            }).toList();

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
                      _mapReady = true;
                      _pendingCameraAction?.call();
                      _pendingCameraAction = null;
                    },
                    onMapEvent: (event) {
                      if (_zoom != event.camera.zoom) {
                        setState(() => _zoom = event.camera.zoom);
                      }
                    },
                  ),
                  children: [
                    // 🔹 Capa base seleccionable
                    TileLayer(
                      urlTemplate: _mapUrl(widget.baseMapStyle),
                      userAgentPackageName: 'geodos.app',
                      tileProvider: NetworkTileProvider(),
                    ),
                    MarkerLayer(markers: markers),
                  ],
                ),

                if (projects.isEmpty)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(12),
                      child: Text('No hay proyectos visibles con los filtros actuales.'),
                    ),
                  ),

                // 🔹 Leyenda (izquierda)
                Positioned(
                  top: 12,
                  left: 12,
                  child: _Legend(
                    key: widget.legendKey,
                    filtersState: st,
                  ),
                ),

                // 🔹 Selector de mapa base (Bloque B1)
                Positioned(
                  top: 12,
                  right: 12,
                  child: _BaseMapSelector(
                    current: widget.baseMapStyle,
                    onChanged: widget.onBaseMapChanged,
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  String _mapUrl(BaseMapStyle style) {
    switch (style) {
      case BaseMapStyle.satellite:
        return 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}';
      case BaseMapStyle.terrain:
        return 'https://tile.opentopomap.org/{z}/{x}/{y}.png';
      default:
        return 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
    }
  }

  List<_ProjectCluster> _buildClusters(List<Project> projects, double zoom) {
    final threshold = zoom >= 13
        ? 60
        : zoom >= 11
        ? 120
        : zoom >= 9
        ? 250
        : 450;
    final clusters = <_ProjectCluster>[];
    final distance = const Distance();

    for (final project in projects) {
      final point = LatLng(project.lat, project.lon);
      _ProjectCluster? match;
      for (final cluster in clusters) {
        for (final item in cluster.items) {
          if (distance.as(LengthUnit.Meter, point, LatLng(item.lat, item.lon)) <=
              threshold) {
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

  Color _categoryColor(BuildContext context, String category) {
    final c = category.toUpperCase();
    if (c.contains('MEDIOAMBIENTE')) return Colors.green.shade700;
    if (c.contains('ORDENACION') || c.contains('ORDENACIÓN')) return Colors.blue.shade700;
    if (c.contains('PATRIMONIO')) return Colors.brown.shade700;
    return Theme.of(context).colorScheme.primary;
  }

  Color _dominantClusterColor(BuildContext context, List<Project> projects) {
    final counts = <String, int>{};
    for (final p in projects) {
      counts[p.category] = (counts[p.category] ?? 0) + 1;
    }
    final dominant = counts.entries.reduce((a, b) => a.value > b.value ? a : b).key;
    return _categoryColor(context, dominant);
  }

  void _openClusterSheet(BuildContext context, List<Project> projects) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Proyectos (${projects.length})'),
        content: SizedBox(
          width: math.min(MediaQuery.of(context).size.width * 0.8, 500),
          child: ListView.builder(
            itemCount: projects.length,
            itemBuilder: (_, i) => ListTile(
              title: Text(projects[i].title),
              subtitle: Text(projects[i].category),
            ),
          ),
        ),
      ),
    );
  }
}

/// ===============================================================
///  Selector visual del mapa base
/// ===============================================================
enum BaseMapStyle { standard, satellite, terrain }

class _BaseMapSelector extends StatelessWidget {
  final BaseMapStyle current;
  final ValueChanged<BaseMapStyle> onChanged;

  const _BaseMapSelector({
    required this.current,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    IconData iconFor(BaseMapStyle style) {
      switch (style) {
        case BaseMapStyle.satellite:
          return Icons.satellite_alt_outlined;
        case BaseMapStyle.terrain:
          return Icons.terrain_outlined;
        default:
          return Icons.map_outlined;
      }
    }

    return Card(
      color: theme.colorScheme.surface,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: BaseMapStyle.values.map((style) {
          final isSelected = style == current;
          return IconButton(
            tooltip: style.name[0].toUpperCase() + style.name.substring(1),
            onPressed: () => onChanged(style),
            icon: Icon(
              iconFor(style),
              color: isSelected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurfaceVariant,
            ),
          );
        }).toList(),
      ),
    );
  }
}

/// ===============================================================
///  Estructuras auxiliares (clusters, leyenda, debug)
/// ===============================================================
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

class _Legend extends StatelessWidget {
  final FiltersState filtersState;
  const _Legend({super.key, required this.filtersState});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final st = filtersState;
    final filters = <String>[];
    if (st.category != null && st.category!.trim().isNotEmpty)
      filters.add('Categoría: ${st.category}');
    if (st.island != null && st.island!.trim().isNotEmpty)
      filters.add('Isla: ${st.island}');
    if (st.scope != null) filters.add('Ámbito: ${st.scope!.name}');
    if (st.year != null) filters.add('Año: ${st.year}');
    if (st.search.isNotEmpty) filters.add('Búsqueda: "${st.search}"');

    return Card(
      elevation: 4,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: filters.isEmpty
            ? Text('Sin filtros', style: t.labelSmall)
            : Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: filters
              .map((f) => Text(f, style: t.labelSmall))
              .toList(),
        ),
      ),
    );
  }
}
