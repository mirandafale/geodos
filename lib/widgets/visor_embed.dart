import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import 'package:latlong2/latlong.dart';

import 'package:geodos/brand/brand.dart';
import 'package:geodos/models/project.dart';
import 'package:geodos/services/filters_controller.dart';
import 'package:geodos/services/project_service.dart';

class VisorEmbed extends StatefulWidget {
  final bool startExpanded;
  final double? baseHeight;

  const VisorEmbed({super.key, this.startExpanded = false, this.baseHeight});

  @override
  State<VisorEmbed> createState() => _VisorEmbedState();
}

class _VisorEmbedState extends State<VisorEmbed> {
  late bool _expanded;
  OverlayEntry? _backdrop;
  final _mapCtrl = MapController();
  final _legendKey = GlobalKey();
  _BaseMapStyle _baseMapStyle = _BaseMapStyle.standard;

  @override
  void initState() {
    super.initState();
    _expanded = widget.startExpanded;
  }

  double get _targetHeight =>
      _expanded ? MediaQuery.of(context).size.height * 0.8 : (widget.baseHeight ?? 360);

  void _showBackdrop() {
    if (_backdrop != null) return;
    _backdrop = OverlayEntry(
      builder: (_) => Positioned.fill(
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
          onBaseMapChanged: (style) => setState(() => _baseMapStyle = style),
        ),
      ),
    );
  }
}

class _ProjectsMap extends StatefulWidget {
  final MapController mapCtrl;
  final FiltersController filters;
  final GlobalKey legendKey;
  final _BaseMapStyle baseMapStyle;
  final ValueChanged<_BaseMapStyle> onBaseMapChanged;

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
            final projects = snap.data ?? [];

            final markers = projects
                .map((p) {
              final color = _colorForCategory(context, p.category);
              return Marker(
                point: LatLng(p.lat, p.lon),
                width: 40,
                height: 40,
                child: Tooltip(
                  message: '${p.title}\n${p.category} · ${p.year ?? 's/f'}',
                  child: Icon(
                    Icons.location_pin,
                    color: color,
                    size: 36,
                  ),
                ),
              );
            })
                .toList();

            WidgetsBinding.instance.addPostFrameCallback((_) {
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
                widget.mapCtrl.fitCamera(
                  CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(60)),
                );
              } else {
                widget.mapCtrl.move(center, 7);
              }
            });

            return Stack(
              children: [
                FlutterMap(
                  mapController: widget.mapCtrl,
                  options: MapOptions(
                    initialCenter: center,
                    initialZoom: 7,
                    interactionOptions: const InteractionOptions(flags: InteractiveFlag.all),
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: widget.baseMapStyle.urlTemplate,
                      userAgentPackageName: 'geodos.app',
                      tileProvider: NetworkTileProvider(),
                    ),
                    MarkerClusterLayerWidget(
                      options: MarkerClusterLayerOptions(
                        maxClusterRadius: 45,
                        size: const Size(40, 40),
                        alignment: Alignment.center,
                        padding: const EdgeInsets.all(50),
                        maxZoom: 16,
                        markers: markers,
                        builder: (context, clusterMarkers) => Container(
                          decoration: BoxDecoration(
                            color: Brand.primary,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: Center(
                            child: Text(
                              clusterMarkers.length.toString(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
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
                  child: _MapActionControls(mapCtrl: widget.mapCtrl),
                ),
                if (projects.isEmpty)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(12.0),
                      child: Text('No hay proyectos visibles con los filtros actuales.'),
                    ),
                  ),
                Positioned(
                  bottom: 68,
                  left: 12,
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

  Color _colorForCategory(BuildContext context, String category) {
    final c = category.toUpperCase();
    if (c.contains('MEDIOAMBIENTE')) return Colors.green.shade700;
    if (c.contains('ORDENACION') || c.contains('ORDENACIÓN')) return Brand.primary;
    if (c.contains('PATRIMONIO')) return Colors.purple.shade700;
    if (c.contains('SISTEMAS')) return Colors.brown.shade700;
    if (c.contains('ESTUDIOS') || c.contains('DESARROLLO')) return Colors.teal.shade700;
    return Brand.secondary;
  }
}

enum _BaseMapStyle {
  standard(
    label: 'Estándar',
    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
  ),
  satellite(
    label: 'Satélite',
    urlTemplate:
    'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}',
  );

  final String label;
  final String urlTemplate;

  const _BaseMapStyle({
    required this.label,
    required this.urlTemplate,
  });
}

class _BaseMapControl extends StatelessWidget {
  final _BaseMapStyle value;
  final ValueChanged<_BaseMapStyle> onChanged;

  const _BaseMapControl({
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 6,
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: ToggleButtons(
          isSelected: [
            value == _BaseMapStyle.standard,
            value == _BaseMapStyle.satellite,
          ],
          onPressed: (index) => onChanged(index == 0 ? _BaseMapStyle.standard : _BaseMapStyle.satellite),
          borderRadius: BorderRadius.circular(8),
          constraints: const BoxConstraints(minHeight: 32, minWidth: 90),
          children: const [
            Text('Estándar'),
            Text('Satélite'),
          ],
        ),
      ),
    );
  }
}

class _MapActionControls extends StatelessWidget {
  final MapController mapCtrl;

  const _MapActionControls({required this.mapCtrl});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 6,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Tooltip(
            message: 'Zoom +',
            child: IconButton(
              onPressed: () => mapCtrl.move(mapCtrl.camera.center, mapCtrl.camera.zoom + 1),
              icon: const Icon(Icons.add),
            ),
          ),
          Tooltip(
            message: 'Zoom -',
            child: IconButton(
              onPressed: () => mapCtrl.move(mapCtrl.camera.center, mapCtrl.camera.zoom - 1),
              icon: const Icon(Icons.remove),
            ),
          ),
        ],
      ),
    );
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
    final sorted = [...categories]..sort();
    return Card(
      color: Colors.white,
      elevation: 5,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 260),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Proyectos visibles: $total', style: t.labelLarge?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 10,
                runSpacing: 8,
                children: sorted
                    .map(
                      (c) => Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: colorForCategory(c),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        c.toUpperCase(),
                        style: t.bodySmall?.copyWith(letterSpacing: 0.2),
                      ),
                    ],
                  ),
                )
                    .toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
