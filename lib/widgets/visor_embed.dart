// visor_embed.dart adaptado con mejoras funcionales y leyenda de categorías

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
  final _mapCtrl = MapController();

  @override
  void initState() {
    super.initState();
    _expanded = widget.startExpanded;
  }

  double get _targetHeight => _expanded ? MediaQuery.of(context).size.height * 0.8 : 360;

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
        ),
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
  static const _center = LatLng(28.2916, -16.6291);
  String _lastSignature = '';

  @override
  Widget build(BuildContext context) {
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

            final markers = projects.map((p) {
              final color = _colorForCategory(context, p.category);
              return Marker(
                point: LatLng(p.lat, p.lon),
                width: 26,
                height: 26,
                child: Tooltip(
                  message: '${p.title}\n${p.category} · ${p.year ?? 's/f'}',
                  child: Container(
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 1))],
                    ),
                    child: Center(
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList();

            _maybeFitCamera(projects);

            return Stack(
              children: [
                FlutterMap(
                  mapController: widget.mapCtrl,
                  options: const MapOptions(
                    initialCenter: _center,
                    initialZoom: 7,
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
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(12.0),
                      child: Text('No hay proyectos visibles con los filtros actuales.'),
                    ),
                  ),
                Positioned(
                  bottom: 12,
                  right: 12,
                  child: _Legend(
                    key: const ValueKey('visor_legend'),
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

  void _maybeFitCamera(List<Project> projects) {
    final sorted = [...projects]..sort((a, b) => a.id.compareTo(b.id));
    final signature = sorted.map((p) => p.id).join('|');
    if (signature == _lastSignature) return;
    _lastSignature = signature;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
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
        widget.mapCtrl.move(_center, 7);
      }
    });
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
      color: Colors.white.withOpacity(0.85),
      elevation: 5,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 260, maxHeight: 200),
          child: SingleChildScrollView(
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
      ),
    );
  }
}
