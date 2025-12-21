// visor_embed.dart adaptado con mejoras funcionales y leyenda de categorías

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
        ),
      ),
    );
  }
}

class _ProjectsMap extends StatelessWidget {
  final MapController mapCtrl;
  final FiltersController filters;
  final GlobalKey legendKey;

  const _ProjectsMap({
    required this.mapCtrl,
    required this.filters,
    required this.legendKey,
  });

  @override
  Widget build(BuildContext context) {
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

            final markers = projects.map((p) {
              final color = _colorForCategory(context, p.category);
              return Marker(
                point: LatLng(p.lat, p.lon),
                width: 40,
                height: 40,
                child: Tooltip(
                  message: '${p.title}\n${p.category} · ${p.year ?? 's/f'}',
                  child: Center(
                    child: Container(
                      width: 15,
                      height: 15,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.25),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }).toList();

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
                mapCtrl.fitCamera(CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(60)));
              } else {
                mapCtrl.move(center, 7);
              }
            });

            return Stack(
              children: [
                FlutterMap(
                  mapController: mapCtrl,
                  options: const MapOptions(
                    initialCenter: center,
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
                  bottom: 12,
                  right: 12,
                  child: _Legend(
                    key: legendKey,
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
    const shadow = [Shadow(color: Colors.black38, blurRadius: 2, offset: Offset(0, 1))];

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 4)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 280),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Proyectos visibles: $total',
                style: t.labelLarge?.copyWith(fontWeight: FontWeight.w700, shadows: shadow),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 10,
                runSpacing: 8,
                children: sorted
                    .map(
                      (c) => ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 240),
                        child: Row(
                          mainAxisSize: MainAxisSize.max,
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: colorForCategory(c),
                                shape: BoxShape.circle,
                                boxShadow: const [
                                  BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2)),
                                ],
                              ),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                c.toUpperCase(),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: t.bodySmall?.copyWith(letterSpacing: 0.2, shadows: shadow),
                              ),
                            ),
                          ],
                        ),
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
